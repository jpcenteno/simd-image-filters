BITS 64

global Manchas_asm
extern malloc

section .rodata

SS_2PI: dd 6.28318

section .text



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

    push r12                            ; [rbp + 8 ]
    push r13                            ; [rbp + 16]
    push r14                            ; [rbp + 24]
    push r15                            ; [rbp + 32]

    mov r12, rdi                        ; (preservo) r12  = src
    mov r13, rsi                        ; (preservo) r13  = dst
    mov r14d, edx                       ; (preservo) r14d = width
    mov r15d, ecx                       ; (preservo) r15d = height

    ; Computo array sen(ii)[i]
    mov edi, r15d                       ; (1er param) EDI = height
    mov esi, [rbp + 16]                 ; (2do param) ESI = n
    call computar_sen_ii                ; rax = senjj[]
    push rax                            ; [rbp + 40] preservo senjj[]
    sub rsp, 8                          ; [rbp + 48] (alineo stack)

    ; Computo array cos(jj)[j]
    mov edi, r14d                       ; (1er param) EDI = width
    mov esi, [rbp + 16]                 ; (2do param) ESI = n
    call computar_cos_jj                ; rax = cosjj[]
    mov [rsp], rax                      ; [rbp + 48] preservo cosjj[]

    ; Hasta aca debugueado

    ; while (0 < i)
    jmp .vertloop_cmp

.vertloop:

    dec ecx                                   ; ecx = i--

    xor r8d, r8d                              ; j = 0
    jmp .horizloop_cmp                        ; while (j < width)

.horizloop:

    ; FIXME computa x (tono)

    ; lee 4px (16B) de ram
    ; separa 3 componentes
    ; Procesa
    ; Escribe vec salida

    add r8d, 16                               ; Avanzo 4px (16 Bytes)

.horizloop_cmp:
    cmp r8d, edx                              ; while (j < width)
    jl .horizloop

.vertloop_cmp:                                ; while (0 < i)
    cmp ecx, 0
    jnz .vertloop

    ; FIXME ahora tiene que liberar memoria de los 2 arrays cos(jj), sen(ii)

    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret ; /Manchas_asm }}}
