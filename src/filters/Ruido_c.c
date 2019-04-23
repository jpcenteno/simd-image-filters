#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Ruido_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;

    // Ruido
    srand(123);
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int a = (rand() % 255) - 127;
            dst_matrix[i][j].b = SAT(src_matrix[i][j].b + a);
            dst_matrix[i][j].g = SAT(src_matrix[i][j].g + a);
            dst_matrix[i][j].r = SAT(src_matrix[i][j].r + a);
            dst_matrix[i][j].a = 255;
        }
    }

}
