
# Minimalist bootloader with application loader

This project contains a simple bootloader written in NASM assembly, designed to load a secondary application from a 
specific sector on a floppy disk, decompress it with RLE (Run-Length Encoding) and XOR decryption, and jump to execute 
it in memory.

The bootloader is intended as an educational example, showcasing several foundational techniques for 
bootloader development in a 16 bit real-mode environment.

This project is designed to provide an easy-to-follow example for beginners interested in low-level programming 
and bootloader development. Have fun exploring and experimenting with the code!

## Author

**Patrik Sporre**  
Email: [patriksporre@gmail.com](mailto:patriksporre@gmail.com)

## Features

- **Simple sector-based loading**: Loads a compressed and encrypted application from the floppy disk's second sector
- **RLE compression and XOR Encryption**: Compresses and encrypts the application binary for minimized disk usage
- **Basic debug output**: Displays characters 'L', 'U', 'J', and 'E' for debugging stages: "Load", "Unpack", "Jump", and "Error"
- **Far jump execution**: Loads and jumps to the application at a specific memory address, setting `CS` and `IP`

## Key learnings and common pitfalls

1. **Sector addressing**: BIOS uses 1-based indexing for sectors (`CL=0x02` for sector 2), but 0-based for cylinders 
   and heads
2. **Data placement**: Writing to sector 2 (offset 0x200) requires setting `seek=1` with the `dd` command
3. **Segment register setup**: Ensure `DS`, `ES`, and `SS` are set to `0x0000`, and `SP` to `0x7c00`
4. **Drive number handling**: Save the boot drive number (from `DL`) provided by BIOS for accurate disk access
5. **Memory jumping**: Use far jumps (`jmp 0x0000:0x9000`) to set `CS` and `IP` correctly when jumping to the application
6. **Debug output**: Print characters to track the bootloader's progress through key stages (if built using `build-debug.sh`)

## Usage

### Build and assemble

1. **Setup**: Ensure `nasm`, `qemu`, and `gcc` are installed for building and testing. Make sure `build-release.sh`, `build-debug.sh`, `and makefloppy.sh` are executable.

   ```bash
   chmod +x build-release.sh
   chmod +x build-debug.sh
   chmod +x makefloppy.sh
   ```

2. **Build**: Run the `build-release.sh` script, which assembles the bootloader and application, compresses the 
   application, creates the floppy image, and loads it in QEMU

   ```bash
   chmod +x build.sh
   ./build-release.sh
   ```

3. **Pack**: Compress and encrypt the application using the `packer` utility, enabling compression 
   before building the floppy image

### Testing

Run the floppy image in QEMU to emulate the bootloader's behavior:

```bash
qemu-system-x86_64 -drive file=floppy.img,format=raw,if=floppy,index=0 -boot a
```

(Both `build-release.sh`, `build-debug.sh` starts the build image in QEMU.)

## Project files

- **boot.asm**: Main bootloader file, handles loading and unpacking (decompressing and decrypting) the application
- **application.asm**: The application loaded by the bootloader, displays output on-screen
- **packer.c**: Utility for compressing and encrypting the application using RLE and XOR
- **build-release.sh**: Script for building and assembling all project components in release mode
- **build-debug.sh**: Script for building and assembling all project components in debug mode
- **makefloppy.sh**: Helper script to create the floppy disk image (used by `build-release.sh` and `build-debug.sh`)

## Example workflow

1. Write the bootloader and application in assembly language
2. Assemble, create the floppy, and run the image in QEMU by running `build-release.sh` or `build-debug.sh`

## License

MIT License

```
MIT License

Copyright (c) 2024 Patrik Sporre

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```