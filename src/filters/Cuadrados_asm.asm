section .data
cero: times 4 dd 0xff_00_00_00
pixel: times 4 dd 0xff_55_aa_ee
;rotarizquierdacuatrobytes: db  0x0a,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x2,0x01,0x00,0x0f,0x0e,0x0d,0x0c,0x0b
rotarizquierdacuatrobytes: db 0x0c,0x0d,0x0e,0x0f,0x00,0x01,0x02,0x03,0x4,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b
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
%define src rdi
%define dst rsi
%define width rdx
%define height rcx
%define src_row_size r8
%define dst_row_size r9
%define column r10
%define row r11
%define mascara xmm8
Cuadrados_asm:
push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rsp, 8
mov rbx, rdi
mov r12, rsi
mov r13, rdx
mov r14, rcx
mov r15, r8
call CompletarConCeros
mov rdi, rbx
mov rsi, r12
mov rdx, r13
mov rcx, r14
mov r8, r15
mov r9, r15
shl rdx, 32
shr rdx, 32
shl rcx, 32
shr rcx, 32
shl r8, 32
shr r8, 32
shl r9, 32
shr r9, 32
lea rdi, [rdi+src_row_size*4 +16]
lea rsi, [rsi+src_row_size*4 +16]
movdqu mascara, [rotarizquierdacuatrobytes]
; seteo en cero los primeros 4 bytes de rdx y rcx
xor column, column
xor row, row
add column, 4
add row, 4
sub width, 4
sub height, 4
; write r8*3 in r9
add r9, r9
add r9, r8
; from top to bottom
.cicloRows:
cmp row, height
je .finCicloRows
;from left to right
.cicloColumns:
cmp column, width
je .finCicloColumns
movdqu xmm0, [rdi]
movdqu xmm1, [rdi+r8]
movdqu xmm2, [rdi+r8*2]
movdqu xmm3, [rdi+r9]
jmp .hallarMaximos
.retornarDeMaximos:
movss [rsi], xmm4
lea rdi, [rdi+4]
lea rsi, [rsi+4]
inc column
jmp .cicloColumns
.finCicloColumns:
inc row
xor column, column
add column, 4
lea rdi, [rdi+32]
lea rsi, [rsi+32]
jmp .cicloRows
.hallarMaximos:
pxor xmm4, xmm4
pmaxub xmm4, xmm0
pmaxub xmm4, xmm1
pmaxub xmm4, xmm2
pmaxub xmm4, xmm3
movdqu xmm6, xmm4
pshufb xmm6, mascara
pmaxub xmm4, xmm6
pshufb xmm6, mascara
pmaxub xmm4, xmm6
pshufb xmm6, mascara
pmaxub xmm4, xmm6
jmp .retornarDeMaximos
.finCicloRows:
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
