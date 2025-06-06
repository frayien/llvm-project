//===- bolt/Core/BinaryEmitter.cpp - Emit code and data -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the collection of functions and classes used for
// emission of code and data into object/binary file.
//
//===----------------------------------------------------------------------===//

#include "bolt/Core/BinaryEmitter.h"
#include "bolt/Core/BinaryContext.h"
#include "bolt/Core/BinaryFunction.h"
#include "bolt/Core/DebugData.h"
#include "bolt/Core/FunctionLayout.h"
#include "bolt/Utils/CommandLineOpts.h"
#include "bolt/Utils/Utils.h"
#include "llvm/DebugInfo/DWARF/DWARFCompileUnit.h"
#include "llvm/MC/MCSection.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/SMLoc.h"

#define DEBUG_TYPE "bolt"

using namespace llvm;
using namespace bolt;

namespace opts {

extern cl::opt<JumpTableSupportLevel> JumpTables;
extern cl::opt<bool> PreserveBlocksAlignment;

cl::opt<bool> AlignBlocks("align-blocks", cl::desc("align basic blocks"),
                          cl::cat(BoltOptCategory));

static cl::list<std::string>
BreakFunctionNames("break-funcs",
  cl::CommaSeparated,
  cl::desc("list of functions to core dump on (debugging)"),
  cl::value_desc("func1,func2,func3,..."),
  cl::Hidden,
  cl::cat(BoltCategory));

static cl::list<std::string>
    FunctionPadSpec("pad-funcs", cl::CommaSeparated,
                    cl::desc("list of functions to pad with amount of bytes"),
                    cl::value_desc("func1:pad1,func2:pad2,func3:pad3,..."),
                    cl::Hidden, cl::cat(BoltCategory));

static cl::list<std::string> FunctionPadBeforeSpec(
    "pad-funcs-before", cl::CommaSeparated,
    cl::desc("list of functions to pad with amount of bytes"),
    cl::value_desc("func1:pad1,func2:pad2,func3:pad3,..."), cl::Hidden,
    cl::cat(BoltCategory));

static cl::opt<bool> MarkFuncs(
    "mark-funcs",
    cl::desc("mark function boundaries with break instruction to make "
             "sure we accidentally don't cross them"),
    cl::ReallyHidden, cl::cat(BoltCategory));

static cl::opt<bool> PrintJumpTables("print-jump-tables",
                                     cl::desc("print jump tables"), cl::Hidden,
                                     cl::cat(BoltCategory));

static cl::opt<bool>
X86AlignBranchBoundaryHotOnly("x86-align-branch-boundary-hot-only",
  cl::desc("only apply branch boundary alignment in hot code"),
  cl::init(true),
  cl::cat(BoltOptCategory));

size_t padFunction(std::map<std::string, size_t> &FunctionPadding,
                   const cl::list<std::string> &Spec,
                   const BinaryFunction &Function) {
  if (FunctionPadding.empty() && !Spec.empty()) {
    for (const std::string &Spec : Spec) {
      size_t N = Spec.find(':');
      if (N == std::string::npos)
        continue;
      std::string Name = Spec.substr(0, N);
      size_t Padding = std::stoull(Spec.substr(N + 1));
      FunctionPadding[Name] = Padding;
    }
  }

  for (auto &FPI : FunctionPadding) {
    std::string Name = FPI.first;
    size_t Padding = FPI.second;
    if (Function.hasNameRegex(Name))
      return Padding;
  }

  return 0;
}

size_t padFunctionBefore(const BinaryFunction &Function) {
  static std::map<std::string, size_t> CacheFunctionPadding;
  return padFunction(CacheFunctionPadding, FunctionPadBeforeSpec, Function);
}
size_t padFunctionAfter(const BinaryFunction &Function) {
  static std::map<std::string, size_t> CacheFunctionPadding;
  return padFunction(CacheFunctionPadding, FunctionPadSpec, Function);
}

} // namespace opts

namespace {
using JumpTable = bolt::JumpTable;

class BinaryEmitter {
private:
  BinaryEmitter(const BinaryEmitter &) = delete;
  BinaryEmitter &operator=(const BinaryEmitter &) = delete;

  MCStreamer &Streamer;
  BinaryContext &BC;

public:
  BinaryEmitter(MCStreamer &Streamer, BinaryContext &BC)
      : Streamer(Streamer), BC(BC) {}

  /// Emit all code and data.
  void emitAll(StringRef OrgSecPrefix);

  /// Emit function code. The caller is responsible for emitting function
  /// symbol(s) and setting the section to emit the code to.
  void emitFunctionBody(BinaryFunction &BF, FunctionFragment &FF,
                        bool EmitCodeOnly = false);

private:
  /// Emit function code.
  void emitFunctions();

  /// Emit a single function.
  bool emitFunction(BinaryFunction &BF, FunctionFragment &FF);

  /// Helper for emitFunctionBody to write data inside a function
  /// (used for AArch64)
  void emitConstantIslands(BinaryFunction &BF, bool EmitColdPart,
                           BinaryFunction *OnBehalfOf = nullptr);

  /// Emit jump tables for the function.
  void emitJumpTables(const BinaryFunction &BF);

  /// Emit jump table data. Callee supplies sections for the data.
  void emitJumpTable(const JumpTable &JT, MCSection *HotSection,
                     MCSection *ColdSection);

  void emitCFIInstruction(const MCCFIInstruction &Inst) const;

  /// Emit exception handling ranges for the function fragment.
  void emitLSDA(BinaryFunction &BF, const FunctionFragment &FF);

  /// Emit line number information corresponding to \p NewLoc. \p PrevLoc
  /// provides a context for de-duplication of line number info.
  /// \p FirstInstr indicates if \p NewLoc represents the first instruction
  /// in a sequence, such as a function fragment.
  ///
  /// If \p NewLoc location matches \p PrevLoc, no new line number entry will be
  /// created and the function will return \p PrevLoc while \p InstrLabel will
  /// be ignored. Otherwise, the caller should use \p InstrLabel to mark the
  /// corresponding instruction by emitting \p InstrLabel before it.
  /// If \p InstrLabel is set by the caller, its value will be used with \p
  /// \p NewLoc. If it was nullptr on entry, it will be populated with a pointer
  /// to a new temp symbol used with \p NewLoc.
  ///
  /// Return new current location which is either \p NewLoc or \p PrevLoc.
  SMLoc emitLineInfo(const BinaryFunction &BF, SMLoc NewLoc, SMLoc PrevLoc,
                     bool FirstInstr, MCSymbol *&InstrLabel);

