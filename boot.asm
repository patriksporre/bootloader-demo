; boot.asm
; 
; Author: Patrik Sporre
; License: MIT License
; 
; This bootloader program loads a secondary application from a specified sector on a floppy disk
; into memory and then jumps to execute it. It is designed to be minimalistic and primarily used 
; for educational purposes or as a foundation for more advanced bootloader development.
; 
; Key learnings and common pitfalls:
;
; 1. Sector addressing misalignment:
;    - BIOS uses 1-based indexing for sectors ('cl' should be '0x02' for sector 2), while the head and cylinder are 0-based
;    - Misalignment here leads to incorrect data loading or system halts
;
; 2. 'dd' command and 'seek' misalignment:
;    - For creating the floppy image with 'dd', use 'seek=1' to write to sector 2
;    - Using 'seek=2' skips to sector 3, leading to misaligned data at 0x400 instead of 0x200
;
; 3. Proper segment register setup:
;    - BIOS initializes segment registers unpredictably; set 'ds', 'es', and 'ss' to '0x0000', and 'sp' to '0x7C00'
;
; 4. Correct drive number handling:
;    - Store the boot drive number from 'dl' (provided by BIOS) to correctly access the boot disk
;
; 5. Memory addressing for application:
;    - Load the application to address '0x9000' and use a far jump ('jmp 0x0000:0x9000') to set 'cs' and 'ip' correctly
;
; 6. Debugging with visual feedback:
;    - Displaying 'L', 'J', 'E', and 'U' for "Load", "Jump", "Error", and "Unpack" helps to track the bootloader’s progress
;
; Usage:
; - Assemble this bootloader using NASM:
;     nasm -f bin boot.asm -o boot.bin
;
; - Write the assembled bootloader to the first sector of a floppy image using a script or direct dd command:
;     dd if=boot.bin of=floppy.img bs=512 count=1 conv=notrunc
;
; - This bootloader expects an application to be placed in the second sector of the floppy (offset 0x200)
;
; Example QEMU Test:
; - To test with QEMU, run:
;     qemu-system-x86_64 -drive file=floppy.img,format=raw,if=floppy,index=0 -boot a
; 
; Features:
; - Initializes stack and segment registers for predictable behavior
; - Displays debug characters ('L', 'J', 'E', and 'U') for "Load," "Jump,", "Error", and "Unpack" stages
; - Loads application to memory address '0x9000'
; - Pads the boot sector to 512 bytes and includes the 0xAA55 boot signature
; 
; MIT License:
; 
; Copyright (c) 2023 Patrik Sporre
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

BITS 16                     ; Instruct NASM that this is 16 bit (real mode) code
org 0x7c00                  ; Origin where BIOS loads the bootloader

%define LOAD_ADDR   0x9000  ; Destination address for our compressed application
%define DECODE_ADDR 0xa000  ; Destination address for our unpacked application
%define XOR_KEY     0x69    ; XOR decryption key

section .text               ; Code section

start:
    mov [boot_drive], dl    ; Store the boot drive number from BIOS

    ; Setup segments and stack
    cli                     ; Disable interrupts
    xor ax, ax              ; Zero out AX
    mov ds, ax              ; Set DS (data segment) to 0x0000
    mov es, ax              ; Set ES (extra segment) to 0x0000
    mov ss, ax              ; Set SS (stack segment) to 0x0000
    mov sp, 0x7c00          ; Set SP (stack pointer) to 0x7c00 (stack grows downwards)
    sti                     ; Enable interrupts

%ifdef DEBUG
    ; Display 'L' for loading stage
    mov ah, 0x0e            
    mov al, 'L'             
    int 0x10                ; Display 'L' to confirm load phase
%endif

    ; Load the main application from sector 1 (0-based) of the floppy disk
    mov ah, 0x02            ; BIOS function to read sectors
    mov al, 0x01            ; Number of sectors to read (1), updated depending on application size
    mov ch, 0x00            ; Cylinder number (0)
    mov cl, 0x02            ; Sector number (2 in 1-based indexing) <!-- IMPORTANT!
    mov dh, 0x00            ; Head number (0)
    mov dl, [boot_drive]    ; Boot drive number (passed by BIOS)
    mov bx, LOAD_ADDR       ; Destination memory for the read
    int 0x13                ; Interrupt to read sector

    jc error                ; Jump to 'error' if reading failed

%ifdef DEBUG
    ; Display 'U' for unpack stage
    mov ah, 0x0e
    mov al, 'U'
    int 0x10
%endif

    ; Call 'unpack' to decrompress and decrypt
    call unpack

%ifdef DEBUG
    ; Display 'J' for jump stage
    mov ah, 0x0e
    mov al, 'J'
    int 0x10                ; Display 'J' before jumping to application
%endif

    ; Far jump to application loaded at DECODE_ADDR
    jmp 0x0000:DECODE_ADDR  ; Set CS and IP correctly with far jump

error:
%ifdef DEBUG
    ; Display 'E' for error
    mov ah, 0x0e
    mov al, 'E'
    int 0x10                ; Display error indicator
%endif

halt_loop:
    hlt                     ; Halt in case of error
    jmp halt_loop           ; Infinite loop on error

;------------------------------------------------------------------------------
; Unpack - Decompresses and decrypts the loaded application data
; 
; This function performs RLE (Run-Length Encoding) decompression with XOR 
; decryption to restore the application to its original form before execution.
; The packed and encrypted data is loaded into memory at LOAD_ADDR by the 
; bootloader and is unpacked to DECODE_ADDR, ready for execution.
;
; Registers used:
;   - SI: Source pointer, initially set to LOAD_ADDR (compressed and encrypted data)
;   - DI: Destination pointer, initially set to DECODE_ADDR (decompressed data)
;   - BL: XOR key used for decryption (constant value XOR_KEY)
;   - CL: Counter for RLE decompression (number of bytes to write)
;
; Process:
;   1. Read the repetition count and byte to repeat from the compressed data
;   2. Apply XOR decryption to the byte
;   3. Write the decrypted byte to the destination address DI
;   4. Repeat until all bytes are written, or a zero repetition count signals the end
;------------------------------------------------------------------------------
unpack:
    mov si, LOAD_ADDR         ; Set source pointer to compressed data start
    mov di, DECODE_ADDR       ; Set destination pointer to decompressed data start
    mov bl, XOR_KEY           ; Load the XOR decryption key into BL

next:
    mov al, [si]              ; Load the repetition count into AL
    inc si                    ; Move to the byte to repeat
    cmp al, 0x00              ; Check for end of data
    je  done                  ; If zero, end unpacking

    mov cl, al                ; Store repetition count in CL
    mov al, [si]              ; Load the byte to repeat
    inc si                    ; Move to the next RLE entry
    xor al, bl                ; Decrypt the byte using XOR

repeat:
    mov [es:di], al           ; Write the decrypted byte to memory at ES:DI
    inc di                    ; Increment destination pointer
    dec cl                    ; Decrement repetition counter
    jnz repeat                ; Repeat until count reaches zero

    jmp next                  ; Move to the next block of RLE data

done:
    ret                       ; Return to caller (unpacking complete)

; Boot sector padding and signature
    times 510-($-$$) db 0   ; Pad the boot sector to 510 bytes
    dw 0xAA55               ; Boot sector signature (0xAA55), required for a bootable sector

section .data               ; Data section

    boot_drive db 0         ; Variable to store boot drive number