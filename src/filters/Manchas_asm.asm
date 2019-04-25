BITS 64

global Manchas_asm
extern malloc

section .rodata

ALIGN 16
PS_2PI: TIMES 4 dd 6.28318               ; [2*PI, 2*PI, 2*PI, 2*PI] :: ps

section .text



; float* gen_senii(uint32_t height, uint32_t n);
;
; Devuelve un array de floats (ss) con el valor de sen(ii) definido como
; sen( (2PI * float(i % n)) / n ). La longitud del array es `height`.
gen_senii: ; {{{

    ; INPUT:
    ; EDI = height
    ; ESI = n

    push rbp
    mov rbp, rsp

    push r12
    push r13

    ; Preserva parametros {{{
    mov r12d, edi                         ; Preserva 'height'
    mov r13d, esi                         ; Preserva 'n'
    ; }}}

    ; Pide memoria para el array {{{
    shl rsi, 2                            ; rsi = height * 4, tamano array floats
    call malloc                           ; rax = malloc(height * 4)
    mov r8, rax                           ; preserva el arreglo. (rax se pisa en el loop)
    ; }}}

    ; Loop donde escribe el array con los datos corresp. {{{

    ; Inicializa {{{
    mov rdi, rax                          ; puntero "mutable" para escribir el array
    xor rcx, rcx                          ; i = 0
    ; }}}

    ; Salta a la guarda
    jmp .cond

    .loop: ; Escribe a[i] {{{

        ; Calcula senii_i para este valor de i.
        xor edx, edx                    ; Anula parte alta dividendo
        mov eax, ecx                    ; dividendo = i
        div r13                         ; edx = i % n

        ; Convierto a float. Ahora trabajo en FPU
        mov [rsp - 4], edx              ; hack para cargar `edx` en FPU
        fild [rsp -4]                   ; push (i%n) al stack FPU



    ; /.loop }}}

    ; Incrementa i
    inc rcx

    .cond: ; Guarda del loop {{{
    cmp rcx, r12                          ; i < height
    jl .loop                              ; si es menor, loopea
    ; /.cond }}}

    ; }}}

    mov rax, r8                         ; devuelve el arreglo

    ; Se espera a la salida del loop que:
    ; - valor de retorno RAX es puntero al inicio del array.
    ; - El array en RAX tiene los valores sen(ii) que debian computarse

    pop r13
    pop r12

    pop rbp
    ret ; /gen_senii }}}


; 1. rdi       <- uint8_t     *src
; 2. rsi       <- uint8_t     *dst
; 3. edx       <- int         width
; 4. ecx       <- int         height
; 5. r8d       <- int         src_row_size
; 6. r9d       <- int         dst_row_size
; 7. [rbp + 8] <- int         n
Manchas_asm: ; {{{

push rbp
mov rbp, rsp


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


pop rbp
ret ; /Manchas_asm }}}
