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

### Installing Dependencies

This project requires the Allegro 5 library. Below are instructions for installing it on different operating systems.

To install Allegro 5 on Linux (in this case Ubuntu), use the following command:

```sh
sudo apt-get install liballegro5-dev liballegro-image5-dev liballegro-font5-dev liballegro-ttf5-dev
```

## Compilation and Execution

You can build and compile the project using the provided Makefile. 

Example:

```sh
make all
```

This will produce an executable named swirl.

```sh
./swirl input.bmp swirl_factor
```

## Interactive Usage of the Application

Once you have successfully compiled and executed the application by providing an input image, you'll enter into an interactive mode where you can observe the swirl effect applied to the image in real-time.

Here’s how you can interact with the application:

Note: Ensure that the input image is in BMP format.

1. Run the application with the input image:

2. After executing the above command, a window displaying the input image will open. 

3. To interactively change the swirl factor, use the following keys:
- Press the `Arrow Up` key to increase the swirl factor.
- Press the `Arrow Down` key to decrease the swirl factor.

The changes in the swirl factor will be immediately visible on the image.

4. As you change the swirl factor, you will see the current value displayed in the window. This allows you to understand the intensity of the effect applied to the image.

5. When you are satisfied with the result, or if you wish to exit the application, press the `Escape` key.

6. You can also close the application by clicking on the close button of the window.

This interactive mode allows you to visualize how varying levels of the swirl effect can alter the image. It’s a useful way to understand the impact of the swirl factor on the processing of the image.


## Effect 

### Original Image
![Original Jelly Image](images/jelly_original.bmp)

### After performing Swirl on it
![SWirled Jelly Image](images/jelly_original_after_swirl.png)
