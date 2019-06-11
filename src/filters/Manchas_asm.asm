BITS 64

global Manchas_asm
extern malloc

section .rodata


    SS_2PI: dd 6.28318

    ALIGN 16

    ; Constantes para calcular `tono`
    PS_50: times 4 dd 50.0
    PS_25: times 4 dd 25.0

    PD_COMP_ALPHA: times 4 dd 0xFF000000

    PD_ZEROS:    times 4 dd 0x00
    PD_BYTE_MAX: times 4 dd 0xFF

    ; Para testear sat:
    ; Puedo pisar XMM0 antes de un llamado a SAT para testear la funcion que
    ; ande como espero.
    TEST_PD_SAT: dd 0xFFFFFFFF, 0x0FFFFFFF, 0xFF, 0x4F
    ; out esperado  [        0,         FF,   FF. 0x4F]

    PB_ALPHA_MASK: times 4 db 0x00, 0x00, 0x00, 0xff

section .bss


    ; Guardo aca punteros a estos arreglos para simplificar el pasaje de
    ; parametros.
    PTR_PF_SENII: resb 8 ; Puntero al array senii[]
    PTR_PF_COSJJ: resb 8 ; Puntero al array cosjj[]


    ALIGN 16

    ; Lugar en memoria estatica para preservar registros xmm. Uso esto en vez
    ; del stack por legibilidad.
    PB_PIXELS: resb 16
    PD_COMP_R: resb 16
    PD_COMP_G: resb 16
    PD_COMP_B: resb 16
    PD_TONO: resb 16

    DW_HEIGHT: resb 4


section .text

; PACKED_DWORD extraer(uint64_t offset, PACKED_DWORD pixels);
; xmm0                 rdi              xmm0
;
; Extrae un componente de los pixeles basado en el offset
%define offset_r 8
%define offset_g 16
%define offset_b 24
extract: ;{{{
    push rbp
    mov rbp, rsp

    push rdi
    pslld xmm0, [rsp]     ; Limpia parte alta
    psrld xmm0, 24        ; limpia parte baja

    pop rbp
    ret ; }}}


; PACKED_DWORD TONO(uint64_t i, uint64_t j);
; xmm0              rdi         rsi
;
; Calcula el vector con los valores de tono.
; Devuelve en xmm0 (parte baja) y xmm1 (parte alta)
tono: ; {{{
    push rbp
    mov rbp, rsp

    ; Construye vector [ senii[j], senii[j], senii[j], senii[j] ]
    mov rax, [PTR_PF_SENII]                    ; Posicion base array senii[]
    mov eax, [rax + rdi * 4]                ; Obtiene senii[i]
    pinsrd xmm0, eax, 0                     ; Inserta en dword[0]
    pinsrd xmm0, eax, 1                     ; Inserta en dword[1]
    pinsrd xmm0, eax, 2                     ; Inserta en dword[2]
    pinsrd xmm0, eax, 3                     ; Inserta en dword[3]

    ; Lee vector [ cosjj[j+0], cosjj[j+1], cosjj[j+2], cosjj[j+3] ]
    mov rax, [PTR_PF_COSJJ]                       ; Posicion base array cosjj
    movups xmm1, [rax + rsi * 4]               ; Carga el vector en registros

    ; multiplica senii * cosjj
    mulps xmm0, xmm1                          ; xmm0 = senii * cosjj

    ; Multiplica por 50
    movups xmm1, [PS_50]                      ; xmm1 = [50, 50, 50, 50]
    mulps xmm0, xmm1                          ; xmm0 = senii * cosjj * 50.0

    ; Substrae 25
    movups xmm1, [PS_25]                      ; xmm1 = [25, 25, 25, 25]
    subps xmm0, xmm1                          ; xmm0 = senii * cosjj * 50.0 - 25.0

    ; Convierto el vector tono a integers (dword) usando truncamiento.
    cvttps2dq xmm0, xmm0                      ; Convierte a 4xInt32

    ; Convierto los datos de dword (32bits) a word (16bits). Es el tipo de
    ; datos que vamos a usar para poder operar de a 2px en paralelo.
    packsswb xmm0, xmm0                       ; [T3,T2,T1,T0,T3,T2,T1,T0]
    ; Desempaqueto parte alta en xmm1
    movdqa xmm1, xmm0
    pshufhw xmm1, xmm1, 0b11111111            ; [t3,t3,t3,t3,??,??,??,??]
    pshuflw xmm1, xmm1, 0b10101010            ; [t3,t3,t3,t3,t2,t2,t2,t2]
    ; Desempaqueto parte baja en xmm0
    pshufhw xmm0, xmm0, 0b01010101            ; [t1,t1,t1,t1,T3,T2,T1,T0]
    pshuflw xmm0, xmm0, 0b00000000            ; [t1,t1,t1,t1,t0,t0,t0,t0]

    pop rbp
    ret ; }}}