  /// Use \p FunctionEndSymbol to mark the end of the line info sequence.
  /// Note that it does not automatically result in the insertion of the EOS
  /// marker in the line table program, but provides one to the DWARF generator
  /// when it needs it.
  void emitLineInfoEnd(const BinaryFunction &BF, MCSymbol *FunctionEndSymbol);

  /// Emit debug line info for unprocessed functions from CUs that include
  /// emitted functions.
  void emitDebugLineInfoForOriginalFunctions();

  /// Emit debug line for CUs that were not modified.
  void emitDebugLineInfoForUnprocessedCUs();

  /// Emit data sections that have code references in them.
  void emitDataSections(StringRef OrgSecPrefix);
};

} // anonymous namespace

void BinaryEmitter::emitAll(StringRef OrgSecPrefix) {
  Streamer.initSections(false, *BC.STI);
  Streamer.setUseAssemblerInfoForParsing(false);

  if (opts::UpdateDebugSections && BC.isELF()) {
    // Force the emission of debug line info into allocatable section to ensure
    // JITLink will process it.
    //
    // NB: on MachO all sections are required for execution, hence no need
    //     to change flags/attributes.
    MCSectionELF *ELFDwarfLineSection =
        static_cast<MCSectionELF *>(BC.MOFI->getDwarfLineSection());
    ELFDwarfLineSection->setFlags(ELF::SHF_ALLOC);
    MCSectionELF *ELFDwarfLineStrSection =
        static_cast<MCSectionELF *>(BC.MOFI->getDwarfLineStrSection());
    ELFDwarfLineStrSection->setFlags(ELF::SHF_ALLOC);
  }

  if (RuntimeLibrary *RtLibrary = BC.getRuntimeLibrary())
    RtLibrary->emitBinary(BC, Streamer);

  BC.getTextSection()->setAlignment(Align(opts::AlignText));

  emitFunctions();

  if (opts::UpdateDebugSections) {
    emitDebugLineInfoForOriginalFunctions();
    DwarfLineTable::emit(BC, Streamer);
  }

  emitDataSections(OrgSecPrefix);

  // TODO Enable for Mach-O once BinaryContext::getDataSection supports it.
  if (BC.isELF())
    AddressMap::emit(Streamer, BC);
  Streamer.setUseAssemblerInfoForParsing(true);
}

void BinaryEmitter::emitFunctions() {
  auto emit = [&](const std::vector<BinaryFunction *> &Functions) {
    const bool HasProfile = BC.NumProfiledFuncs > 0;
    const bool OriginalAllowAutoPadding = Streamer.getAllowAutoPadding();
    for (BinaryFunction *Function : Functions) {
      if (!BC.shouldEmit(*Function))
        continue;

      LLVM_DEBUG(dbgs() << "BOLT: generating code for function \"" << *Function
                        << "\" : " << Function->getFunctionNumber() << '\n');

      // Was any part of the function emitted.
      bool Emitted = false;

      // Turn off Intel JCC Erratum mitigation for cold code if requested
      if (HasProfile && opts::X86AlignBranchBoundaryHotOnly &&
          !Function->hasValidProfile())
        Streamer.setAllowAutoPadding(false);

      FunctionLayout &Layout = Function->getLayout();
      Emitted |= emitFunction(*Function, Layout.getMainFragment());

      if (Function->isSplit()) {
        if (opts::X86AlignBranchBoundaryHotOnly)
          Streamer.setAllowAutoPadding(false);

        assert((Layout.fragment_size() == 1 || Function->isSimple()) &&
               "Only simple functions can have fragments");
        for (FunctionFragment &FF : Layout.getSplitFragments()) {
          // Skip empty fragments so no symbols and sections for empty fragments
          // are generated
          if (FF.empty() && !Function->hasConstantIsland())
            continue;
          Emitted |= emitFunction(*Function, FF);
        }
      }

      Streamer.setAllowAutoPadding(OriginalAllowAutoPadding);

      if (Emitted)
        Function->setEmitted(/*KeepCFG=*/opts::PrintCacheMetrics);
    }
  };

  // Mark the start of hot text.
  if (opts::HotText) {
    Streamer.switchSection(BC.getTextSection());
    Streamer.emitLabel(BC.getHotTextStartSymbol());
  }

  // Emit functions in sorted order.
  std::vector<BinaryFunction *> SortedFunctions = BC.getSortedFunctions();
  emit(SortedFunctions);

  // Emit functions added by BOLT.
  emit(BC.getInjectedBinaryFunctions());

  // Mark the end of hot text.
  if (opts::HotText) {
    if (BC.HasWarmSection)
      Streamer.switchSection(BC.getCodeSection(BC.getWarmCodeSectionName()));
    else
      Streamer.switchSection(BC.getTextSection());
    Streamer.emitLabel(BC.getHotTextEndSymbol());
  }
}

