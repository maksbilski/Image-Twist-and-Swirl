# Swirl Image Processing in Assembly and C

This repository contains code for applying a swirl effect to BMP images. The swirling effect is implemented using x86_64 assembly for performance considerations. The project is primarily aimed at demonstrating the interoperation of C with assembly language and the implementation of image processing algorithms in assembly.

## Overview

This project uses the x86_64 assembly language to apply a swirling effect to an image in BMP format. It reads an image, processes it using an assembly language function, and then writes the output to a new image file. The project is educational and aims to teach assembly language programming for image processing.

## Files in the Repository

- `swirl.s`: Contains the assembly code for the swirl image processing operation.
- `main.c`: Contains the C code which is responsible for loading and saving a BMP image, and calling the assembly function to perform the swirl operation.
- `bmp.h`: Contains the C header file with necessary structures and function prototypes for handling BMP images.
- `Makefile`: Contains rules to build the project easily.
- `README.md`: This file.

### swirl.s

This file contains x86_64 assembly code for the swirling effect. It provides a function named `performSwirl`, which takes parameters necessary to create a swirling effect on a given image. The function can be called from C programs.

### main.c

This C file is the driver code that utilizes the `performSwirl` function defined in `swirl.s`. It reads an input BMP file, calls `performSwirl` to process the image, and then writes the result to an output file.

### bmp.h

This header file defines structures and function prototypes for handling BMP images. The structures represent the BMP file header and the info header, while the function prototypes are for reading and writing BMP files.

### Makefile

This file contains rules for easily building the project. It uses the GCC compiler, and it is configured to link against the Allegro 5 library.

## Installing Dependencies

This project requires the Allegro 5 library. Below are instructions for installing it on different operating systems.

### Ubuntu

To install Allegro 5 on Ubuntu, use the following command:

```sh
sudo apt-get install liballegro5-dev liballegro-image5-dev liballegro-font5-dev liballegro-ttf5-dev


## Compilation and Execution

You can build and compile the project using the provided Makefile. 

Example:

```sh
make all
```

This will produce an executable named swirl.

./swirl input.bmp output.bmp swirl_factor
