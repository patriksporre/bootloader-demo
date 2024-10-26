/*
 * packer.c
 * 
 * Description:
 * This program performs RLE (Run-Length Encoding) compression with XOR encryption 
 * to prepare an application binary file for use by a bootloader. The packed file 
 * contains compressed and encrypted data, making it ready for loading by the bootloader.
 * 
 * Author: Patrik Sporre
 * License: MIT License
 * 
 * MIT License
 * 
 * Copyright (c) 2024 Patrik Sporre
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * 
 * Building and Running:
 * 
 * 1. Build the packer:
 *      gcc packer.c -o packer
 * 
 * 2. Run the packer with the input and output files specified:
 *      ./packer <input file> <output file>
 * 
 *    Example:
 *      ./packer application.bin application-packed.bin
 * 
 * This will produce the following output:
 * 
 * - Original size of the input file
 * - Compressed size after RLE compression
 * - Compression ratio as a percentage
 * - Total sectors (512 bytes each) required after padding
 * 
 * Output file (`application-packed.bin` in this example) is created with RLE-compressed 
 * and XOR-encrypted data, padded to the nearest 512-byte sector boundary.
 */

#include <stdio.h>
#include <stdlib.h>

// XOR encryption key
#define XOR_KEY 0x69

// Sector size
#define SECTOR_SIZE 512

/**
 * XOR encrypts the input data in place.
 *
 * @param data   Pointer to the data buffer to encrypt.
 * @param length Length of the data in bytes.
 */
void encrypt(unsigned char *data, unsigned int length) {
    for (unsigned int i = 0; i < length; i++) {
        data[i] ^= XOR_KEY;
    }
}

/**
 * Compresses the input data using Run-Length Encoding (RLE).
 *
 * Each run of identical bytes is stored as a length byte followed by the byte value,
 * allowing repeated values to be compressed effectively.
 *
 * @param data    Pointer to the data buffer to compress.
 * @param length  Length of the data in bytes.
 * @param output  Pointer to the output file where compressed data is written.
 */
void compress(unsigned char *data, unsigned int length, FILE *output) {
    for (unsigned int i = 0; i < length;) {
        unsigned char byte = data[i];
        unsigned char repeats = 1;

        while ((i + repeats < length) && (data[i + repeats] == byte) && (repeats < 255)) {
            repeats++;
        }

        fputc(repeats, output);              // Write repetition count
        fputc(byte, output);                 // Write the byte value
        i += repeats;
    }
}

/**
 * Pads the output file to ensure its size is a multiple of 512 bytes (SECTOR_SIZE).
 *
 * @param output    Pointer to the output file to pad.
 * @param file_size Current size of the file in bytes.
 * @return          The total size of the file in sectors after padding.
 */
unsigned int pad_to_sector(FILE *output, unsigned int file_size) {
    unsigned int padding_needed = SECTOR_SIZE - (file_size % SECTOR_SIZE);
    if (padding_needed != SECTOR_SIZE) {
        for (unsigned int i = 0; i < padding_needed; i++) {
            fputc(0, output);               // Pad with zeros
        }
        file_size += padding_needed;
    }
    return file_size / SECTOR_SIZE;
}

/**
 * Main function that encrypts, compresses, and writes an input file to the output file.
 *
 * Usage:
 *   ./packer <input file> <output file>
 * 
 * Example:
 *   ./packer application.bin application-packed.bin
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return     0 on success, 1 on failure.
 */
int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input file> <output file>\n", argv[0]);
        return 1;
    }

    // Open input and output files
    FILE *input = fopen(argv[1], "rb");
    FILE *output = fopen(argv[2], "wb");
    if (!input) {
        perror("Error opening input file");
        return 1;
    }
    if (!output) {
        perror("Error opening output file");
        fclose(input);
        return 1;
    }

    // Read input file into memory
    fseek(input, 0, SEEK_END);
    unsigned int original_size = ftell(input); // Store the original file size
    fseek(input, 0, SEEK_SET);

    if (original_size == 0) {
        fprintf(stderr, "Error: Input file is empty.\n");
        fclose(input);
        fclose(output);
        return 1;
    }

    unsigned char *data = malloc(original_size);
    if (!data) {
        perror("Memory allocation failed");
        fclose(input);
        fclose(output);
        return 1;
    }
    if (fread(data, 1, original_size, input) != original_size) {
        perror("Error reading input file");
        fclose(output);
        free(data);
        return 1;
    }
    fclose(input);

    // Encrypt and compress data
    encrypt(data, original_size);
    compress(data, original_size, output);

    // Calculate output file size and pad to the next sector if necessary
    fflush(output);
    fseek(output, 0, SEEK_END);
    
    unsigned int compressed_size = ftell(output);
    unsigned int sectors = pad_to_sector(output, compressed_size);

    // Print summary of results
    printf("Packing complete:\n");
    printf("  Original size: %u bytes\n", original_size);
    printf("  Compressed size: %u bytes\n", compressed_size);
    printf("  Compression ratio: %.2f%%\n", (100.0 * compressed_size) / original_size);
    printf("  Total sectors (512 bytes each): %u\n", sectors);

    fclose(output);
    free(data);

    return 0;
}