; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=+avx512fp16 -mattr=+avx512vl -O3 | FileCheck %s --check-prefixes=X86
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512fp16 -mattr=+avx512vl -O3 | FileCheck %s --check-prefixes=X64

define <8 x i16> @test_v8f16_oeq_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_oeq_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpeqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_oeq_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpeqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"oeq",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ogt_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ogt_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpgt_oqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ogt_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmplt_oqph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ogt",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_oge_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_oge_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpge_oqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_oge_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmple_oqph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"oge",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_olt_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_olt_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmplt_oqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_olt_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmplt_oqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"olt",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ole_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ole_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmple_oqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ole_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmple_oqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ole",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_one_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_one_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpneq_oqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_one_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpneq_oqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"one",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ord_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ord_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpordph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ord_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpordph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ord",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ueq_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ueq_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpeq_uqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ueq_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpeq_uqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ueq",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ugt_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ugt_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpnle_uqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ugt_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnle_uqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ugt",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_uge_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_uge_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpnlt_uqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_uge_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnlt_uqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"uge",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ult_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ult_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpnge_uqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ult_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnle_uqph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ult",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ule_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ule_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpngt_uqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ule_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnlt_uqph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ule",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_une_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_une_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpneqph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_une_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpneqph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"une",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_uno_q(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_uno_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpunordph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_uno_q:
; X64:       # %bb.0:
; X64-NEXT:    vcmpunordph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"uno",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_oeq_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_oeq_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpeq_osph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_oeq_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpeq_osph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"oeq",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ogt_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ogt_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpgtph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ogt_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpltph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ogt",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_oge_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_oge_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpgeph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_oge_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpleph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"oge",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_olt_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_olt_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpltph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_olt_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpltph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"olt",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ole_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ole_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpleph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ole_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpleph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ole",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_one_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_one_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpneq_osph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_one_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpneq_osph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"one",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ord_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ord_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpord_sph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ord_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpord_sph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ord",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ueq_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ueq_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpeq_usph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ueq_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpeq_usph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ueq",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ugt_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ugt_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpnleph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ugt_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnleph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ugt",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_uge_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_uge_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpnltph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_uge_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnltph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"uge",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ult_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ult_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpngeph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ult_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnleph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ult",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_ule_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_ule_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpngtph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_ule_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpnltph %xmm2, %xmm3, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"ule",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_une_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_une_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpneq_usph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_une_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpneq_usph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"une",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <8 x i16> @test_v8f16_uno_s(<8 x i16> %a, <8 x i16> %b, <8 x half> %f1, <8 x half> %f2) #0 {
; X86-LABEL: test_v8f16_uno_s:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcmpunord_sph 8(%ebp), %xmm2, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v8f16_uno_s:
; X64:       # %bb.0:
; X64-NEXT:    vcmpunord_sph %xmm3, %xmm2, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(
                                               <8 x half> %f1, <8 x half> %f2, metadata !"uno",
                                               metadata !"fpexcept.strict") #0
  %res = select <8 x i1> %cond, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %res
}

define <2 x i16> @test_v2f16_oeq_q(<2 x i16> %a, <2 x i16> %b, <2 x half> %f1, <2 x half> %f2) #0 {
; X86-LABEL: test_v2f16_oeq_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vucomish 8(%ebp), %xmm2
; X86-NEXT:    setnp %al
; X86-NEXT:    sete %cl
; X86-NEXT:    testb %al, %cl
; X86-NEXT:    setne %al
; X86-NEXT:    andl $1, %eax
; X86-NEXT:    kmovw %eax, %k0
; X86-NEXT:    vpsrld $16, %xmm2, %xmm2
; X86-NEXT:    vucomish 10(%ebp), %xmm2
; X86-NEXT:    setnp %al
; X86-NEXT:    sete %cl
; X86-NEXT:    testb %al, %cl
; X86-NEXT:    setne %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $14, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v2f16_oeq_q:
; X64:       # %bb.0:
; X64-NEXT:    vucomish %xmm3, %xmm2
; X64-NEXT:    setnp %al
; X64-NEXT:    sete %cl
; X64-NEXT:    testb %al, %cl
; X64-NEXT:    setne %al
; X64-NEXT:    andl $1, %eax
; X64-NEXT:    kmovw %eax, %k0
; X64-NEXT:    vpsrld $16, %xmm3, %xmm3
; X64-NEXT:    vpsrld $16, %xmm2, %xmm2
; X64-NEXT:    vucomish %xmm3, %xmm2
; X64-NEXT:    setnp %al
; X64-NEXT:    sete %cl
; X64-NEXT:    testb %al, %cl
; X64-NEXT:    setne %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $14, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <2 x i1> @llvm.experimental.constrained.fcmp.v2f16(
                                               <2 x half> %f1, <2 x half> %f2, metadata !"oeq",
                                               metadata !"fpexcept.strict") #0
  %res = select <2 x i1> %cond, <2 x i16> %a, <2 x i16> %b
  ret <2 x i16> %res
}

