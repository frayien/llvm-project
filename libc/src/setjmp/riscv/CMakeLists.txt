add_entrypoint_object(
  setjmp
  SRCS
    setjmp.cpp
  HDRS
    ../setjmp_impl.h
  DEPENDS
    libc.hdr.types.jmp_buf
  COMPILE_OPTIONS
    ${libc_opt_high_flag}
    -fomit-frame-pointer
)

add_entrypoint_object(
  longjmp
  SRCS
    longjmp.cpp
  HDRS
    ../longjmp.h
  DEPENDS
    libc.hdr.types.jmp_buf
  COMPILE_OPTIONS
    ${libc_opt_high_flag}
    -fomit-frame-pointer
)
