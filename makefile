CC=gcc
CFLAGS= -Wall -g -lm $(shell pkg-config --cflags allegro-5 allegro_image-5 allegro_font-5 allegro_ttf-5)
LDFLAGS=$(shell pkg-config --libs allegro-5 allegro_image-5 allegro_font-5 allegro_ttf-5)
all: main.o swirl.o
	$(CC) $(CFLAGS) main.o swirl.o $(LDFLAGS) -o swirl
main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o
swirl.o: swirl.s
	nasm -f elf64 swirl.s -o swirl.o
clean:
	rm -rf swirl.o swirl main.o
