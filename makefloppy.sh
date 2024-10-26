#!/bin/bash

# makefloppy.sh
# 
# This script creates a 1.44 MB floppy disk image by combining a bootloader and a packed application.
# 
# Usage:
#   ./makefloppy.sh <bootloader> <packed application> <output image>
#
# Example:
#   ./makefloppy.sh boot.bin application-packed.bin floppy.img
#
# Note: Make sure the script is executable before running it:
#   chmod +x makefloppy.sh
#
# The script performs the following steps:
#   1. Creates a blank 1.44 MB floppy disk image (2880 sectors)
#   2. Writes the bootloader to the first sector (sector 0) of the disk image
#   3. Writes the packed application to the second sector (sector 1) <-- IMPORTANT!
#   4. Outputs a floppy disk image that can be used with QEMU or other emulators

# Check if we have the correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <bootloader> <packed application> <output image>"
    exit 1
fi

# Assign arguments to variables
BOOTLOADER=$1
APPLICATION=$2
OUTPUT=$3

# Create a blank 1.44 MB floppy disk image (2880 sectors)
dd if=/dev/zero of="$OUTPUT" bs=512 count=2880

# Write the bootloader to the first sector (sector 0) of the floppy image
dd if="$BOOTLOADER" of="$OUTPUT" conv=notrunc

# Write the packed application to the second sector (sector 1) of the floppy image
dd if="$APPLICATION" of="$OUTPUT" bs=512 seek=1 conv=notrunc

# Print a success message
echo "Floppy disk image created: $OUTPUT"