; PACKED_DWORD SAT(PACKED_DWORD A)
;
; Devuelve un vector de 4 dwords cuyo valor esta acotado entre [0, 255].
sat: ; {{{
    push rbp
    mov rbp, rsp

    ; Acota inferiormente por 0.
    ; Via anular los elementos negativos.
    movdqu xmm1, xmm0                   ; xmm1 = [a3 a2 a1 a0]
    pxor xmm2, xmm2                     ; xmm2 = [ 0  0  0  0]
    pcmpgtd xmm1, xmm2                  ; xmm1 = [a3>0 a2>0 a1>0 a0>0]
    pand xmm0, xmm1                     ; Anula elemento si es negativo

    ; Acota superiormente el byte inferior por 255 (0xFF)
    movdqu xmm1, xmm0                   ; xmm1 = [a3 a2 a1 a0]
    movdqu xmm2, [PD_BYTE_MAX]          ; xmm2 = [0xFF, 0xFF, 0xFF, 0xFF]
    pcmpgtd xmm1, xmm2                  ; xmm1 = [a3>0xFF, ..., a0>0xFF]
    por xmm0, xmm1                      ; Sobreescribe con 0xFFFFFFFF los elementos mayores.

    ; Limpia parte superior para que el numero sea correcto en uint8_t
    pslld xmm0, 24                      ; [ ... | b0 0 0 0 | ...]
    psrld xmm0, 24                      ; [ ... | 0 0 0 b0 | ...]

    pop rbp
    ret ; }}}


; float* computar_sen_ii(uint32_t height, uint32_t n);
;
; Devuelve un array de floats (ss) con el valor de sen(ii) definido como
; sen( (2PI * float(i % n)) / n ). La longitud del array es `height`.
computar_sen_ii: ; {{{

    ; INPUT:
    ; EDI = height
    ; ESI = n

    push rbp
    mov rbp, rsp

    push r12
    push r13

    ; Preserva parametros
    mov r12d, edi                         ; Preserva 'height'
    mov r13d, esi                         ; Preserva 'n'

    ; Pide memoria para el array
    shl edi, 2                            ; (1er param) edi = height * 4 (tamano para array floats)
    call malloc                           ; rax = malloc(height * 4)
    mov rdi, rax                          ; preserva el arreglo. (rax se pisa en el loop)

    ; Loop donde escribe el array con los datos corresp. {{{

    ; Inicializa {{{
    xor rcx, rcx                          ; i = 0
    ; }}}

    ; Salta a la guarda
    jmp .cond

    .loop: ; Escribe a[i] {{{

        ; Calcula senii_i para este valor de i.

        ; Calcula edx = i % n
        xor edx, edx                    ; Anula parte alta dividendo
        mov eax, ecx                    ; dividendo = i
        div r13d                        ; edx = i % n (pisa RAX)

        ; Convierto a float. Ahora trabajo en FPU
        mov [rsp - 4], edx              ; hack para cargar `edx` en FPU
        fild dword [rsp -4]             ; push (i%n) al stack FPU

        ; * 2PI
        fld dword [SS_2PI]              ; push 2PI al stack FPU
        fmul                            ; FPU tiene 2PI*(i%n)

        ; / float(n)
        mov [rsp - 4], r13d             ; Hack para cargar `n` de edx al FPU
        fild dword [rsp - 4]            ; Push float(n) al FPU
        fdiv                            ; FPU = 2PI*(i%n)/n

        ; op sin
        fsin                            ; FPU = sin(2 PI ( 1 % n ) / n )

        fstp dword [rdi + rcx * 4]       ; Escribe el resltado en el array

    ; /.loop }}}

    ; Incrementa i
    inc rcx

    .cond: ; Guarda del loop {{{
    cmp ecx, r12d                         ; i < height
    jl .loop                              ; si es menor, loopea
    ; /.cond }}}

    ; }}}

    mov rax, rdi                         ; devuelve el arreglo

    ; Se espera a la salida del loop que:
    ; - valor de retorno RAX es puntero al inicio del array.
    ; - El array en RAX tiene los valores sen(ii) que debian computarse

    pop r13
    pop r12

    pop rbp
    ret ; /computar_sen_ii }}}


