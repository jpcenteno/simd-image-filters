#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Cuadrados_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{    
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;
    
    // Cuadrados
    for (int i = 4; i < height-4; i++) {
        for (int j = 4; j < width-4; j++) {
            int maxB = 0;
            int maxG = 0;
            int maxR = 0;
            for (int ii = 0; ii <= 3; ii++) {
                for (int jj = 0; jj <= 3; jj++) {
                    if(maxB<src_matrix[i+ii][j+jj].b) maxB = src_matrix[i+ii][j+jj].b;
                    if(maxG<src_matrix[i+ii][j+jj].g) maxG = src_matrix[i+ii][j+jj].g;
                    if(maxR<src_matrix[i+ii][j+jj].r) maxR = src_matrix[i+ii][j+jj].r;
                }
            }
            dst_matrix[i][j].b = maxB;
            dst_matrix[i][j].g = maxG;
            dst_matrix[i][j].r = maxR;
            dst_matrix[i][j].a = 255;
        }
    }
    
    utils_paintBorders32(dst, width, height, src_row_size, 4, 0xFF000000);
}
