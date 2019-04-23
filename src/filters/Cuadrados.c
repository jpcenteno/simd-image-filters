#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Cuadrados_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Cuadrados_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Cuadrados_fn_t) (uint8_t*, uint8_t*, int, int, int, int);


void leer_params_Cuadrados(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_Cuadrados(configuracion_t *config)
{
    Cuadrados_fn_t *Cuadrados = SWITCH_C_ASM( config, Cuadrados_c, Cuadrados_asm );
    buffer_info_t info = config->src;
    Cuadrados(info.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size);
}

void liberar_Cuadrados(configuracion_t *config) {

}

void ayuda_Cuadrados()
{
    printf ( "       * Cuadrados\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         Cuadrados -i c facil.bmp\n" );
}

DEFINIR_FILTRO(Cuadrados)