define <2 x i16> @test_v2f16_ogt_q(<2 x i16> %a, <2 x i16> %b, <2 x half> %f1, <2 x half> %f2) #0 {
; X86-LABEL: test_v2f16_ogt_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vcomish 8(%ebp), %xmm2
; X86-NEXT:    seta %al
; X86-NEXT:    andl $1, %eax
; X86-NEXT:    kmovw %eax, %k0
; X86-NEXT:    vpsrld $16, %xmm2, %xmm2
; X86-NEXT:    vcomish 10(%ebp), %xmm2
; X86-NEXT:    seta %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $14, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v2f16_ogt_q:
; X64:       # %bb.0:
; X64-NEXT:    vcomish %xmm3, %xmm2
; X64-NEXT:    seta %al
; X64-NEXT:    andl $1, %eax
; X64-NEXT:    kmovw %eax, %k0
; X64-NEXT:    vpsrld $16, %xmm3, %xmm3
; X64-NEXT:    vpsrld $16, %xmm2, %xmm2
; X64-NEXT:    vcomish %xmm3, %xmm2
; X64-NEXT:    seta %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $14, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <2 x i1> @llvm.experimental.constrained.fcmps.v2f16(
                                               <2 x half> %f1, <2 x half> %f2, metadata !"ogt",
                                               metadata !"fpexcept.strict") #0
  %res = select <2 x i1> %cond, <2 x i16> %a, <2 x i16> %b
  ret <2 x i16> %res
}

