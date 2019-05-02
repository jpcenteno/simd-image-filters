BITS 64

global Manchas_asm
extern malloc

section .rodata

    ALIGN 16

    SS_2PI: dd 6.28318

    ; Constantes para calcular `tono`
    PS_50: times 4 dd -50.0
    PS_25: times 4 dd 25.0

    ; FIXME por que necesito usar unaligned si puse align 16 mas arriba?
    PD_COMP_ALPHA: times 4 dd 0xFF000000

    PD_ZEROS:    times 4 dd 0x00
    PD_BYTE_MAX: times 4 dd 0xFF

    ; Para testear sat:
    ; Puedo pisar XMM0 antes de un llamado a SAT para testear la funcion que
    ; ande como espero.
    TEST_PD_SAT: dd 0xFFFFFFFF, 0x0FFFFFFF, 0xFF, 0x4F
    ; out esperado  [        0,         FF,   FF. 0x4F]

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

    ; Convierto el vector tono a integers usando truncamiento.
    cvttps2dq xmm0, xmm0                      ; Convierte a 4xInt32

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

    ; while (0 < i)
    jmp .vertloop_cmp

.vertloop:

    dec r15                                   ; r15 = height - 1

.vertloop_body: ; {{{

    xor rbx, rbx                              ; j = 0
    jmp .horizloop_cmp                        ; while (j < width)

.horizloop:

.horizloop_body: ; {{{

    ; Computa el vector de tono
    mov rdi, r15                              ; (1er arg) = i
    mov rsi, rbx                              ; (2do arg) = j
    call tono
    movdqa [PD_TONO], xmm0                    ; preserva el vec tono

    ; lee 4px (16B) del src
    movdqu xmm0, [r12]                        ; Lee 4px del src
    movdqa [PB_PIXELS], xmm0                  ; Preserva en mem estatica (para leer aligned la proxima)

    ; Extrae comp rojo
    pslld xmm0, 8                             ; [...  | R G B 0 | ... ]
    psrld xmm0, 24                            ; [ ... | 0 0 0 R | ... ]
    paddd xmm0, [PD_TONO]                     ; [ ... | R + tono | ... ] suma el tono
    call sat                                  ; [ ... | sat(R + tono) | ... ] Satura el resultado
    movdqa [PD_COMP_R], xmm0                  ; Preserva componente rojo

    ; Extrae componente verde
    movdqa xmm0, [PB_PIXELS]                  ; [...  | A R G B | ... ]
    pslld xmm0, 16                            ; [...  | G B 0 0 | ... ]
    psrld xmm0, 24                            ; [ ... | 0 0 0 G | ... ]
    paddd xmm0, [PD_TONO]                     ; [ ... | G + tono | ... ] suma el tono
    call sat                                  ; [ ... | sat(G + tono) | ... ] Satura el resultado
    movdqa [PD_COMP_G], xmm0                  ; preserva verde

    ; Extrae componente Azul
    movdqa xmm0, [PB_PIXELS]                  ; [...  | A R G B | ... ]
    pslld xmm0, 24                            ; [...  | B 0 0 0 | ... ]
    psrld xmm0, 24                            ; [ ... | 0 0 0 B | ... ]
    paddd xmm0, [PD_TONO]                     ; [ ... | G + tono | ... ] suma el tono
    call sat                                  ; [ ... | sat(G + tono) | ... ] Satura el resultado
    movdqa [PD_COMP_B], xmm0                  ; preserva azul

    ; combina
    movdqa xmm1, [PD_COMP_R]                  ; [ ... | 0 0 0 R | ... ]
    pslld xmm1, 24                            ; [ ... | R 0 0 0 | ... ]
    psrld xmm1, 8                             ; [ ... | 0 R 0 0 | ... ]
    por xmm0, xmm1                            ; [ ... | 0 R 0 B | ... ]

    movdqa xmm1, [PD_COMP_G]                  ; [ ... | 0 0 0 G | ... ] 
    pslld xmm1, 24                            ; [ ... | G 0 0 0 | ... ]
    psrld xmm1, 16                            ; [ ... | 0 0 G 0 | ... ]
    por xmm0, xmm1                            ; [ ... | 0 R G B | ... ]

    ; Escribe el componente alpha
    movdqu xmm1, [PD_COMP_ALPHA]              ; [ ... | FF 0 0 0 | ... ]
    por xmm0, xmm1                            ; [ ... | FF R G B | ... ]

    ; Escribe vec salida
    movdqu [r13], xmm0

    ; Avanzo punteros
    add r12, 16                               ; src += 16 Bytes
    add r13, 16                               ; dst += 16 Bytes

; .horizloop_body: ; }}}

    add ebx, 4                                ; Avanzo 4px (16 Bytes)

.horizloop_cmp:

    cmp ebx, r14d                             ; while (j < width)
    jl .horizloop

; .vertloop_body: ; }}}

.vertloop_cmp:                                ; while (0 < i)
    cmp r15, 0
    jnz .vertloop

    ; FIXME ahora tiene que liberar memoria de los 2 arrays cos(jj), sen(ii)

    add rsp, 8
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret ; /Manchas_asm }}}
