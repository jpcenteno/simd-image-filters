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
    call malloc                           ; rax = malloc(height * 4) FIXME supongo que esto esta bien
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
        mov rax, SS_2PI                 ; FIXME borrame
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

    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi                        ; (preservo) r12  = src
    mov r13, rsi                        ; (preservo) r13  = dst
    mov r14d, edx                       ; (preservo) r14d = width
    mov r15d, ecx                       ; (preservo) r15d = height

    ; Computo array sen(ii)[i]
    mov edi, r15d                       ; (1er param) EDI = height
    mov esi, [rbp + 16]                 ; (2do param) ESI = n
    call computar_sen_ii                ; rax = sen(ii)[i]
    mov rbx, rax                        ; preservo array

    ; Hasta aca debuguea

    ; while (0 < i)
    jmp .vertloop_cmp
    .vertloop:

      dec ecx                                   ; ecx = i--

      ; FIXME Computa ii {{{

      ; Hace vector [i, i, i, i]
      pinsrd xmm0, ecx, 0                       ; xmm0 = [ , , ,i] (pd)
      pinsrd xmm0, ecx, 1                       ; xmm0 = [ , ,i,i] (pd)
      pinsrd xmm0, ecx, 2                       ; xmm0 = [ ,i,i,i] (pd)
      pinsrd xmm0, ecx, 3                       ; xmm0 = [i,i,i,i] (pd)

      ; Como saco el modulo en SIMD?



      ; /computa 'ii' }}}

      xor r8d, r8d                              ; j = 0
      jmp .horizloop_cmp                        ; while (j < width)
      .horizloop:

      ; FIXME Computa ii
      ; fixme computa x (tono)

      ; lee 4px (16B) de ram
      ; separa 3 componentes
      ; Procesa
      ; Escribe vec salida

      .horizloop_cmp:
      cmp r8d, edx                              ; while (j < width)
      jl .horizloop

    .vertloop_cmp:                              ; while (0 < i)
    cmp ecx, 0
    jnz .vertloop

    push rbx
    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret ; /Manchas_asm }}}
