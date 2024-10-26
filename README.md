
# Minimalist bootloader with application loader

This project contains a simple bootloader written in NASM assembly, designed to load a secondary application from a 
specific sector on a floppy disk, decompress it with RLE (Run-Length Encoding) and XOR decryption, and jump to execute 
it in memory. The bootloader is intended as an educational example, showcasing several foundational techniques for 
bootloader development in a 16 bit real-mode environment.

## Features

- **Simple sector-based loading**: Loads a compressed and encrypted application from the floppy disk's second sector
- **RLE Compression and XOR Encryption**: Compresses and encrypts the application binary for minimized disk usage
- **Basic Debug Output**: Displays characters ('L', 'U', 'J', 'E') for debugging stages: Load, Unpack, Jump, and Error
- **Far Jump Execution**: Loads and jumps to the application at a specific memory address, setting `CS` and `IP`

## Key learnings and common pitfalls

1. **Sector Addressing**: BIOS uses 1-based indexing for sectors (`CL=0x02` for sector 2) but 0-based for cylinders 
   and heads
2. **Data Placement**: Writing to sector 2 (offset 0x200) requires setting `seek=1` with the `dd` command
3. **Segment Register Setup**: Ensure `DS`, `ES`, and `SS` are set to `0x0000`, and `SP` to `0x7C00`
4. **Drive Number Handling**: Save the boot drive number (`DL`) provided by BIOS for accurate disk access
5. **Memory Jumping**: Use far jumps (`jmp 0x0000:0x9000`) to set `CS` and `IP` correctly when jumping to the application
6. **Debug Output**: Print characters to track the bootloader's progress through key stages

## Usage

### Build and assemble

1. **Setup**: Ensure `nasm`, `qemu`, and optionally `gcc` are installed for building and testing
2. **Build**: Run the `build.sh` script, which assembles the bootloader and application, optionally compresses the 
   application, and creates the floppy image

   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. **Pack**: Compress and encrypt the application using the `packer` utility, enabling compression 
   before building the floppy image

### Testing

Run the floppy image in QEMU to emulate the bootloader's behavior:

```bash
qemu-system-x86_64 -drive file=floppy.img,format=raw,if=floppy,index=0 -boot a
```

## Project files

- **boot.asm**: Main bootloader file, handles loading and decompressing the application
- **application.asm**: Secondary application loaded by the bootloader, displays output on-screen
- **packer.c**: Utility for compressing and encrypting the application using RLE + XOR
- **build.sh**: Script for building and assembling all project components
- **makefloppy.sh**: Helper script to create the floppy disk image

## Example workflow

1. Write the bootloader and application in assembly
2. (Optional) Pack the application using the `packer` utility
3. Assemble and create the floppy image using `build.sh` or `makefloppy.sh`
4. Test in QEMU

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

---

This project is designed to provide an easy-to-follow example for beginners interested in low-level programming 
and bootloader development. Have fun exploring and experimenting with the code!