bool BinaryEmitter::emitFunction(BinaryFunction &Function,
                                 FunctionFragment &FF) {
  if (Function.size() == 0 && !Function.hasIslandsInfo())
    return false;

  if (Function.getState() == BinaryFunction::State::Empty)
    return false;

  // Avoid emitting function without instructions when overwriting the original
  // function in-place. Otherwise, emit the empty function to define the symbol.
  if (!BC.HasRelocations && !Function.hasNonPseudoInstructions())
    return false;

  MCSection *Section =
      BC.getCodeSection(Function.getCodeSectionName(FF.getFragmentNum()));
  Streamer.switchSection(Section);
  Section->setHasInstructions(true);
  BC.Ctx->addGenDwarfSection(Section);

  if (BC.HasRelocations) {
    // Set section alignment to at least maximum possible object alignment.
    // We need this to support LongJmp and other passes that calculates
    // tentative layout.
    Section->ensureMinAlignment(Align(opts::AlignFunctions));

    Streamer.emitCodeAlignment(Function.getMinAlign(), &*BC.STI);
    uint16_t MaxAlignBytes = FF.isSplitFragment()
                                 ? Function.getMaxColdAlignmentBytes()
                                 : Function.getMaxAlignmentBytes();
    if (MaxAlignBytes > 0)
      Streamer.emitCodeAlignment(Function.getAlign(), &*BC.STI, MaxAlignBytes);
  } else {
    Streamer.emitCodeAlignment(Function.getAlign(), &*BC.STI);
  }

  if (size_t Padding = opts::padFunctionBefore(Function)) {
    // Handle padFuncsBefore after the above alignment logic but before
    // symbol addresses are decided.
    if (!BC.HasRelocations) {
      BC.errs() << "BOLT-ERROR: -pad-before-funcs is not supported in "
                << "non-relocation mode\n";
      exit(1);
    }

    // Preserve Function.getMinAlign().
    if (!isAligned(Function.getMinAlign(), Padding)) {
      BC.errs() << "BOLT-ERROR: user-requested " << Padding
                << " padding bytes before function " << Function
                << " is not a multiple of the minimum function alignment ("
                << Function.getMinAlign().value() << ").\n";
      exit(1);
    }

    LLVM_DEBUG(dbgs() << "BOLT-DEBUG: padding before function " << Function
                      << " with " << Padding << " bytes\n");

    // Since the padding is not executed, it can be null bytes.
    Streamer.emitFill(Padding, 0);
  }

  MCContext &Context = Streamer.getContext();
  const MCAsmInfo *MAI = Context.getAsmInfo();

  MCSymbol *const StartSymbol = Function.getSymbol(FF.getFragmentNum());

  // Emit all symbols associated with the main function entry.
  if (FF.isMainFragment()) {
    for (MCSymbol *Symbol : Function.getSymbols()) {
      Streamer.emitSymbolAttribute(Symbol, MCSA_ELF_TypeFunction);
      Streamer.emitLabel(Symbol);
    }
  } else {
    Streamer.emitSymbolAttribute(StartSymbol, MCSA_ELF_TypeFunction);
    Streamer.emitLabel(StartSymbol);
  }

  const bool NeedsFDE =
      Function.hasCFI() && !(Function.isPatch() && Function.isAnonymous());
  // Emit CFI start
  if (NeedsFDE) {
    Streamer.emitCFIStartProc(/*IsSimple=*/false);
    if (Function.getPersonalityFunction() != nullptr)
      Streamer.emitCFIPersonality(Function.getPersonalityFunction(),
                                  Function.getPersonalityEncoding());
    MCSymbol *LSDASymbol = Function.getLSDASymbol(FF.getFragmentNum());
    if (LSDASymbol)
      Streamer.emitCFILsda(LSDASymbol, BC.LSDAEncoding);
    else
      Streamer.emitCFILsda(0, dwarf::DW_EH_PE_omit);
    // Emit CFI instructions relative to the CIE
    for (const MCCFIInstruction &CFIInstr : Function.cie()) {
      // Only write CIE CFI insns that LLVM will not already emit
      const std::vector<MCCFIInstruction> &FrameInstrs =
          MAI->getInitialFrameState();
      if (!llvm::is_contained(FrameInstrs, CFIInstr))
        emitCFIInstruction(CFIInstr);
    }
  }

  assert((Function.empty() || !(*Function.begin()).isCold()) &&
         "first basic block should never be cold");

  // Emit UD2 at the beginning if requested by user.
  if (!opts::BreakFunctionNames.empty()) {
    for (std::string &Name : opts::BreakFunctionNames) {
      if (Function.hasNameRegex(Name)) {
        Streamer.emitIntValue(0x0B0F, 2); // UD2: 0F 0B
        break;
      }
    }
  }

  // Emit code.
  emitFunctionBody(Function, FF, /*EmitCodeOnly=*/false);

  // Emit padding if requested.
  if (size_t Padding = opts::padFunctionAfter(Function)) {
    LLVM_DEBUG(dbgs() << "BOLT-DEBUG: padding function " << Function << " with "
                      << Padding << " bytes\n");
    Streamer.emitFill(Padding, MAI->getTextAlignFillValue());
  }

  if (opts::MarkFuncs)
    Streamer.emitBytes(BC.MIB->getTrapFillValue());

  // Emit CFI end
  if (NeedsFDE)
    Streamer.emitCFIEndProc();

  MCSymbol *EndSymbol = Function.getFunctionEndLabel(FF.getFragmentNum());
  Streamer.emitLabel(EndSymbol);

  if (MAI->hasDotTypeDotSizeDirective()) {
    const MCExpr *SizeExpr = MCBinaryExpr::createSub(
        MCSymbolRefExpr::create(EndSymbol, Context),
        MCSymbolRefExpr::create(StartSymbol, Context), Context);
    Streamer.emitELFSize(StartSymbol, SizeExpr);
  }

  if (opts::UpdateDebugSections && Function.getDWARFUnit())
    emitLineInfoEnd(Function, EndSymbol);

  // Exception handling info for the function.
  emitLSDA(Function, FF);

  if (FF.isMainFragment() && opts::JumpTables > JTS_NONE)
    emitJumpTables(Function);

  return true;
}

void BinaryEmitter::emitFunctionBody(BinaryFunction &BF, FunctionFragment &FF,
                                     bool EmitCodeOnly) {
  if (!EmitCodeOnly && FF.isSplitFragment() && BF.hasConstantIsland()) {
    assert(BF.getLayout().isHotColdSplit() &&
           "Constant island support only with hot/cold split");
    BF.duplicateConstantIslands();
  }

  // Track the first emitted instruction with debug info.
  bool FirstInstr = true;
  for (BinaryBasicBlock *const BB : FF) {
    if ((opts::AlignBlocks || opts::PreserveBlocksAlignment) &&
        BB->getAlignment() > 1)
      Streamer.emitCodeAlignment(BB->getAlign(), &*BC.STI,
                                 BB->getAlignmentMaxBytes());
    Streamer.emitLabel(BB->getLabel());
    if (!EmitCodeOnly) {
      if (MCSymbol *EntrySymbol = BF.getSecondaryEntryPointSymbol(*BB))
        Streamer.emitLabel(EntrySymbol);
    }

    SMLoc LastLocSeen;
    for (auto I = BB->begin(), E = BB->end(); I != E; ++I) {
      MCInst &Instr = *I;

      if (EmitCodeOnly && BC.MIB->isPseudo(Instr))
        continue;

      // Handle pseudo instructions.
      if (BC.MIB->isCFI(Instr)) {
        emitCFIInstruction(*BF.getCFIFor(Instr));
        continue;
      }

      if (!EmitCodeOnly) {
        // A symbol to be emitted before the instruction to mark its location.
        MCSymbol *InstrLabel = BC.MIB->getInstLabel(Instr);

        if (opts::UpdateDebugSections && BF.getDWARFUnit()) {
          LastLocSeen = emitLineInfo(BF, Instr.getLoc(), LastLocSeen,
                                     FirstInstr, InstrLabel);
          FirstInstr = false;
        }

        // Prepare to tag this location with a label if we need to keep track of
        // the location of calls/returns for BOLT address translation maps
        if (BF.requiresAddressTranslation() && BC.MIB->getOffset(Instr)) {
          const uint32_t Offset = *BC.MIB->getOffset(Instr);
          if (!InstrLabel)
            InstrLabel = BC.Ctx->createTempSymbol();
          BB->getLocSyms().emplace_back(Offset, InstrLabel);
        }

        if (InstrLabel)
          Streamer.emitLabel(InstrLabel);
      }

      // Emit sized NOPs via MCAsmBackend::writeNopData() interface on x86.
      // This is a workaround for invalid NOPs handling by asm/disasm layer.
      if (BC.isX86() && BC.MIB->isNoop(Instr)) {
        if (std::optional<uint32_t> Size = BC.MIB->getSize(Instr)) {
          SmallString<15> Code;
          raw_svector_ostream VecOS(Code);
          BC.MAB->writeNopData(VecOS, *Size, BC.STI.get());
          Streamer.emitBytes(Code);
          continue;
        }
      }

      Streamer.emitInstruction(Instr, *BC.STI);
    }
  }

  if (!EmitCodeOnly)
    emitConstantIslands(BF, FF.isSplitFragment());
}

