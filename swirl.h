#ifndef _SWIRL_H
#define _SWIRL_H
#include <stdint.h>
#include "bmp.h"
void performSwirl(RGBTRIPLE *pPixelArray, int width, int height,
                  double swirlFactor);
#endif