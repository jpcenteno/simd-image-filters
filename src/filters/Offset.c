#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Offset_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Offset_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Offset_fn_t) (uint8_t*, uint8_t*, int, int, int, int);


void leer_params_Offset(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_Offset(configuracion_t *config)
{
    Offset_fn_t *Offset = SWITCH_C_ASM( config, Offset_c, Offset_asm );
    buffer_info_t info = config->src;
    Offset(info.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size);
}

void liberar_Offset(configuracion_t *config) {

}

void ayuda_Offset()
{
    printf ( "       * Offset\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         Offset -i c facil.bmp\n" );
}

DEFINIR_FILTRO(Offset)


