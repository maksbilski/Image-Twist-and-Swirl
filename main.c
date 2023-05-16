#define _USE_MATH_DEFINES
#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include "swirl.h"
#include "bmp.h"


int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <imagePath> <swirlFactor>\n", argv[0]);
        return 1;
    }

    char* inputFile = argv[1];
    double swirlFactor = atof(argv[2]);

    // Open input file
    FILE *inptr = fopen(inputFile, "r");
    if (inptr == NULL)
    {
        printf("Could not open %s.\n", inputFile);
        return 4;
    }

    // Read infile's BITMAPFILEHEADER
    BITMAPFILEHEADER bitmapFileheader;
    fread(&bitmapFileheader, sizeof(BITMAPFILEHEADER), 1, inptr);

    // Read infile's BITMAPINFOHEADER
    BITMAPINFOHEADER bitmapInfoheader;
    fread(&bitmapInfoheader, sizeof(BITMAPINFOHEADER), 1, inptr);


    // Get image's dimensions
    int height = abs(bitmapInfoheader.biHeight);
    int width = bitmapInfoheader.biWidth;

    void* pixelArray = malloc(height*width*3);

    // Iterate over infile's scanlines
    for (int i = 0; i < height; i++)
    {
        // Read row into pixel array
        fread(pixelArray[i], sizeof(RGBTRIPLE), width, inptr);

        // Skip over padding
        fseek(inptr, padding, SEEK_CUR);
    }

    return 0;
}