; float* computar_cos_jj(uint32_t width, uint32_t n);
;
; Devuelve un array de floats (ss) con el valor de cos(jj) definido como
; cos( (2PI * float(i % n)) / n ). La longitud del array es `width`.
computar_cos_jj: ; {{{

    ; INPUT:
    ; EDI = width
    ; ESI = n

    push rbp
    mov rbp, rsp

    push r12
    push r13

    ; Preserva parametros
    mov r12d, edi                         ; Preserva 'width'
    mov r13d, esi                         ; Preserva 'n'

    ; Pide memoria para el array
    shl edi, 2                            ; (1er param) edi = width * 4 (tamano para array floats)
    call malloc                           ; rax = malloc(width * 4)
    mov rdi, rax                          ; preserva el arreglo. (rax se pisa en el loop)

    ; Loop donde escribe el array con los datos corresp. {{{

    xor rcx, rcx                          ; j = 0
    ; Salta a la guarda
    jmp .cond

    .loop: ; Escribe a[j] {{{

        ; Calcula cos(jj[j]) para este valor de j.

        ; Calcula edx = i % n
        xor edx, edx                    ; Anula parte alta dividendo
        mov eax, ecx                    ; dividendo = j
        div r13d                        ; edx = j % n (pisa RAX)

        ; Convierto a float. Ahora trabajo en FPU
        mov [rsp - 4], edx              ; hack para cargar `edx` en FPU
        fild dword [rsp -4]             ; push (j%n) al stack FPU

        ; * 2PI
        fld dword [SS_2PI]              ; push 2PI al stack FPU
        fmul                            ; FPU tiene 2PI*(j%n)

        ; / float(n)
        mov [rsp - 4], r13d             ; Hack para cargar `n` de edx al FPU
        fild dword [rsp - 4]            ; Push float(n) al FPU
        fdiv                            ; FPU = 2PI*(j%n)/n

        ; op sin
        fcos                            ; FPU = cos(2 PI ( j % n ) / n )

        fstp dword [rdi + rcx * 4]       ; Escribe el resltado en el array

    ; /.loop }}}

    ; Incrementa i
    inc rcx

    .cond: ; Guarda del loop {{{
    cmp ecx, r12d                         ; i < width
    jl .loop                              ; si es menor, loopea
    ; /.cond }}}

    ; }}}

    mov rax, rdi                         ; devuelve el arreglo

    ; Se espera a la salida del loop que:
    ; - valor de retorno RAX es puntero al inicio del array.
    ; - El array en RAX tiene los valores sen(ii) que debian computarse

    pop r13
    pop r12

    pop rbp
    ret ; /computar_sen_ii }}}


