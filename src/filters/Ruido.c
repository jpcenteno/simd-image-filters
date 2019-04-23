#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Ruido_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Ruido_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Ruido_fn_t) (uint8_t*, uint8_t*, int, int, int, int);


void leer_params_Ruido(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_Ruido(configuracion_t *config)
{
    Ruido_fn_t *Ruido = SWITCH_C_ASM( config, Ruido_c, Ruido_asm );
    buffer_info_t info = config->src;
    Ruido(info.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size);
}

void liberar_Ruido(configuracion_t *config) {

}

void ayuda_Ruido()
{
    printf ( "       * Ruido\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         Ruido -i c facil.bmp\n" );
}

DEFINIR_FILTRO(Ruido)


