#define _USE_MATH_DEFINES
#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <allegro5/allegro_image.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_font.h>
#include <allegro5/allegro_ttf.h>
#include "swirl.h"

#define INPUT_BUFFER_SIZE 256

void displayResult(ALLEGRO_DISPLAY* display, RGBTRIPLE* pixelArray, int width, int height) {

    ALLEGRO_BITMAP* bitmap = al_create_bitmap(width, height);
    if(!bitmap) {
        fprintf(stderr, "failed to create bitmap!\n");
        return;
    }

    al_set_target_bitmap(bitmap);

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            RGBTRIPLE pixel = pixelArray[i * width + j];
            al_put_pixel(j, i, al_map_rgb(pixel.rgbtRed, pixel.rgbtGreen, pixel.rgbtBlue));
        }
    }

    al_set_target_bitmap(al_get_backbuffer(display));
    al_draw_bitmap(bitmap, 0, 0, 0);
    al_flip_display();

    //Clean up
    al_destroy_bitmap(bitmap);
}



void initDefaultSwirlFactor(double* swirlFactor)
{
    *swirlFactor = -0.005;
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        printf("Usage: %s <imagePath>\n", argv[0]);
        return 1;
    }

    char* inputFile = argv[1];

    FILE *inptr = fopen(inputFile, "r");
    if (inptr == NULL)
    {
        printf("Could not open %s.\n", inputFile);
        return 2;
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
    int offset = bitmapFileheader.bfOffBits;

    RGBTRIPLE* pixelArray = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE));

    fseek(inptr, 0, SEEK_SET);
    fseek(inptr, offset, SEEK_CUR);

    // Determine padding for scanlines
    int padding = (4 - (width * sizeof(RGBTRIPLE)) % 4) % 4;

    // Iterate over infile's scanlines in reverse order
    for (int i = 0; i < height; i++)
    {
        // Calculate the offset in the pixel array for the current row
        RGBTRIPLE* row = pixelArray + i * width;

        // Read row into pixel array
        fread(row, sizeof(RGBTRIPLE), width, inptr);

        // Skip over padding
        fseek(inptr, padding, SEEK_CUR);
    }

    RGBTRIPLE* pixelArrayCopy = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE));

    if(pixelArrayCopy == NULL) {
        // Handle the error.
        fprintf(stderr, "Memory allocation for pixelArrayCopy failed\n");
        exit(1);
    }

    double swirlFactor;
    initDefaultSwirlFactor(&swirlFactor);

    al_init();
    al_init_image_addon();
    al_install_mouse();
    al_install_keyboard();
    al_init_font_addon();

    ALLEGRO_DISPLAY *display = al_create_display(800, 600); // Create display with desired dimensions
    if(!display) {
        fprintf(stderr, "failed to create display!\n");
        return -1;
    }

    ALLEGRO_FONT* font = al_create_builtin_font();
    ALLEGRO_BITMAP *membitmap;
    ALLEGRO_TIMER *timer;
    ALLEGRO_EVENT_QUEUE *queue;

    bool redraw = true;
    timer = al_create_timer(1.0 / 30);
    queue = al_create_event_queue();
    al_register_event_source(queue, al_get_keyboard_event_source());
    al_register_event_source(queue, al_get_display_event_source(display));
    al_register_event_source(queue, al_get_timer_event_source(timer));
    al_register_event_source(queue , al_get_mouse_event_source());
    al_start_timer(timer);
    al_register_event_source(queue, al_get_display_event_source(display)); // Now display is initialized


    while (1) {
        ALLEGRO_EVENT event;
        al_wait_for_event(queue, &event);
        if (event.type == ALLEGRO_EVENT_DISPLAY_CLOSE)
            break;
        if(event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN)
        {
            performSwirl(pixelArray, pixelArrayCopy, width, height, swirlFactor);
        }
        if (event.type == ALLEGRO_EVENT_KEY_CHAR)
        {
            if (event.keyboard.keycode == ALLEGRO_KEY_ESCAPE)
                break;
            if (event.keyboard.unichar == 'w')
                swirlFactor += 0.005;
            if (event.keyboard.unichar == 's')
                swirlFactor -= 0.005;
        }
        if (event.type == ALLEGRO_EVENT_TIMER)
            redraw = true;
        if (redraw && al_is_event_queue_empty(queue))
        {
            redraw = false;
            al_clear_to_color(al_map_rgb_f(0, 0, 0));
            displayResult(display, pixelArrayCopy, width, height); // Pass display to the function
            char formattedString[100];
            al_draw_text(font, al_map_rgb(255, 255, 255), 0, 5, 0, "Change swirlFactor with <w, s>");
            sprintf(formattedString, "Swirl Factor: %.3f" , swirlFactor); // Corrected format string
            al_draw_text(font, al_map_rgb(255, 255, 255), 0, 35, 0, formattedString);
            al_flip_display();
        }
    }

    free(bitmapInfoheader);
    free(pixelArray);
    free(pixelArrayCopy);
    al_destroy_display(display);
    al_destroy_font(font);
    al_destroy_event_queue(queue);
    al_destroy_timer(timer);

    return 0;
}
