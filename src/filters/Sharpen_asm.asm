section .data
alphaMask:  times 4 dd 0xff_00_00_00

global Sharpen_asm
Sharpen_asm:
  ; rdi <-- uint8_t *src
  ; rsi <-- uint8_t *dst
  ; edx <-- int width
  ; ecx <-- int height
  ; r8d  <-- int src_row_size
  ; r9d  <-- int dst_row_size
  push rbp
  mov rbp, rsp
  push rdi
  push rsi
  push rdx
  push rcx
  push r8
  push r9
  push r12
  push r13

  xor r10, r10

  sub ecx, 2
  ; sub edx, 1

  mov rax, rdi

  add rsi, r8

.rows:
  cmp r10d, ecx
  je .end
  xor r11, r11
  .cols:
    cmp r11d, edx
    je .nextRow

    ; tengo en registros las filas que necesito
    shl r11, 2
    movdqu xmm0, [rax + r11]
    add r11, r8
    movdqu xmm1, [rax + r11]
    add r11, r8
    movdqu xmm2, [rax + r11]
    sub r11, r8 
    sub r11, r8 
    shr r11, 2

    ; minus current row
    pxor xmm10, xmm10
    movdqu xmm3, xmm0             ; xmm3 <-- xmm0 high
    punpckhbw xmm3, xmm10
    movdqu xmm4, xmm0             ; xmm4 <-- xmm0 low
    punpcklbw xmm4, xmm10

    pxor xmm11, xmm11
    psubw xmm11, xmm3
    psrldq xmm3, 8
    psubw xmm11, xmm3
    psrldq xmm4, 8
    psubw xmm11, xmm4

    ; minus current row + 2
    movdqu xmm3, xmm2             ; xmm3 <-- xmm2 high
    punpckhbw xmm3, xmm10
    movdqu xmm4, xmm2             ; xmm4 <-- xmm2 low
    punpcklbw xmm4, xmm10

    psubw xmm11, xmm3
    psrldq xmm3, 8
    psubw xmm11, xmm3
    psrldq xmm4, 8
    psubw xmm11, xmm4

    ; current row + 1 (minus j+0 and j+2, add 9 times j+1)
    movdqu xmm3, xmm1             ; xmm3 <-- xmm1 high
    punpckhbw xmm3, xmm10
    movdqu xmm4, xmm1             ; xmm4 <-- xmm1 low
    punpcklbw xmm4, xmm10

    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    paddw xmm11, xmm3
    psrldq xmm3, 8
    psubw xmm11, xmm3
    psrldq xmm4, 8
    psubw xmm11, xmm4

    ; pack data from low xmm11
    packuswb xmm11, xmm11
    movd r13d, xmm11

    ; algo
    ; mov dword [rsi + r11 * 4], 0xFF_FF_00_00
    inc r11
    inc r11
    mov dword [rsi + r11 * 4], r13d
    dec r11
    jmp .cols

  .nextRow:
    inc r10d
    add rdi, r8
    mov rax, rdi
    add rsi, r8
    jmp .rows

.end:
  pop r13
  pop r12
  pop r9
  pop r8
  pop rcx
  pop rdx
  pop rsi
  pop rdi
  call paintBordersASM
  pop rbp
  ret

paintBordersASM:
  push rbp
  mov rbp, rsp

  movdqu xmm10, [alphaMask]

  xor r9, r9

.nextTopRowColumn:
  cmp r9, r8
  je .continueWithMiddle
  movdqu [rsi + r9], xmm10
  add r9, 16
  jmp .nextTopRowColumn

.continueWithMiddle:
  add rsi, r8
  xor r9, r9
  mov r10, rdx
  shl r10, 2
  sub r10, 4
  dec rcx

.middleRows:
  cmp r9, rcx
  je .continueWithBottom
  movd [rsi], xmm10
  movd [rsi + r10], xmm10
  add rsi, r8
  inc r9
  jmp .middleRows

.continueWithBottom:
  sub rsi, r8
  xor r9, r9

.nextBottomRowColumn:
  cmp r9, r8
  je .end
  movdqu [rsi + r9], xmm10
  add r9, 16
  jmp .nextBottomRowColumn

.end:
  pop rbp
  ret