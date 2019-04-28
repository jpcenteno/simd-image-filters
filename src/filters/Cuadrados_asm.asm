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
%define rbx maxB
%define r12 maxG
%define r13 maxR
%define r14d ii
%define r15d jj
%define r10d column
%define r11d row
Cuadrados_asm:
push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rsp, 8
movdqu xmm0, [rdi]
movdqu xmm1, [rsi]
xor r14, r14
xor r15, r15
; seteo en cero los primeros 4 bytes de rdx y rcx
rol rdx, 32
ror rdx, 32
ror rcx, 32
ror rcx, 32

xor r10, r10
xor r11, r11
add r10, 4
add r11, 4
sub edx, 5
sub ecx, 5
; from top to bottom
.cicloRows:
cmp row, ecx
je .finCicloRows

;from left to right
.cicloColumns:
cmp column, edx
je .finCicloColumns rows
xor maxB, maxB
xor maxG, maxG
xor maxR, maxR
xor ii, ii
xor jj, jj


.finCicloColumns:
inc r11d
jmp .cicloRows


add rsp, 8
pop r15
pop r14
pop r13
pop r12
pop rbp
ret
