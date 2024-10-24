/*
 * Packer for the application to be launched by the bootloader
 * 
 * How to compile and run on macOS:
 * 
 * To compile:
 *   gcc packer.c -o packer
 * 
 * To run:
 *   ./packer <input file> <output file>
 * 
 * Example:
 *   ./packer application.bin packed_application.bin
 * 
 */

#include <stdio.h>
#include <stdlib.h>

// The key to be used for encryption and decryption
#define XOR_KEY 0x69

// The RLE compression function
void compress(unsigned char *data, unsigned int length, FILE *output) {
    for (unsigned int i = 0; i < length; ) {
        unsigned char byte = data[i];
        unsigned char repeats = 1;

        // Count the repetitions of the byte
        while ( (i + 1 < length) && (data[i + 1] == byte) && (repeats < 255) ) {
            repeats++;
            i++;
        }

        // Write the length and byte to the output file
        fputc(repeats, output);
        fputc(byte, output);

        i++;
    }
}

// The XOR encryption function
void encrypt(unsigned char *data, unsigned int length) {
    for (unsigned int i = 0; i < length; i++) {
        data[i] ^= XOR_KEY;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <input file> <output file>\n", argv[0]);
        return 1;
    }

    // Open input (original binary) and output (packed binary) files
    FILE *input = fopen(argv[1], "rb");
    FILE *output = fopen(argv[2], "wb");

    if (input == NULL) {
        perror("Error opening input file");
        return 1;
    }

    if (output == NULL) {
        perror("Error opening output file");
        fclose(input);
        return 1;
    }

    // Read the input file into memory
    fseek(input, 0, SEEK_END);
    unsigned int filesize = ftell(input);
    fseek(input, 0, SEEK_SET);

    if (filesize == 0) {
        printf("Input file is empty.\n");
        fclose(input);
        fclose(output);
        return 1;
    }

    unsigned char *data = (unsigned char *) malloc(filesize);
    
    if (data == NULL) {
        perror("Memory allocation failed");
        fclose(input);
        fclose(output);
        return 1;
    }

    if (fread(data, 1, filesize, input) != filesize) {
        perror("Error reading input file");
        fclose(output);
        free(data);
        return 1;
    }

    fclose(input);

    // Step 1: XOR encryption
    encrypt(data, filesize);

    // Step 2: RLE compression
    compress(data, filesize, output);

    fclose(output);
    free(data);

    printf("Packing complete. Packed file is '%s'.\n", argv[2]);
    return 0;
}