void BinaryEmitter::emitConstantIslands(BinaryFunction &BF, bool EmitColdPart,
                                        BinaryFunction *OnBehalfOf) {
  if (!BF.hasIslandsInfo())
    return;

  BinaryFunction::IslandInfo &Islands = BF.getIslandInfo();
  if (Islands.DataOffsets.empty() && Islands.Dependency.empty())
    return;

  // AArch64 requires CI to be aligned to 8 bytes due to access instructions
  // restrictions. E.g. the ldr with imm, where imm must be aligned to 8 bytes.
  const uint16_t Alignment = OnBehalfOf
                                 ? OnBehalfOf->getConstantIslandAlignment()
                                 : BF.getConstantIslandAlignment();
  Streamer.emitCodeAlignment(Align(Alignment), &*BC.STI);

  if (!OnBehalfOf) {
    if (!EmitColdPart)
      Streamer.emitLabel(BF.getFunctionConstantIslandLabel());
    else
      Streamer.emitLabel(BF.getFunctionColdConstantIslandLabel());
  }

  assert((!OnBehalfOf || Islands.Proxies[OnBehalfOf].size() > 0) &&
         "spurious OnBehalfOf constant island emission");

  assert(!BF.isInjected() &&
         "injected functions should not have constant islands");
  // Raw contents of the function.
  StringRef SectionContents = BF.getOriginSection()->getContents();

  // Raw contents of the function.
  StringRef FunctionContents = SectionContents.substr(
      BF.getAddress() - BF.getOriginSection()->getAddress(), BF.getMaxSize());

  if (opts::Verbosity && !OnBehalfOf)
    BC.outs() << "BOLT-INFO: emitting constant island for function " << BF
              << "\n";

  // We split the island into smaller blocks and output labels between them.
  auto IS = Islands.Offsets.begin();
  for (auto DataIter = Islands.DataOffsets.begin();
       DataIter != Islands.DataOffsets.end(); ++DataIter) {
    uint64_t FunctionOffset = *DataIter;
    uint64_t EndOffset = 0ULL;

    // Determine size of this data chunk
    auto NextData = std::next(DataIter);
    auto CodeIter = Islands.CodeOffsets.lower_bound(*DataIter);
    if (CodeIter == Islands.CodeOffsets.end() &&
        NextData == Islands.DataOffsets.end())
      EndOffset = BF.getMaxSize();
    else if (CodeIter == Islands.CodeOffsets.end())
      EndOffset = *NextData;
    else if (NextData == Islands.DataOffsets.end())
      EndOffset = *CodeIter;
    else
      EndOffset = (*CodeIter > *NextData) ? *NextData : *CodeIter;

    if (FunctionOffset == EndOffset)
      continue; // Size is zero, nothing to emit

    auto emitCI = [&](uint64_t &FunctionOffset, uint64_t EndOffset) {
      if (FunctionOffset >= EndOffset)
        return;

      for (auto It = Islands.Relocations.lower_bound(FunctionOffset);
           It != Islands.Relocations.end(); ++It) {
        if (It->first >= EndOffset)
          break;

        const Relocation &Relocation = It->second;
        if (FunctionOffset < Relocation.Offset) {
          Streamer.emitBytes(
              FunctionContents.slice(FunctionOffset, Relocation.Offset));
          FunctionOffset = Relocation.Offset;
        }

        LLVM_DEBUG(
            dbgs() << "BOLT-DEBUG: emitting constant island relocation"
                   << " for " << BF << " at offset 0x"
                   << Twine::utohexstr(Relocation.Offset) << " with size "
                   << Relocation::getSizeForType(Relocation.Type) << '\n');

        FunctionOffset += Relocation.emit(&Streamer);
      }

      assert(FunctionOffset <= EndOffset && "overflow error");
      if (FunctionOffset < EndOffset) {
        Streamer.emitBytes(FunctionContents.slice(FunctionOffset, EndOffset));
        FunctionOffset = EndOffset;
      }
    };

    // Emit labels, relocs and data
    while (IS != Islands.Offsets.end() && IS->first < EndOffset) {
      auto NextLabelOffset =
          IS == Islands.Offsets.end() ? EndOffset : IS->first;
      auto NextStop = std::min(NextLabelOffset, EndOffset);
      assert(NextStop <= EndOffset && "internal overflow error");
      emitCI(FunctionOffset, NextStop);
      if (IS != Islands.Offsets.end() && FunctionOffset == IS->first) {
        // This is a slightly complex code to decide which label to emit. We
        // have 4 cases to handle: regular symbol, cold symbol, regular or cold
        // symbol being emitted on behalf of an external function.
        if (!OnBehalfOf) {
          if (!EmitColdPart) {
            LLVM_DEBUG(dbgs() << "BOLT-DEBUG: emitted label "
                              << IS->second->getName() << " at offset 0x"
                              << Twine::utohexstr(IS->first) << '\n');
            if (IS->second->isUndefined())
              Streamer.emitLabel(IS->second);
            else
              assert(BF.hasName(std::string(IS->second->getName())));
          } else if (Islands.ColdSymbols.count(IS->second) != 0) {
            LLVM_DEBUG(dbgs()
                       << "BOLT-DEBUG: emitted label "
                       << Islands.ColdSymbols[IS->second]->getName() << '\n');
            if (Islands.ColdSymbols[IS->second]->isUndefined())
              Streamer.emitLabel(Islands.ColdSymbols[IS->second]);
          }
        } else {
          if (!EmitColdPart) {
            if (MCSymbol *Sym = Islands.Proxies[OnBehalfOf][IS->second]) {
              LLVM_DEBUG(dbgs() << "BOLT-DEBUG: emitted label "
                                << Sym->getName() << '\n');
              Streamer.emitLabel(Sym);
            }
          } else if (MCSymbol *Sym =
                         Islands.ColdProxies[OnBehalfOf][IS->second]) {
            LLVM_DEBUG(dbgs() << "BOLT-DEBUG: emitted label " << Sym->getName()
                              << '\n');
            Streamer.emitLabel(Sym);
          }
        }
        ++IS;
      }
    }
    assert(FunctionOffset <= EndOffset && "overflow error");
    emitCI(FunctionOffset, EndOffset);
  }
  assert(IS == Islands.Offsets.end() && "some symbols were not emitted!");

  if (OnBehalfOf)
    return;
  // Now emit constant islands from other functions that we may have used in
  // this function.
  for (BinaryFunction *ExternalFunc : Islands.Dependency)
    emitConstantIslands(*ExternalFunc, EmitColdPart, &BF);
}

