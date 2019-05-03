section .data
alphaMask:  times 4 dd 0xff_00_00_00
redMask:    times 4 dd 0x00_ff_00_00
greenMask:  times 4 dd 0x00_00_ff_00
blueMask:   times 4 dd 0x00_00_00_ff

section .text
global Offset_asm
Offset_asm:
  ; rdi <-- uint8_t *src
  ; rsi <-- uint8_t *dst
  ; edx <-- int width
  ; ecx <-- int height
  ; r8d  <-- int src_row_size
  ; r9d  <-- int dst_row_size 
  push rbp
  mov rbp, rsp
  push r12
  push r13

  movdqu xmm10, [alphaMask]
  movdqu xmm11, [redMask]
  movdqu xmm12, [greenMask]
  movdqu xmm13, [blueMask]
  
  xor r10, r10
  xor r11, r11
  shl rdx, 2
  sub ecx, 16

  xor r8, r8
  xor r9, r9

  call paintBordersASM

  times 8 add rsi, rdx
  times 8 add rdi, rdx

  mov r9, rdx
  sub r9, 64

  mov rax, rdi
  add rax, 32
  
  mov r8, rsi
  add r8, 32

  xor r12, r12
  xor r13, r13

  mov r12, rax
  mov r13, r8

.forEachRow:
  cmp r10d, ecx
  je .end
  xor r11, r11
  .forEachColumn:
    cmp r11, r9
    je .nextRow
    movdqu xmm0, [rax + r11]

    ; src[i+8][j+8].r
    mov r12, rax
    add r12, r11
    add r12, 32
    movdqu xmm1, [r12 + rdx * 8]
    pand xmm1, xmm11

    ; src[i][j+8].g
    mov r12, rax
    add r12, r11
    add r12, 32
    movdqu xmm2, [r12]
    pand xmm2, xmm12

    ; src[i+8][j].b
    mov r12, rax
    add r12, r11
    movdqu xmm3, [r12 + rdx * 8]
    pand xmm3, xmm13

    pxor xmm0, xmm0
    paddq xmm0, xmm1
    paddq xmm0, xmm2
    paddq xmm0, xmm3
    paddq xmm0, xmm10

    movdqu [r8 + r11], xmm0
    add r11, 16
    jmp .forEachColumn
  .nextRow:
    add rdi, rdx
    add rsi, rdx

    mov rax, rdi
    add rax, 32

    mov r8, rsi
    add r8, 32

    inc r10d
    jmp .forEachRow

.end:
  pop r13
  pop r12
  pop rbp
  ret

paintBordersASM:
  push rbp
  mov rbp, rsp
  push rcx
  push rdx
  push rsi
  push r8
  push r9
  sub rsp, 8

  mov r8, 8

.topRows:
  cmp r8, 0
  je .continueWithMiddle
  xor r9, r9
  .nextTopRowColumn:
    cmp r9, rdx
    je .nextTopRow
    movdqu [rsi + r9], xmm10
    add r9, 16
    jmp .nextTopRowColumn
  .nextTopRow:
    add rsi, rdx
    dec r8
    jmp .topRows

.continueWithMiddle:
  xor r8, r8
  mov r9, rdx
  sub r9, 32

.middleRows:
  cmp r8, rcx
  je .continueWithBottom
  movdqu [rsi], xmm10
  movdqu [rsi + 16], xmm10
  movdqu [rsi + r9], xmm10
  movdqu [rsi + r9 + 16], xmm10
  add rsi, rdx
  inc r8
  jmp .middleRows

.continueWithBottom:
  mov r8, 8

.bottomRows:
  cmp r8, 0
  je .end
  xor r9, r9
  .nextBottomRowColumn:
    cmp r9, rdx
    je .nextBottomRow
    movdqu [rsi + r9], xmm10
    add r9, 16
    jmp .nextBottomRowColumn
  .nextBottomRow:
    add rsi, rdx
    dec r8
    jmp .bottomRows

.end:
  add rsp, 8
  pop r9
  pop r8
  pop rsi
  pop rdx
  pop rcx
  pop rbp
  ret