#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Manchas_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size, int n);

void Manchas_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size, int n);

typedef void (Manchas_fn_t) (uint8_t*, uint8_t*, int, int, int, int, int);

typedef struct Manchas_params_t {
    int n;
} Manchas_params_t;

Manchas_params_t extra;
void leer_params_Manchas(configuracion_t *config, int argc, char *argv[]) {
    config->extra_config = &extra;
    extra.n = atoi(argv[argc - 1]);
}

void aplicar_Manchas(configuracion_t *config)
{
    Manchas_fn_t *Manchas = SWITCH_C_ASM( config, Manchas_c, Manchas_asm );
    buffer_info_t info = config->src;
    Manchas(info.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size, extra.n);
}

void liberar_Manchas(configuracion_t *config) {

}

void ayuda_Manchas()
{
    printf ( "       * Manchas\n" );
    printf ( "           Parámetros     : \n"
             "                         n = tamaño de la mancha\n");
    printf ( "           Ejemplo de uso : \n"
             "                         Manchas -i c facil.bmp 10\n" );
}

DEFINIR_FILTRO(Manchas)