SMLoc BinaryEmitter::emitLineInfo(const BinaryFunction &BF, SMLoc NewLoc,
                                  SMLoc PrevLoc, bool FirstInstr,
                                  MCSymbol *&InstrLabel) {
  DWARFUnit *FunctionCU = BF.getDWARFUnit();
  const DWARFDebugLine::LineTable *FunctionLineTable = BF.getDWARFLineTable();
  assert(FunctionCU && "cannot emit line info for function without CU");

  DebugLineTableRowRef RowReference = DebugLineTableRowRef::fromSMLoc(NewLoc);

  // Check if no new line info needs to be emitted.
  if (RowReference == DebugLineTableRowRef::NULL_ROW ||
      NewLoc.getPointer() == PrevLoc.getPointer())
    return PrevLoc;

  unsigned CurrentFilenum = 0;
  const DWARFDebugLine::LineTable *CurrentLineTable = FunctionLineTable;

  // If the CU id from the current instruction location does not
  // match the CU id from the current function, it means that we
  // have come across some inlined code.  We must look up the CU
  // for the instruction's original function and get the line table
  // from that.
  const uint64_t FunctionUnitIndex = FunctionCU->getOffset();
  const uint32_t CurrentUnitIndex = RowReference.DwCompileUnitIndex;
  if (CurrentUnitIndex != FunctionUnitIndex) {
    CurrentLineTable = BC.DwCtx->getLineTableForUnit(
        BC.DwCtx->getCompileUnitForOffset(CurrentUnitIndex));
    // Add filename from the inlined function to the current CU.
    CurrentFilenum = BC.addDebugFilenameToUnit(
        FunctionUnitIndex, CurrentUnitIndex,
        CurrentLineTable->Rows[RowReference.RowIndex - 1].File);
  }

  const DWARFDebugLine::Row &CurrentRow =
      CurrentLineTable->Rows[RowReference.RowIndex - 1];
  if (!CurrentFilenum)
    CurrentFilenum = CurrentRow.File;

  unsigned Flags = (DWARF2_FLAG_IS_STMT * CurrentRow.IsStmt) |
                   (DWARF2_FLAG_BASIC_BLOCK * CurrentRow.BasicBlock) |
                   (DWARF2_FLAG_PROLOGUE_END * CurrentRow.PrologueEnd) |
                   (DWARF2_FLAG_EPILOGUE_BEGIN * CurrentRow.EpilogueBegin);

  // Always emit is_stmt at the beginning of function fragment.
  if (FirstInstr)
    Flags |= DWARF2_FLAG_IS_STMT;

  BC.Ctx->setCurrentDwarfLoc(CurrentFilenum, CurrentRow.Line, CurrentRow.Column,
                             Flags, CurrentRow.Isa, CurrentRow.Discriminator);
  const MCDwarfLoc &DwarfLoc = BC.Ctx->getCurrentDwarfLoc();
  BC.Ctx->clearDwarfLocSeen();

  if (!InstrLabel)
    InstrLabel = BC.Ctx->createTempSymbol();

  BC.getDwarfLineTable(FunctionUnitIndex)
      .getMCLineSections()
      .addLineEntry(MCDwarfLineEntry(InstrLabel, DwarfLoc),
                    Streamer.getCurrentSectionOnly());

  return NewLoc;
}

void BinaryEmitter::emitLineInfoEnd(const BinaryFunction &BF,
                                    MCSymbol *FunctionEndLabel) {
  DWARFUnit *FunctionCU = BF.getDWARFUnit();
  assert(FunctionCU && "DWARF unit expected");
  BC.Ctx->setCurrentDwarfLoc(0, 0, 0, DWARF2_FLAG_END_SEQUENCE, 0, 0);
  const MCDwarfLoc &DwarfLoc = BC.Ctx->getCurrentDwarfLoc();
  BC.Ctx->clearDwarfLocSeen();
  BC.getDwarfLineTable(FunctionCU->getOffset())
      .getMCLineSections()
      .addLineEntry(MCDwarfLineEntry(FunctionEndLabel, DwarfLoc),
                    Streamer.getCurrentSectionOnly());
}

void BinaryEmitter::emitJumpTables(const BinaryFunction &BF) {
  MCSection *ReadOnlySection = BC.MOFI->getReadOnlySection();
  MCSection *ReadOnlyColdSection = BC.MOFI->getContext().getELFSection(
      ".rodata.cold", ELF::SHT_PROGBITS, ELF::SHF_ALLOC);

  if (!BF.hasJumpTables())
    return;

  if (opts::PrintJumpTables)
    BC.outs() << "BOLT-INFO: jump tables for function " << BF << ":\n";

  for (auto &JTI : BF.jumpTables()) {
    JumpTable &JT = *JTI.second;
    // Only emit shared jump tables once, when processing the first parent
    if (JT.Parents.size() > 1 && JT.Parents[0] != &BF)
      continue;
    if (opts::PrintJumpTables)
      JT.print(BC.outs());
    if (opts::JumpTables == JTS_BASIC) {
      JT.updateOriginal();
    } else {
      MCSection *HotSection, *ColdSection;
      if (BF.isSimple()) {
        HotSection = ReadOnlySection;
        ColdSection = ReadOnlyColdSection;
      } else {
        HotSection = BF.hasProfile() ? ReadOnlySection : ReadOnlyColdSection;
        ColdSection = HotSection;
      }
      emitJumpTable(JT, HotSection, ColdSection);
    }
  }
}

