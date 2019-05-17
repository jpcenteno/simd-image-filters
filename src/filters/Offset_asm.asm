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
  shl rdx, 2                              ; rdx <-- width en bytes
  sub ecx, 16                             ; se consideran el offset+8 y el borde de 8 pixeles

  call paintBordersASM

  times 8 add rsi, rdx                    ; se avanzan los punteros hasta luego del borde
  times 8 add rdi, rdx

  mov r9, rdx                             ; r9 <-- width en bytes
  sub r9, 64                              ; offset+8 y 8 pixeles del borde

  mov rax, rdi                            ; rax <-- puntero a fila actual en img src
  add rax, 32                             ; 8 pixeles * 4 bytes = 32, los primeros 8 pixeles del borde
  mov r12, rax                            ; r12 <-- puntero a primer pixel a procesar en src
  
  mov r8, rsi                             ; r8 <-- puntero a fila actual en img dst
  add r8, 32                              ; 8 pixeles * 4 bytes = 32, los primeros 8 pixeles del borde
  mov r13, r8                             ; r13 <-- puntero a primer pixel a guardar en dst

.forEachRow:
  cmp r10d, ecx
  je .end
  xor r11, r11

  .forEachColumn:
    cmp r11, r9
    je .nextRow
    movdqu xmm0, [rax + r11]              ; xmm0 <-- [ A3 R3 G3 B3 | A2 R2 G2 B2 | A1 R1 G1 B1 | A0 R0 G0 B0 ]

    ; src[i+8][j+8].r
    mov r12, rax                          ; r12 <-- puntero a fila actual
    add r12, r11                          ; r12 <-- puntero a fila actual y pixel actual
    add r12, 32                           ; r12 <-- puntero a fila actual y pixel actual + 8
    movdqu xmm1, [r12 + rdx * 8]          ; xmm1 <-- [ idem P3 | idem P2 | idem P1 | A0[+8][+8] R0[+8][+8] G0[+8][+8] B0[+8][+8] ]
    pand xmm1, xmm11                      ; xmm1 <-- [ idem P3 | idem P2 | idem P1 | 0 R0[+8][+8] 0 0 ]

    ; src[i][j+8].g
    mov r12, rax                          ; r12 <-- puntero a fila actual
    add r12, r11                          ; r12 <-- puntero a fila actual y pixel actual
    add r12, 32                           ; r12 <-- puntero a fila actual y pixel actual + 8
    movdqu xmm2, [r12]                    ; xmm2 <-- [ idem P3 | idem P2 | idem P1 | A0[+0][+8] R0[+0][+8] G0[+0][+8] B0[+0][+8] ]
    pand xmm2, xmm12                      ; xmm2 <-- [ idem P3 | idem P2 | idem P1 | 0 0 G0[+0][+8] 0 ]

    ; src[i+8][j].b
    mov r12, rax                          ; r12 <-- puntero a fila actual
    add r12, r11                          ; r12 <-- puntero a fila actual y pixel actual
    movdqu xmm3, [r12 + rdx * 8]          ; xmm3 <-- [ idem P3 | idem P2 | idem P1 | A0[+8][+0] R0[+8][+0] G0[+8][+0] B0[+8][+0] ]
    pand xmm3, xmm13                      ; xmm3 <-- [ idem P3 | idem P2 | idem P1 | 0 0 0 B0[+8][+0] ]

    pxor xmm0, xmm0                       ; xmm0 <-- [ 0 | 0 | 0 | 0 ]
    por xmm0, xmm1                        ; xmm0 <-- [ idem P3 | idem P2 | idem P1 | 0 R0[+8][+8] 0 0 ]
    por xmm0, xmm2                        ; xmm0 <-- [ idem P3 | idem P2 | idem P1 | 0 R0[+8][+8] G0[+0][+8] 0 ]
    por xmm0, xmm3                        ; xmm0 <-- [ idem P3 | idem P2 | idem P1 | 0 R0[+8][+8] G0[+0][+8] B0[+8][+0] ]
    por xmm0, xmm10                       ; xmm0 <-- [ idem P3 | idem P2 | idem P1 | 0xFF R0[+8][+8] G0[+0][+8] B0[+8][+0] ]

    movdqu [r8 + r11], xmm0               ; guardo 4 pixeles procesados
    add r11, 16                           ; avanzo a los 4 siguientes
    jmp .forEachColumn

  .nextRow:
    add rdi, rdx                          ; avanzo a siguiente fila dst
    add rsi, rdx                          ; avanzo a siguiente fila src

    mov rax, rdi
    add rax, 32                           ; rax <-- siguiente fila dst, primer pixel a procesar luego del borde

    mov r8, rsi
    add r8, 32                            ; r8 <-- siguiente fila src, primer pixel a guardar luego del borde

    inc r10d                              ; siguiente fila
    jmp .forEachRow

.end:
  pop r13
  pop r12
  pop rbp
  ret


paintBordersASM:
  ; rdi <-- uint8_t *src
  ; rsi <-- uint8_t *dst
  ; rdx <-- int width en bytes
  ; ecx <-- int height menos border y offset
  ; r8d  <-- int src_row_size
  ; r9d  <-- int dst_row_size
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
    movdqu [rsi + r9], xmm10            ; guardo en src, xmm10 = [ idem P3 | idem P2 | idem P1 | 0xFF 0 0 0 ]
    add r9, 16                          ; guardo de a 4
    jmp .nextTopRowColumn

  .nextTopRow:
    add rsi, rdx                        ; prox fila
    dec r8
    jmp .topRows

.continueWithMiddle:
  xor r8, r8
  mov r9, rdx
  sub r9, 32

.middleRows:
  cmp r8, rcx
  je .continueWithBottom
  movdqu [rsi], xmm10                   ; guardo en src, xmm10 = [ idem P3 | idem P2 | idem P1 | 0xFF 0 0 0 ]
  movdqu [rsi + 16], xmm10              ; idem para completar el primer borde vertical
  movdqu [rsi + r9], xmm10              ; idem para el segundo
  movdqu [rsi + r9 + 16], xmm10
  add rsi, rdx
  inc r8                                ; prox fila
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
    movdqu [rsi + r9], xmm10            ; guardo en src, xmm10 = [ idem P3 | idem P2 | idem P1 | 0xFF 0 0 0 ]
    add r9, 16                          ; guardo de a 4
    jmp .nextBottomRowColumn

  .nextBottomRow:
    add rsi, rdx                        ; prox fila
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