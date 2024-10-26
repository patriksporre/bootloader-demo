#!/bin/bash

# build.sh
#
# This script assembles the bootloader and application, creates a floppy disk image,
# writes the bootloader and application to the image, and optionally runs the image in QEMU.
# The script can also include an optional packing step once the bootloader supports decompression and decryption.
#
# Usage:
#   ./build.sh
#
# Note: Make sure the script is executable before running it:
#   chmod +x makefloppy.sh
#
# Requirements:
#   Ensure that NASM, QEMU, and (if using packing) the packer and makefloppy scripts are available.
#
# Steps:
#   1. Removes any old build files
#   2. Assembles the bootloader and application with NASM
#   3. Optionally packs the application binary (currently commented out)
#   4. Creates a floppy image and adds the bootloader and application
#   5. Runs the floppy disk image in QEMU for testing

# File paths
BOOTLOADER="boot.bin"
APPLICATION="application.bin"
PACKED_APPLICATION="application-packed.bin"
FLOPPY_IMAGE="floppy.img"

# Clean up previous builds
echo "Removing old build files..."
rm -f "$FLOPPY_IMAGE" "$BOOTLOADER" "$APPLICATION" "$PACKED_APPLICATION"

# Compile the packer
echo "Compiling the packer..."
gcc packer.c -o packer

# Assemble bootloader and application
echo "Assembling bootloader and application..."
nasm -f bin -DDEBUG boot.asm -o "$BOOTLOADER" || { echo "Bootloader assembly failed"; exit 1; }
nasm -f bin -DDEBUG application.asm -o "$APPLICATION" || { echo "Application assembly failed"; exit 1; }

echo "Packing application..."
./packer "$APPLICATION" "$PACKED_APPLICATION" || { echo "Packer failed"; exit 1; }
FINAL_APP="$PACKED_APPLICATION"

# Create floppy image and write bootloader and application
echo "Creating floppy disk image with bootloader and application..."
./makefloppy.sh "$BOOTLOADER" "$FINAL_APP" "$FLOPPY_IMAGE" || { echo "Error creating floppy image"; exit 1; }

# Clean up temporary build files
echo "Cleaning up temporary files..."
rm -f "$APPLICATION" "$PACKED_APPLICATION" application-padded.bin "$BOOTLOADER"

# Run the floppy disk image in QEMU
echo "Running the floppy image in QEMU..."
qemu-system-x86_64 -drive file="$FLOPPY_IMAGE",format=raw,if=floppy,index=0 -boot a