void BinaryEmitter::emitJumpTable(const JumpTable &JT, MCSection *HotSection,
                                  MCSection *ColdSection) {
  // Pre-process entries for aggressive splitting.
  // Each label represents a separate switch table and gets its own count
  // determining its destination.
  std::map<MCSymbol *, uint64_t> LabelCounts;
  if (opts::JumpTables > JTS_SPLIT && !JT.Counts.empty()) {
    auto It = JT.Labels.find(0);
    assert(It != JT.Labels.end());
    MCSymbol *CurrentLabel = It->second;
    uint64_t CurrentLabelCount = 0;
    for (unsigned Index = 0; Index < JT.Entries.size(); ++Index) {
      auto LI = JT.Labels.find(Index * JT.EntrySize);
      if (LI != JT.Labels.end()) {
        LabelCounts[CurrentLabel] = CurrentLabelCount;
        CurrentLabel = LI->second;
        CurrentLabelCount = 0;
      }
      CurrentLabelCount += JT.Counts[Index].Count;
    }
    LabelCounts[CurrentLabel] = CurrentLabelCount;
  } else {
    Streamer.switchSection(JT.Count > 0 ? HotSection : ColdSection);
    Streamer.emitValueToAlignment(Align(JT.EntrySize));
  }
  MCSymbol *JTLabel = nullptr;
  uint64_t Offset = 0;
  for (MCSymbol *Entry : JT.Entries) {
    auto LI = JT.Labels.find(Offset);
    if (LI == JT.Labels.end())
      goto emitEntry;
    JTLabel = LI->second;
    LLVM_DEBUG({
      dbgs() << "BOLT-DEBUG: emitting jump table " << JTLabel->getName()
             << " (originally was at address 0x"
             << Twine::utohexstr(JT.getAddress() + Offset)
             << (Offset ? ") as part of larger jump table\n" : ")\n");
    });
    if (!LabelCounts.empty()) {
      const uint64_t JTCount = LabelCounts[JTLabel];
      LLVM_DEBUG(dbgs() << "BOLT-DEBUG: jump table count: " << JTCount << '\n');
      Streamer.switchSection(JTCount ? HotSection : ColdSection);
      Streamer.emitValueToAlignment(Align(JT.EntrySize));
    }
    // Emit all labels registered at the address of this jump table
    // to sync with our global symbol table.  We may have two labels
    // registered at this address if one label was created via
    // getOrCreateGlobalSymbol() (e.g. LEA instructions referencing
    // this location) and another via getOrCreateJumpTable().  This
    // creates a race where the symbols created by these two
    // functions may or may not be the same, but they are both
    // registered in our symbol table at the same address. By
    // emitting them all here we make sure there is no ambiguity
    // that depends on the order that these symbols were created, so
    // whenever this address is referenced in the binary, it is
    // certain to point to the jump table identified at this
    // address.
    if (BinaryData *BD = BC.getBinaryDataByName(JTLabel->getName())) {
      for (MCSymbol *S : BD->getSymbols())
        Streamer.emitLabel(S);
    } else {
      Streamer.emitLabel(JTLabel);
    }
  emitEntry:
    if (JT.Type == JumpTable::JTT_NORMAL) {
      Streamer.emitSymbolValue(Entry, JT.OutputEntrySize);
    } else { // JTT_PIC
      const MCSymbolRefExpr *JTExpr =
          MCSymbolRefExpr::create(JTLabel, Streamer.getContext());
      const MCSymbolRefExpr *E =
          MCSymbolRefExpr::create(Entry, Streamer.getContext());
      const MCBinaryExpr *Value =
          MCBinaryExpr::createSub(E, JTExpr, Streamer.getContext());
      Streamer.emitValue(Value, JT.EntrySize);
    }
    Offset += JT.EntrySize;
  }
}

void BinaryEmitter::emitCFIInstruction(const MCCFIInstruction &Inst) const {
  switch (Inst.getOperation()) {
  default:
    llvm_unreachable("Unexpected instruction");
  case MCCFIInstruction::OpDefCfaOffset:
    Streamer.emitCFIDefCfaOffset(Inst.getOffset());
    break;
  case MCCFIInstruction::OpAdjustCfaOffset:
    Streamer.emitCFIAdjustCfaOffset(Inst.getOffset());
    break;
  case MCCFIInstruction::OpDefCfa:
    Streamer.emitCFIDefCfa(Inst.getRegister(), Inst.getOffset());
    break;
  case MCCFIInstruction::OpDefCfaRegister:
    Streamer.emitCFIDefCfaRegister(Inst.getRegister());
    break;
  case MCCFIInstruction::OpOffset:
    Streamer.emitCFIOffset(Inst.getRegister(), Inst.getOffset());
    break;
  case MCCFIInstruction::OpRegister:
    Streamer.emitCFIRegister(Inst.getRegister(), Inst.getRegister2());
    break;
  case MCCFIInstruction::OpWindowSave:
    Streamer.emitCFIWindowSave();
    break;
  case MCCFIInstruction::OpNegateRAState:
    Streamer.emitCFINegateRAState();
    break;
  case MCCFIInstruction::OpSameValue:
    Streamer.emitCFISameValue(Inst.getRegister());
    break;
  case MCCFIInstruction::OpGnuArgsSize:
    Streamer.emitCFIGnuArgsSize(Inst.getOffset());
    break;
  case MCCFIInstruction::OpEscape:
    Streamer.AddComment(Inst.getComment());
    Streamer.emitCFIEscape(Inst.getValues());
    break;
  case MCCFIInstruction::OpRestore:
    Streamer.emitCFIRestore(Inst.getRegister());
    break;
  case MCCFIInstruction::OpUndefined:
    Streamer.emitCFIUndefined(Inst.getRegister());
    break;
  }
}