; 1. rdi        <- uint8_t     *src
; 2. rsi        <- uint8_t     *dst
; 3. edx        <- int         width
; 4. ecx        <- int         height
; 5. r8d        <- int         src_row_size
; 6. r9d        <- int         dst_row_size
; 7. [rbp + 16] <- int         n
Manchas_asm: ; {{{

    push rbp
    mov rbp, rsp

    push r12                            ; [rbp - 8 ]
    push r13                            ; [rbp - 16]
    push r14                            ; [rbp - 24]
    push r15                            ; [rbp - 32]
    push rbp                            ; [rbp - 40]
    sub rsp, 8                          ; [rbp - 48] Balanceo stack

    mov r12, rdi                        ; (preservo) r12  = src
    mov r13, rsi                        ; (preservo) r13  = dst
    mov r14d, edx                       ; (preservo) r14d = width
    mov r15d, ecx                       ; (preservo) r15d = height

    ; Computo array sen(ii)[i]
    mov edi, r15d                       ; (1er param) EDI = height
    mov esi, [rbp + 16]                 ; (2do param) ESI = n
    call computar_sen_ii                ; rax = senjj[]
    mov [PTR_PF_SENII], rax                ; Preservo el array

    ; Computo array cos(jj)[j]
    mov edi, r14d                       ; (1er param) EDI = width
    mov esi, [rbp + 16]                 ; (2do param) ESI = n
    call computar_cos_jj                ; rax = cosjj[]
    mov [PTR_PF_COSJJ], rax                ; Preservo el array

    ; Hasta aca debugueado

    mov [DW_HEIGHT], r15d

    xor r15, r15

    ; while (i < height)
    jmp .vertloop_cmp

.vertloop:

.vertloop_body: ; {{{

    xor rbx, rbx                              ; j = 0
    jmp .horizloop_cmp                        ; while (j < width)

.horizloop:

.horizloop_body: ; {{{

    ; Computa el vector de tono
    mov rdi, r15                              ; (1er arg) = i
    mov rsi, rbx                              ; (2do arg) = j
    call tono
    ; xmm0 = [t1,t1,t1,t1,t0,t0,t0,t0]
    ; xmm1 = [t3,t3,t3,t3,t2,t2,t2,t2]

    ; lee 4px (16B) del src
    movdqu xmm2, [r12]                        ; [a3,r3,g3,b3,a2,r2,g2,b2,a1,r1,g1,b1,a0,r0,g0,b0]

    ; Unpack de los pixeles en 2 registros MMX packed word.
    pxor xmm4, xmm4                           ; [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    movdqa xmm3, xmm2                         ; [a3,r3,g3,b3,a2,r2,g2,b2,a1,r1,g1,b1,a0,r0,g0,b0]
    punpcklbw xmm2, xmm4                      ; Low:  [ 0,a1, 0,r1, 0,g1, 0,b1, 0,a0, 0,r0, 0,g0, 0,b0]
    punpckhbw xmm3, xmm4                      ; High: [ 0,a3, 0,r3, 0,g3, 0,b3, 0,a2, 0,r2, 0,g2, 0,b2]

    ; Hago la adicion de tono a los dos vectores.
    paddsw xmm2, xmm0                          ; [a1+t1,r1+t1,g1+t1,b1+t1,a0+t0,r0+t0,g0+t0,b0+t0]
    paddsw xmm3, xmm1                          ; [a3+t3,r3+t3,g3+t3,b3+t3,a2+t2,r2+t2,g2+t2,b2+t2]

    ; Puede ser negativo. Acoto por 0 para pasar a unsigned.
    movdqa xmm0, xmm2                         ; Copio px+tono (low) porque la prox instr sobreescribe
    pcmpgtw xmm0, xmm4                        ; [(a1+t1)>0,(r1+t1)>0,(g1+t1)>0,(b1+t1)>0,(a0+t0)>0,(r0+t0)>0,(g0+t0)>0,(b0+t0)>0]
    pand xmm2, xmm0                           ; Pongo en 0 todos los componentes <= 0
    movdqa xmm0, xmm3                         ; Copio px+tono (high) porque la prox instr sobreescribe
    pcmpgtw xmm0, xmm4                        ; [(a3+t3)>0,(r3+t3)>0,(g3+t3)>0,(b3+t3)>0,(a2+t2)>0,(r2+t2)>0,(g2+t2)>0,(b2+t2)>0]
    pand xmm3, xmm0                           ; Pongo en 0 todos los componentes <= 0

    ; pack a bytes
    packuswb xmm2, xmm3                       ; [a3+t3,r3+t3,g3+t3,b3+t3,a2+t2,r2+t2,g2+t2,b2+t2,a1+t1,r1+t1,g1+t1,b1+t1,a0+t0,r0+t0,g0+t0,b0+t0]

    ; Corrijo alpha
    por xmm2, [PB_ALPHA_MASK]                 ; [0xFF,r3+t3,g3+t3,b3+t3,0xFF,r2+t2,g2+t2,b2+t2,0xFF,r1+t1,g1+t1,b1+t1,0xFF,r0+t0,g0+t0,b0+t0]

    ; Escribe vec salida
    movdqu [r13], xmm2

    ; Avanzo punteros
    add r12, 16                               ; src += 16 Bytes
    add r13, 16                               ; dst += 16 Bytes

; .horizloop_body: ; }}}

    add ebx, 4                                ; Avanzo 4px (16 Bytes)

.horizloop_cmp:

    cmp ebx, r14d                             ; while (j < width)
    jl .horizloop

; .vertloop_body: ; }}}

    inc r15

.vertloop_cmp:                                ; while (0 < i)
    cmp r15d, [DW_HEIGHT]
    jne .vertloop

    add rsp, 8
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret ; /Manchas_asm }}}
