section .data
cero: times 4 dd 0x00_00_00_ff

section .text
global Cuadrados_asm
;rdi <-- src
;rsi <-- dst
;edx <-- width
;ecx <-- height
;r8d <-- src_row_size
;r9d <-- dst_row_size
;------------------------
;rbx <-- maxB
;r12 <-- maxG
;r13 <-- maxR
;r14 <-- ii
;r15 <-- jj
%define maxB rbx
%define maxG r12
%define maxR r13
%define ii r14d
%define jj r15d
%define column r10d
%define row r11d
Cuadrados_asm:
push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rsp, 8
call CompletarConCeros
;movdqu xmm0, [rdi]
;movdqu xmm1, [rsi]
;xor r14, r14
;xor r15, r15
; seteo en cero los primeros 4 bytes de rdx y rcx
;rol rdx, 32
;ror rdx, 32
;ror rcx, 32
;ror rcx, 32
;xor r10, r10
;xor r11, r11
;add r10, 4
;add r11, 4
;sub edx, 5
;sub ecx, 5
; from top to bottom
;.cicloRows:
;cmp row, ecx
;je .finCicloRows
;from left to right
;.cicloColumns:
;cmp column, edx
;je .finCicloColumns
;xor maxB, maxB
;xor maxG, maxG
;xor maxR, maxR
;xor ii, ii
;xor jj, jj
;,.cicloii:
;cmp ii, 3
;je .finCicloii
;.ciclojj:
;cmp jj, 3
;je .finCiclojj
;.finCiclojj:
;inc ii
;jmp .cicloii
;.finCicloColumns:
;inc r11d
;jmp .cicloRows
;.finCicloRows:
add rsp, 8
pop r15
pop r14
pop r13
pop r12
pop rbx
pop rbp
ret

;rdi <-- src
;rsi <-- dst
;edx <-- width
;ecx <-- height
;r8d <-- src_row_size
;r9d <-- dst_row_size
;--------------------
;r12 guardo dst
;r13 guardo width
;r14 guardo height
;r15 guardo src_row_size
CompletarConCeros:
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
xor r12, r12
xor r13, r13
xor r14, r14
xor r15, r15
mov r12, rsi
mov r13d, edx
mov r14d, ecx
mov r15d, r8d
movdqu xmm2, [cero]
shr r13, 1
; r8 <--- column index
; r9 <--- row index
xor r8, r8
.comienzo:
xor r9, r9
.cicloLargoVertical:
cmp r9, 4
je .finCicloLargo
.cicloLargoHorizontal:
cmp r8d, r13d
je .finCicloLargoHorizontal
movdqu [r12+r8*8], xmm2
inc r8
inc r8
jmp .cicloLargoHorizontal
.finCicloLargoHorizontal:
xor r8, r8
inc r9
add r12, r15
jmp .cicloLargoVertical
.finCicloLargo:
cmp r11,1
je .fin
mov r10d, r14d
sub r10d, 4
.cicloIntermedio:
cmp r9d, r10d
je .finCicloIntermedio
movdqu [r12], xmm2
mov r8, r15
sub r8, 16
movdqu [r12+r8], xmm2
xor r8, r8
inc r9
add r12, r15
jmp .cicloIntermedio
.finCicloIntermedio:
mov r11, 1
jmp .comienzo
.fin:
pop r15
pop r14
pop r13
pop r12
pop rbp
ret