// The code is based on EHStreamer::emitExceptionTable().
void BinaryEmitter::emitLSDA(BinaryFunction &BF, const FunctionFragment &FF) {
  const BinaryFunction::CallSitesRange Sites =
      BF.getCallSites(FF.getFragmentNum());
  if (Sites.empty())
    return;

  Streamer.switchSection(BC.MOFI->getLSDASection());

  const unsigned TTypeEncoding = BF.getLSDATypeEncoding();
  const unsigned TTypeEncodingSize = BC.getDWARFEncodingSize(TTypeEncoding);
  const uint16_t TTypeAlignment = 4;

  // Type tables have to be aligned at 4 bytes.
  Streamer.emitValueToAlignment(Align(TTypeAlignment));

  // Emit the LSDA label.
  MCSymbol *LSDASymbol = BF.getLSDASymbol(FF.getFragmentNum());
  assert(LSDASymbol && "no LSDA symbol set");
  Streamer.emitLabel(LSDASymbol);

  // Corresponding FDE start.
  const MCSymbol *StartSymbol = BF.getSymbol(FF.getFragmentNum());

  // Emit the LSDA header.

  // If LPStart is omitted, then the start of the FDE is used as a base for
  // landing pad displacements. Then, if a cold fragment starts with
  // a landing pad, this means that the first landing pad offset will be 0.
  // However, C++ runtime will treat 0 as if there is no landing pad, thus we
  // cannot emit LP offset as 0.
  //
  // As a solution, for fixed-address binaries we set LPStart to 0, and for
  // position-independent binaries we offset LP start by one byte.
  bool NeedsLPAdjustment = false;
  std::function<void(const MCSymbol *)> emitLandingPad;

  // Check if there's a symbol associated with a landing pad fragment.
  const MCSymbol *LPStartSymbol = BF.getLPStartSymbol(FF.getFragmentNum());
  if (!LPStartSymbol) {
    // Since landing pads are not in the same fragment, we fall back to emitting
    // absolute addresses for this FDE.
    if (opts::Verbosity >= 2) {
      BC.outs() << "BOLT-INFO: falling back to generating absolute-address "
                << "exception ranges for " << BF << '\n';
    }

    assert(BC.HasFixedLoadAddress &&
           "Cannot emit absolute-address landing pads for PIE/DSO");

    Streamer.emitIntValue(dwarf::DW_EH_PE_udata4, 1); // LPStart format
    Streamer.emitIntValue(0, 4);                      // LPStart
    emitLandingPad = [&](const MCSymbol *LPSymbol) {
      if (LPSymbol)
        Streamer.emitSymbolValue(LPSymbol, 4);
      else
        Streamer.emitIntValue(0, 4);
    };
  } else {
    std::optional<FragmentNum> LPFN = BF.getLPFragment(FF.getFragmentNum());
    const FunctionFragment &LPFragment = BF.getLayout().getFragment(*LPFN);
    NeedsLPAdjustment =
        (!LPFragment.empty() && LPFragment.front()->isLandingPad());

    // Emit LPStart encoding and optionally LPStart.
    if (NeedsLPAdjustment || LPStartSymbol != StartSymbol) {
      Streamer.emitIntValue(dwarf::DW_EH_PE_pcrel | dwarf::DW_EH_PE_sdata4, 1);
      MCSymbol *DotSymbol = BC.Ctx->createTempSymbol("LPBase");
      Streamer.emitLabel(DotSymbol);

      const MCExpr *LPStartExpr = MCBinaryExpr::createSub(
          MCSymbolRefExpr::create(LPStartSymbol, *BC.Ctx),
          MCSymbolRefExpr::create(DotSymbol, *BC.Ctx), *BC.Ctx);
      if (NeedsLPAdjustment)
        LPStartExpr = MCBinaryExpr::createSub(
            LPStartExpr, MCConstantExpr::create(1, *BC.Ctx), *BC.Ctx);
      Streamer.emitValue(LPStartExpr, 4);
    } else {
      // DW_EH_PE_omit means FDE start (StartSymbol) will be used as LPStart.
      Streamer.emitIntValue(dwarf::DW_EH_PE_omit, 1);
    }
    emitLandingPad = [&](const MCSymbol *LPSymbol) {
      if (LPSymbol) {
        const MCExpr *LPOffsetExpr = MCBinaryExpr::createSub(
            MCSymbolRefExpr::create(LPSymbol, *BC.Ctx),
            MCSymbolRefExpr::create(LPStartSymbol, *BC.Ctx), *BC.Ctx);
        if (NeedsLPAdjustment)
          LPOffsetExpr = MCBinaryExpr::createAdd(
              LPOffsetExpr, MCConstantExpr::create(1, *BC.Ctx), *BC.Ctx);
        Streamer.emitULEB128Value(LPOffsetExpr);
      } else {
        Streamer.emitULEB128IntValue(0);
      }
    };
  }

  Streamer.emitIntValue(TTypeEncoding, 1); // TType format

  MCSymbol *TTBaseLabel = nullptr;
  if (TTypeEncoding != dwarf::DW_EH_PE_omit) {
    TTBaseLabel = BC.Ctx->createTempSymbol("TTBase");
    MCSymbol *TTBaseRefLabel = BC.Ctx->createTempSymbol("TTBaseRef");
    Streamer.emitAbsoluteSymbolDiffAsULEB128(TTBaseLabel, TTBaseRefLabel);
    Streamer.emitLabel(TTBaseRefLabel);
  }

  // Emit encoding of entries in the call site table. The format is used for the
  // call site start, length, and corresponding landing pad.
  if (!LPStartSymbol)
    Streamer.emitIntValue(dwarf::DW_EH_PE_sdata4, 1);
  else
    Streamer.emitIntValue(dwarf::DW_EH_PE_uleb128, 1);

  MCSymbol *CSTStartLabel = BC.Ctx->createTempSymbol("CSTStart");
  MCSymbol *CSTEndLabel = BC.Ctx->createTempSymbol("CSTEnd");
  Streamer.emitAbsoluteSymbolDiffAsULEB128(CSTEndLabel, CSTStartLabel);

  Streamer.emitLabel(CSTStartLabel);
  for (const auto &FragmentCallSite : Sites) {
    const BinaryFunction::CallSite &CallSite = FragmentCallSite.second;
    const MCSymbol *BeginLabel = CallSite.Start;
    const MCSymbol *EndLabel = CallSite.End;

    assert(BeginLabel && "start EH label expected");
    assert(EndLabel && "end EH label expected");

    // Start of the range is emitted relative to the start of current
    // function split part.
    if (!LPStartSymbol) {
      Streamer.emitAbsoluteSymbolDiff(BeginLabel, StartSymbol, 4);
      Streamer.emitAbsoluteSymbolDiff(EndLabel, BeginLabel, 4);
    } else {
      Streamer.emitAbsoluteSymbolDiffAsULEB128(BeginLabel, StartSymbol);
      Streamer.emitAbsoluteSymbolDiffAsULEB128(EndLabel, BeginLabel);
    }
    emitLandingPad(CallSite.LP);
    Streamer.emitULEB128IntValue(CallSite.Action);
  }
  Streamer.emitLabel(CSTEndLabel);

  // Write out action, type, and type index tables at the end.
  //
  // For action and type index tables there's no need to change the original
  // table format unless we are doing function splitting, in which case we can
  // split and optimize the tables.
  //
  // For type table we (re-)encode the table using TTypeEncoding matching
  // the current assembler mode.
  for (uint8_t const &Byte : BF.getLSDAActionTable())
    Streamer.emitIntValue(Byte, 1);

  const BinaryFunction::LSDATypeTableTy &TypeTable =
      (TTypeEncoding & dwarf::DW_EH_PE_indirect) ? BF.getLSDATypeAddressTable()
                                                 : BF.getLSDATypeTable();
  assert(TypeTable.size() == BF.getLSDATypeTable().size() &&
         "indirect type table size mismatch");

  Streamer.emitValueToAlignment(Align(TTypeAlignment));

  for (int Index = TypeTable.size() - 1; Index >= 0; --Index) {
    const uint64_t TypeAddress = TypeTable[Index];
    switch (TTypeEncoding & 0x70) {
    default:
      llvm_unreachable("unsupported TTypeEncoding");
    case dwarf::DW_EH_PE_absptr:
      Streamer.emitIntValue(TypeAddress, TTypeEncodingSize);
      break;
    case dwarf::DW_EH_PE_pcrel: {
      if (TypeAddress) {
        const MCSymbol *TypeSymbol =
            BC.getOrCreateGlobalSymbol(TypeAddress, "TI", 0, TTypeAlignment);
        MCSymbol *DotSymbol = BC.Ctx->createNamedTempSymbol();
        Streamer.emitLabel(DotSymbol);
        const MCBinaryExpr *SubDotExpr = MCBinaryExpr::createSub(
            MCSymbolRefExpr::create(TypeSymbol, *BC.Ctx),
            MCSymbolRefExpr::create(DotSymbol, *BC.Ctx), *BC.Ctx);
        Streamer.emitValue(SubDotExpr, TTypeEncodingSize);
      } else {
        Streamer.emitIntValue(0, TTypeEncodingSize);
      }
      break;
    }
    }
  }

  if (TTypeEncoding != dwarf::DW_EH_PE_omit)
    Streamer.emitLabel(TTBaseLabel);

  for (uint8_t const &Byte : BF.getLSDATypeIndexTable())
    Streamer.emitIntValue(Byte, 1);
}