define <4 x i16> @test_v4f16_oge_q(<4 x i16> %a, <4 x i16> %b, <4 x half> %f1, <4 x half> %f2) #0 {
; X86-LABEL: test_v4f16_oge_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vucomish 8(%ebp), %xmm2
; X86-NEXT:    setae %al
; X86-NEXT:    andl $1, %eax
; X86-NEXT:    kmovw %eax, %k0
; X86-NEXT:    vpsrld $16, %xmm2, %xmm3
; X86-NEXT:    vucomish 10(%ebp), %xmm3
; X86-NEXT:    setae %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $14, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k0
; X86-NEXT:    movw $-5, %ax
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kandw %k1, %k0, %k0
; X86-NEXT:    vmovshdup {{.*#+}} xmm3 = xmm2[1,1,3,3]
; X86-NEXT:    vucomish 12(%ebp), %xmm3
; X86-NEXT:    setae %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $13, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k0
; X86-NEXT:    movw $-9, %ax
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kandw %k1, %k0, %k0
; X86-NEXT:    vpsrlq $48, %xmm2, %xmm2
; X86-NEXT:    vucomish 14(%ebp), %xmm2
; X86-NEXT:    setae %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $12, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v4f16_oge_q:
; X64:       # %bb.0:
; X64-NEXT:    vucomish %xmm3, %xmm2
; X64-NEXT:    setae %al
; X64-NEXT:    andl $1, %eax
; X64-NEXT:    kmovw %eax, %k0
; X64-NEXT:    vpsrld $16, %xmm3, %xmm4
; X64-NEXT:    vpsrld $16, %xmm2, %xmm5
; X64-NEXT:    vucomish %xmm4, %xmm5
; X64-NEXT:    setae %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $14, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k0
; X64-NEXT:    movw $-5, %ax
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kandw %k1, %k0, %k0
; X64-NEXT:    vmovshdup {{.*#+}} xmm4 = xmm3[1,1,3,3]
; X64-NEXT:    vmovshdup {{.*#+}} xmm5 = xmm2[1,1,3,3]
; X64-NEXT:    vucomish %xmm4, %xmm5
; X64-NEXT:    setae %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $13, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k0
; X64-NEXT:    movw $-9, %ax
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kandw %k1, %k0, %k0
; X64-NEXT:    vpsrlq $48, %xmm3, %xmm3
; X64-NEXT:    vpsrlq $48, %xmm2, %xmm2
; X64-NEXT:    vucomish %xmm3, %xmm2
; X64-NEXT:    setae %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $12, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <4 x i1> @llvm.experimental.constrained.fcmp.v4f16(
                                               <4 x half> %f1, <4 x half> %f2, metadata !"oge",
                                               metadata !"fpexcept.strict") #0
  %res = select <4 x i1> %cond, <4 x i16> %a, <4 x i16> %b
  ret <4 x i16> %res
}

define <4 x i16> @test_v4f16_olt_q(<4 x i16> %a, <4 x i16> %b, <4 x half> %f1, <4 x half> %f2) #0 {
; X86-LABEL: test_v4f16_olt_q:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $16, %esp
; X86-NEXT:    vmovsh {{.*#+}} xmm3 = mem[0],zero,zero,zero,zero,zero,zero,zero
; X86-NEXT:    vcomish %xmm2, %xmm3
; X86-NEXT:    seta %al
; X86-NEXT:    andl $1, %eax
; X86-NEXT:    kmovw %eax, %k0
; X86-NEXT:    vpsrld $16, %xmm2, %xmm3
; X86-NEXT:    vmovsh {{.*#+}} xmm4 = mem[0],zero,zero,zero,zero,zero,zero,zero
; X86-NEXT:    vcomish %xmm3, %xmm4
; X86-NEXT:    seta %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $14, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k0
; X86-NEXT:    movw $-5, %ax
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kandw %k1, %k0, %k0
; X86-NEXT:    vmovshdup {{.*#+}} xmm3 = xmm2[1,1,3,3]
; X86-NEXT:    vmovsh {{.*#+}} xmm4 = mem[0],zero,zero,zero,zero,zero,zero,zero
; X86-NEXT:    vcomish %xmm3, %xmm4
; X86-NEXT:    seta %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $13, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k0
; X86-NEXT:    movw $-9, %ax
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kandw %k1, %k0, %k0
; X86-NEXT:    vpsrlq $48, %xmm2, %xmm2
; X86-NEXT:    vmovsh {{.*#+}} xmm3 = mem[0],zero,zero,zero,zero,zero,zero,zero
; X86-NEXT:    vcomish %xmm2, %xmm3
; X86-NEXT:    seta %al
; X86-NEXT:    kmovd %eax, %k1
; X86-NEXT:    kshiftlw $15, %k1, %k1
; X86-NEXT:    kshiftrw $12, %k1, %k1
; X86-NEXT:    korw %k1, %k0, %k1
; X86-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: test_v4f16_olt_q:
; X64:       # %bb.0:
; X64-NEXT:    vcomish %xmm2, %xmm3
; X64-NEXT:    seta %al
; X64-NEXT:    andl $1, %eax
; X64-NEXT:    kmovw %eax, %k0
; X64-NEXT:    vpsrld $16, %xmm2, %xmm4
; X64-NEXT:    vpsrld $16, %xmm3, %xmm5
; X64-NEXT:    vcomish %xmm4, %xmm5
; X64-NEXT:    seta %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $14, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k0
; X64-NEXT:    movw $-5, %ax
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kandw %k1, %k0, %k0
; X64-NEXT:    vmovshdup {{.*#+}} xmm4 = xmm2[1,1,3,3]
; X64-NEXT:    vmovshdup {{.*#+}} xmm5 = xmm3[1,1,3,3]
; X64-NEXT:    vcomish %xmm4, %xmm5
; X64-NEXT:    seta %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $13, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k0
; X64-NEXT:    movw $-9, %ax
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kandw %k1, %k0, %k0
; X64-NEXT:    vpsrlq $48, %xmm2, %xmm2
; X64-NEXT:    vpsrlq $48, %xmm3, %xmm3
; X64-NEXT:    vcomish %xmm2, %xmm3
; X64-NEXT:    seta %al
; X64-NEXT:    kmovd %eax, %k1
; X64-NEXT:    kshiftlw $15, %k1, %k1
; X64-NEXT:    kshiftrw $12, %k1, %k1
; X64-NEXT:    korw %k1, %k0, %k1
; X64-NEXT:    vpblendmw %xmm0, %xmm1, %xmm0 {%k1}
; X64-NEXT:    retq
  %cond = call <4 x i1> @llvm.experimental.constrained.fcmps.v4f16(
                                               <4 x half> %f1, <4 x half> %f2, metadata !"olt",
                                               metadata !"fpexcept.strict") #0
  %res = select <4 x i1> %cond, <4 x i16> %a, <4 x i16> %b
  ret <4 x i16> %res
}

attributes #0 = { strictfp nounwind }

declare <2 x i1> @llvm.experimental.constrained.fcmp.v2f16(<2 x half>, <2 x half>, metadata, metadata)
declare <2 x i1> @llvm.experimental.constrained.fcmps.v2f16(<2 x half>, <2 x half>, metadata, metadata)
declare <4 x i1> @llvm.experimental.constrained.fcmp.v4f16(<4 x half>, <4 x half>, metadata, metadata)
declare <4 x i1> @llvm.experimental.constrained.fcmps.v4f16(<4 x half>, <4 x half>, metadata, metadata)
declare <8 x i1> @llvm.experimental.constrained.fcmp.v8f16(<8 x half>, <8 x half>, metadata, metadata)
declare <8 x i1> @llvm.experimental.constrained.fcmps.v8f16(<8 x half>, <8 x half>, metadata, metadata)
