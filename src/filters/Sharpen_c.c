#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Sharpen_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;
    
    // Sharpen
    float sharpen[3][3] = { {  -1, -1,  -1 }, { -1,  9, -1 }, {  -1, -1,  -1 } };

    for (int i = 0; i < height-2; i++) {
        for (int j = 0; j < width-2; j++) {

            float totalB = 0;
            float totalG = 0;
            float totalR = 0;

            for (int ii = 0; ii <= 2; ii++) {
                for (int jj = 0; jj <= 2; jj++) {
                    totalB = totalB + (float)sharpen[ii][jj] * (float)src_matrix[i+ii][j+jj].b;
                    totalG = totalG + (float)sharpen[ii][jj] * (float)src_matrix[i+ii][j+jj].g;
                    totalR = totalR + (float)sharpen[ii][jj] * (float)src_matrix[i+ii][j+jj].r;
                }
            }
            dst_matrix[i+1][j+1].b = SAT(totalB);
            dst_matrix[i+1][j+1].g = SAT(totalG);
            dst_matrix[i+1][j+1].r = SAT(totalR);
            dst_matrix[i+1][j+1].a = 255;
   
        }
    }
    
    utils_paintBorders32(dst, width, height, src_row_size, 1, 0xFF000000);
}