void BinaryEmitter::emitDebugLineInfoForOriginalFunctions() {
  // If a function is in a CU containing at least one processed function, we
  // have to rewrite the whole line table for that CU. For unprocessed functions
  // we use data from the input line table.
  for (auto &It : BC.getBinaryFunctions()) {
    const BinaryFunction &Function = It.second;

    // If the function was emitted, its line info was emitted with it.
    if (Function.isEmitted())
      continue;

    const DWARFDebugLine::LineTable *LineTable = Function.getDWARFLineTable();
    if (!LineTable)
      continue; // nothing to update for this function

    const uint64_t Address = Function.getAddress();
    std::vector<uint32_t> Results;
    if (!LineTable->lookupAddressRange(
            {Address, object::SectionedAddress::UndefSection},
            Function.getSize(), Results))
      continue;

    if (Results.empty())
      continue;

    // The first row returned could be the last row matching the start address.
    // Find the first row with the same address that is not the end of the
    // sequence.
    uint64_t FirstRow = Results.front();
    while (FirstRow > 0) {
      const DWARFDebugLine::Row &PrevRow = LineTable->Rows[FirstRow - 1];
      if (PrevRow.Address.Address != Address || PrevRow.EndSequence)
        break;
      --FirstRow;
    }

    const uint64_t EndOfSequenceAddress =
        Function.getAddress() + Function.getMaxSize();
    BC.getDwarfLineTable(Function.getDWARFUnit()->getOffset())
        .addLineTableSequence(LineTable, FirstRow, Results.back(),
                              EndOfSequenceAddress);
  }

  // For units that are completely unprocessed, use original debug line contents
  // eliminating the need to regenerate line info program.
  emitDebugLineInfoForUnprocessedCUs();
}

void BinaryEmitter::emitDebugLineInfoForUnprocessedCUs() {
  // Sorted list of section offsets provides boundaries for section fragments,
  // where each fragment is the unit's contribution to debug line section.
  std::vector<uint64_t> StmtListOffsets;
  StmtListOffsets.reserve(BC.DwCtx->getNumCompileUnits());
  for (const std::unique_ptr<DWARFUnit> &CU : BC.DwCtx->compile_units()) {
    DWARFDie CUDie = CU->getUnitDIE();
    auto StmtList = dwarf::toSectionOffset(CUDie.find(dwarf::DW_AT_stmt_list));
    if (!StmtList)
      continue;

    StmtListOffsets.push_back(*StmtList);
  }
  llvm::sort(StmtListOffsets);

  // For each CU that was not processed, emit its line info as a binary blob.
  for (const std::unique_ptr<DWARFUnit> &CU : BC.DwCtx->compile_units()) {
    if (BC.ProcessedCUs.count(CU.get()))
      continue;

    DWARFDie CUDie = CU->getUnitDIE();
    auto StmtList = dwarf::toSectionOffset(CUDie.find(dwarf::DW_AT_stmt_list));
    if (!StmtList)
      continue;

    StringRef DebugLineContents = CU->getLineSection().Data;

    const uint64_t Begin = *StmtList;

    // Statement list ends where the next unit contribution begins, or at the
    // end of the section.
    auto It = llvm::upper_bound(StmtListOffsets, Begin);
    const uint64_t End =
        It == StmtListOffsets.end() ? DebugLineContents.size() : *It;

    BC.getDwarfLineTable(CU->getOffset())
        .addRawContents(DebugLineContents.slice(Begin, End));
  }
}

void BinaryEmitter::emitDataSections(StringRef OrgSecPrefix) {
  for (BinarySection &Section : BC.sections()) {
    if (!Section.hasRelocations())
      continue;

    StringRef Prefix = Section.hasSectionRef() ? OrgSecPrefix : "";
    Section.emitAsData(Streamer, Prefix + Section.getName());
    Section.clearRelocations();
  }
}

namespace llvm {
namespace bolt {

void emitBinaryContext(MCStreamer &Streamer, BinaryContext &BC,
                       StringRef OrgSecPrefix) {
  BinaryEmitter(Streamer, BC).emitAll(OrgSecPrefix);
}

void emitFunctionBody(MCStreamer &Streamer, BinaryFunction &BF,
                      FunctionFragment &FF, bool EmitCodeOnly) {
  BinaryEmitter(Streamer, BF.getBinaryContext())
      .emitFunctionBody(BF, FF, EmitCodeOnly);
}

} // namespace bolt
} // namespace llvm
