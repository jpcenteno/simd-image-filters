#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Manchas_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size,
    int n)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;

    // Manchas
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            
            float ii = ((float)(i%n)/n)*2*3.14159;
            float jj = ((float)(j%n)/n)*2*3.14159;
            int x = 50*sin(ii)*cos(jj)-25;
            
            dst_matrix[i][j].b = SAT(src_matrix[i][j].b + x);
            dst_matrix[i][j].g = SAT(src_matrix[i][j].g + x);
            dst_matrix[i][j].r = SAT(src_matrix[i][j].r + x);
            dst_matrix[i][j].a = 255;
        }
    }

}
