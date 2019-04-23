#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Sharpen_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Sharpen_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Sharpen_fn_t) (uint8_t*, uint8_t*, int, int, int, int);


void leer_params_Sharpen(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_Sharpen(configuracion_t *config)
{
    Sharpen_fn_t *Sharpen = SWITCH_C_ASM( config, Sharpen_c, Sharpen_asm );
    buffer_info_t info = config->src;
    Sharpen(info.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size);
}

void liberar_Sharpen(configuracion_t *config) {

}

void ayuda_Sharpen()
{
    printf ( "       * Sharpen\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         Sharpen -i c facil.bmp\n" );
}

DEFINIR_FILTRO(Sharpen)


