section .data
cero: times 4 dd 0xff_00_00_00
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
%define src rdi
%define dst rsi
%define width rdx
%define height rcx
%define src_row_size r8
%define fourth_row_offset r9
%define column r10
%define row r11
%define first_row xmm0
%define second_row xmm1
%define third_row xmm2
%define fourth_row xmm3
%define vector_maximum xmm4
%define rotated_vector_maximum xmm6
%define mask xmm8
Cuadrados_asm:
push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rsp, 8
mov rbx, src
mov r12, dst
mov r13, width
mov r14, height
mov r15, src_row_size
;preparing the call to CompletarConCeros.
mov rdi, rsi
mov rsi, rdx
mov rdx, rcx
mov rcx, r8
call CompletarConCeros
;restoring variables.
mov src, rbx
mov dst, r12
mov width, r13
mov height, r14
mov src_row_size, r15
mov r9, r15
shl width, 32
shr width, 32
shl height, 32
shr height, 32
shl src_row_size, 32
shr src_row_size, 32
shl fourth_row_offset, 32
shr fourth_row_offset, 32
lea src, [src+src_row_size*4 +16]
lea dst, [dst+src_row_size*4 +16]
movdqu mask, [rotarizquierdacuatrobytes]
xor column, column
xor row, row
add column, 4
add row, 4
sub width, 4
sub height, 4
;writing r8*3 in r9
add fourth_row_offset, fourth_row_offset
add fourth_row_offset, src_row_size
;from top to bottom
.cicloRows:
cmp row, height
je .finCicloRows
;from left to right
.cicloColumns:
cmp column, width
je .finCicloColumns
movdqu first_row, [src]
movdqu second_row, [src+src_row_size]
movdqu third_row, [src+src_row_size*2]
movdqu fourth_row, [src+fourth_row_offset]
jmp .hallarMaximos
.retornarDeMaximos:
movss [dst], vector_maximum
lea src, [src+4]
lea dst, [dst+4]
inc column
jmp .cicloColumns
.finCicloColumns:
inc row
xor column, column
add column, 4
lea src, [src+32]
lea dst, [dst+32]
jmp .cicloRows
.hallarMaximos:
pxor vector_maximum, vector_maximum
pmaxub vector_maximum, first_row
pmaxub vector_maximum, second_row
pmaxub vector_maximum, third_row
pmaxub vector_maximum, fourth_row
movdqu rotated_vector_maximum, vector_maximum
pshufb rotated_vector_maximum, mask
pmaxub vector_maximum, rotated_vector_maximum
pshufb rotated_vector_maximum, mask
pmaxub vector_maximum, rotated_vector_maximum
pshufb rotated_vector_maximum, mask
pmaxub vector_maximum, rotated_vector_maximum
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

;rdi <-- dst
;rsi <-- width
;rdx <-- height
;rcx <-- src_row_size
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
mov r12, rdi
mov r13d, esi
mov r14d, edx
mov r15d, ecx
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
