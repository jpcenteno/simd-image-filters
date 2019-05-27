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

;Making a stack frame.
push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rsp, 8

;Saving input data to registers.
mov rbx, src
mov r12, dst
mov r13, width
mov r14, height
mov r15, src_row_size

;Preparing the call to CompletarConCeros.
mov rdi, rsi
mov rsi, rdx
mov rdx, rcx
mov rcx, r8
call CompletarConCeros

;Restoring variables.
mov src, rbx
mov dst, r12
mov width, r13
mov height, r14
mov src_row_size, r15
mov r9, r15

;Cleaning registers from garbage on the upper bits.
shl width, 32
shr width, 32
shl height, 32
shr height, 32
shl src_row_size, 32
shr src_row_size, 32
shl fourth_row_offset, 32
shr fourth_row_offset, 32

;Moving src and dst pointers to the 4th row and column (starting from zero).
lea src, [src+src_row_size*4 +16]
lea dst, [dst+src_row_size*4 +16]

;Retrieve the mask from memory and store it in a register.
movdqu mask, [rotarizquierdacuatrobytes]

;Reset column and row index and start them at four.
xor column, column
xor row, row
add column, 4
add row, 4

;The right and lower limits are smaller because of the black border.
sub width, 4
sub height, 4

;Writing r8*3 in r9 (which is the offset to the 4th row).
add fourth_row_offset, fourth_row_offset
add fourth_row_offset, src_row_size

;Moving the row index from top to bottom.
.cicloRows:
cmp row, height
je .finCicloRows

;Moving the column index from left to right.
.cicloColumns:
cmp column, width
je .finCicloColumns

;Loading 4x4 matrix on XMM registers.
movdqu first_row, [src]
movdqu second_row, [src+src_row_size]
movdqu third_row, [src+src_row_size*2]
movdqu fourth_row, [src+fourth_row_offset]

;Find maximums and store in the vector_maximum register.
jmp .hallarMaximos

.retornarDeMaximos:
;Save maximums on the destination image.
movss [dst], vector_maximum

;Next iteration of the cycle: Move one byte to the right.
lea src, [src+4]
lea dst, [dst+4]
;Move to the next column.
inc column
jmp .cicloColumns

;Jump here when it reaches black border.
.finCicloColumns:
inc row
xor column, column
add column, 4

;Move the src and dst pointer the next non border pixel.
                        ; |     |     |     |     |        +0    +4    +8   +12
lea src, [src+32]       ; |0x00h|0x00h|0x00h|0x00h|--------|0x00h|0x00h|0x00h|0x00h|
lea dst, [dst+32]       ; +16   +20   +24   +28   +32
                        ; |0x00h|0x00h|0x00h|0x00h|--------|0x00h|0x00h|0x00h|0x00h|
jmp .cicloRows

;Algorithm for finding maximums:
.hallarMaximos:
pxor vector_maximum, vector_maximum

;Find maximum comparing row by row on each column.
pmaxub vector_maximum, first_row
pmaxub vector_maximum, second_row
pmaxub vector_maximum, third_row
pmaxub vector_maximum, fourth_row

movdqu rotated_vector_maximum, vector_maximum

;Rotate vector one pixel to the right and compare.
;Repeat four times to find the maximum among all pixels in the vector.
pshufb rotated_vector_maximum, mask
pmaxub vector_maximum, rotated_vector_maximum
pshufb rotated_vector_maximum, mask
pmaxub vector_maximum, rotated_vector_maximum
pshufb rotated_vector_maximum, mask
pmaxub vector_maximum, rotated_vector_maximum
jmp .retornarDeMaximos

;Disarm stack frame.
.finCicloRows:
add rsp, 8
pop r15
pop r14
pop r13
pop r12
pop rbx
pop rbp
ret

;Expected input:
;rdi <-- dst
;rsi <-- width
;rdx <-- height
;rcx <-- src_row_size
;--------------------
;Registers I will use to store data:
;r12 <-- dst
;r13 <-- width
;r14 <-- height
;r15 <-- src_row_size
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
