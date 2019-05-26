section .data
alphaMask:  times 4 dd 0xff_00_00_00

section .text
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

  sub ecx, 2                      ; se considera la matriz del operador y el borde para el límite
  sub edx, 3                      ; idem

  mov rax, rdi                    ; rax <-- puntero a fila actual en img src

  add rsi, r8                     ; avanzo *dst una fila (por borde)
  add rsi, 4                      ; avanzo al primer pixel a procesar (por borde)

.rows:
  cmp r10d, ecx
  je .end
  xor r11, r11
  .cols:
    cmp r11d, edx
    jge .nextRow

    ; tengo en registros las filas que necesito
    shl r11, 2                    ; contador en bytes
    movdqu xmm0, [rax + r11]      ; [ inf 3 | inf 2 | inf 1 | inf 0 ] pixeles fila inf operador
    add r11, r8
    movdqu xmm1, [rax + r11]      ; [ med 3 | med 2 | med 1 | med 0 ] pixeles fila media operador
    add r11, r8
    movdqu xmm2, [rax + r11]      ; [ sup 3 | sup 2 | sup 1 | sup 0 ] pixeles fila superior operador
    sub r11, r8
    sub r11, r8
    shr r11, 2                    ; contador en pixeles

    ; fila inf operador
    pxor xmm10, xmm10
    movdqu xmm3, xmm0             ; xmm3  <-- xmm0 high
    punpckhbw xmm3, xmm10         ; xmm3  <-- [ inf3 | inf2 ]
    movdqu xmm4, xmm0             ; xmm4  <-- xmm0 low
    punpcklbw xmm4, xmm10         ; xmm4  <-- [ inf1 | inf0 ]

    pxor xmm11, xmm11             ; acumulo en xmm11
    psubw xmm11, xmm3             ; xmm11 <-- [ -inf3 | -inf2 ]

    psubw xmm11, xmm4             ; xmm11 <-- [ -inf3 - inf1 | -inf2 - inf0 ]
    pslldq xmm3, 8                ; xmm3  <-- [ inf2 |   0  ]
    psrldq xmm4, 8                ; xmm4  <-- [   0  | inf1 ]
    por xmm3, xmm4                ; xmm4  <-- [ inf2 | inf1 ]

    psubw xmm11, xmm3             ; xmm11 <-- [ -inf3 - inf2 - inf1 | -inf2 - inf1 - inf0 ]

    ; fila sup operador
    movdqu xmm3, xmm2             ; xmm3 <-- xmm2 high
    punpckhbw xmm3, xmm10         ; xmm3  <-- [ sup3 | sup2 ]
    movdqu xmm4, xmm2             ; xmm4 <-- xmm2 low
    punpcklbw xmm4, xmm10         ; xmm4  <-- [ sup1 | sup0 ]

    psubw xmm11, xmm3             ; repito la lógica restando los valores en xmm11

    psubw xmm11, xmm4
    pslldq xmm3, 8
    psrldq xmm4, 8
    por xmm3, xmm4
    psubw xmm11, xmm3             ; xmm11 <-- [ -i3-i2-i1-s3-s2-s1 | -i2-i1-i0-s2-s1-s0 ]

    ; fila med operador (minus j+0 and j+2, add 9 times j+1)
    movdqu xmm3, xmm1             ; xmm3 <-- xmm1 high
    punpckhbw xmm3, xmm10         ; xmm3  <-- [ med3 | med2 ]
    movdqu xmm4, xmm1             ; xmm4 <-- xmm1 low
    punpcklbw xmm4, xmm10         ; xmm4  <-- [ med1 | med0 ]

    movdqu xmm5, xmm3             ; xmm5 <-- [ med3 | med2 ]
    movdqu xmm6, xmm4             ; xmm6 <-- [ med1 | med0 ]
    pslldq xmm5, 8                ; xmm5 <-- [ med2 |   0  ]
    psrldq xmm6, 8                ; xmm6 <-- [   0  | med1 ]
    por xmm5, xmm6                ; xmm5 <-- [ med2 | med1 ]
    paddw xmm11, xmm5             ; sumo 9 veces
    paddw xmm11, xmm5
    paddw xmm11, xmm5
    paddw xmm11, xmm5
    paddw xmm11, xmm5
    paddw xmm11, xmm5
    paddw xmm11, xmm5
    paddw xmm11, xmm5
    paddw xmm11, xmm5             ; xmm11 <-- [ -i3-i2-i1-s3-s2-s1+(9*m2) | -i2-i1-i0-s2-s1-s0+(9*m1) ]
    psubw xmm11, xmm3             ; xmm11 <-- [ -i3-i2-i1-s3-s2-s1-m3+(9*m2) | -i2-i1-i0-s2-s1-s0-m2+(9*m1) ]
    psubw xmm11, xmm4             ; xmm11 <-- [ -i3-i2-i1-s3-s2-s1-m3+(9*m2)-m1 | -i2-i1-i0-s2-s1-s0-m2+(9*m1)-m0 ]

    ; pack data from low xmm11
    packuswb xmm11, xmm11         ; xmm11 <-- [ sharpen1 | sharpen0 | sharpen1 | sharpen 0 ]
    movq r13, xmm11               ; r13 <-- [ sharpen1 | sharpen0 ] proceso de a dos pixeles

    mov qword [rsi + r11 * 4], r13
    add r11, 2                    ; paso a los dos pixeles siguientes

    jmp .cols

  .nextRow:
    inc r10d
    add rdi, r8                   ; dst siguientes fila
    mov rax, rdi
    add rsi, r8                   ; src siguiente fila
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
  ; rdi <-- uint8_t *src
  ; rsi <-- uint8_t *dst
  ; edx <-- int width
  ; ecx <-- int height
  ; r8d  <-- int src_row_size
  ; r9d  <-- int dst_row_size
  push rbp
  mov rbp, rsp

  movdqu xmm10, [alphaMask]

  xor r9, r9

.nextTopRowColumn:
  cmp r9, r8
  je .continueWithMiddle
  movdqu [rsi + r9], xmm10          ; guardo en src, xmm10 = [ idem P3 | idem P2 | idem P1 | 0xFF 0 0 0 ]
  add r9, 16                        ; guardo de a 4
  jmp .nextTopRowColumn

.continueWithMiddle:
  add rsi, r8                       ; prox fila
  xor r9, r9
  mov r10, rdx
  shl r10, 2                        ; width en bytes
  sub r10, 4                        ; en r10 tengo el offset hasta el otro borde vertical
  dec rcx

.middleRows:
  cmp r9, rcx
  je .continueWithBottom
  movd [rsi], xmm10                 ; primer borde vertical
  movd [rsi + r10], xmm10           ; segundo borde vertical
  add rsi, r8                       ; prox fila
  inc r9
  jmp .middleRows

.continueWithBottom:
  sub rsi, r8                       ; rsi tengo la ultima fila para el borde
  xor r9, r9

.nextBottomRowColumn:
  cmp r9, r8
  je .end
  movdqu [rsi + r9], xmm10          ; guardo en src, xmm10 = [ idem P3 | idem P2 | idem P1 | 0xFF 0 0 0 ]
  add r9, 16                        ; guardo de a 4
  jmp .nextBottomRowColumn

.end:
  pop rbp
  ret
