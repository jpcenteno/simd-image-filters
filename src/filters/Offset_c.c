#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Offset_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;

    // Offset
    for (int i = 0; i < height-8; i++) {
        for (int j = 0; j < width-8; j++) {
            dst_matrix[i][j].b = src_matrix[i+8][j].b;
            dst_matrix[i][j].g = src_matrix[i][j+8].g;
            dst_matrix[i][j].r = src_matrix[i+8][j+8].r;
            dst_matrix[i][j].a = 255;
        }
    }
    utils_paintBorders32(dst, width, height, src_row_size, 8, 0xFF000000);
}
