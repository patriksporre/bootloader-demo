; boot.asm
; 
; Author: Patrik Sporre
; License: MIT License
; 
; This bootloader program loads a secondary application from a specified sector on a floppy disk
; into memory and then jumps to execute it. It is designed to be minimalistic and primarily used 
; for educational purposes or as a foundation for more advanced bootloader development.
; 
; Through extensive debugging, I have identified some key points for successful implementation:
;
; 1. Sector addressing misalignment:
;    - BIOS uses 1-based indexing for sectors (set `cl` to `0x02` for sector 2),
;      while the head and cylinder are 0-based. Misalignment here leads to loading
;      incorrect data or system halts
;
; 2. `dd` command and `seek` misalignment:
;    - When creating the floppy image with `dd`, set `seek=1` for writing to sector 2.
;      Setting `seek=2` actually skips to sector 3, placing data incorrectly at 0x400 
;      instead of 0x200
;
; 3. Proper segment register setup:
;    - On boot, BIOS leaves segment registers in an undefined state. Setting `ds`,
;      `es`, and `ss` to `0x0000` and `sp` to `0x7C00` is essential for stability
;
; 4. Correct drive number handling:
;    - BIOS provides the boot drive in `dl`, which must be saved and reused for
;      subsequent disk reads. Hardcoding this value causes loading errors
;
; 5. Memory addressing for application:
;    - Load the application to a specified address (e.g., `0x9000`). Use a far jump
;      (`jmp 0x0000:0x9000`) to ensure `cs` and `ip` are set correctly, preventing
;      execution errors in the application
;
; 6. Debugging with visual feedback:
;    - Adding character output ('L' for load, 'J' for jump, 'E' for error) helps 
;      visualize bootloader progression and debug issues quickly
;
; Usage:
; - Assemble this bootloader using NASM:
;     nasm -f bin boot.asm -o boot.bin
;
; - The assembled bootloader (boot.bin) can then be written to the first sector of a floppy image 
;   using a script or direct dd command:
;     dd if=boot.bin of=floppy.img bs=512 count=1 conv=notrunc
;
; - This bootloader expects an application to be placed in the second sector of the floppy (offset 0x200)
; 
; Features:
; - Initializes stack and segment registers to ensure predictable behavior
; - Displays debug characters ('L', 'J', and 'E') for "Load," "Jump," and "Error" stages
; - Jumps to the loaded application at memory address 0x9000
; - Pads the boot sector to 512 bytes and ends with the 0xAA55 boot signature
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

    ; Display 'L' for loading stage
    mov ah, 0x0e            
    mov al, 'L'             
    int 0x10                ; Display 'L' to confirm load phase

    ; Load the main application from sector 1 (0-based) of the floppy disk
    mov ah, 0x02            ; BIOS function to read sectors
    mov al, 0x01            ; Number of sectors to read (1), updated depending on application size
    mov ch, 0x00            ; Cylinder number (0)
    mov cl, 0x02            ; Sector number (2 in 1-based indexing) <!-- IMPORTANT!
    mov dh, 0x00            ; Head number (0)
    mov dl, [boot_drive]    ; Boot drive number (passed by BIOS)
    mov bx, 0x9000          ; Destination memory for the read (0x9000)
    int 0x13                ; Interrupt to read sector

    jc error                ; Jump to 'error' if reading failed

    ; Display 'J' for jump stage
    mov ah, 0x0e
    mov al, 'J'
    int 0x10                ; Display 'J' before jumping to application

    ; Far jump to application loaded at 0x9000
    jmp 0x0000:0x9000       ; Set CS and IP correctly with far jump

error:
    ; Display 'E' for error
    mov ah, 0x0e
    mov al, 'E'
    int 0x10                ; Display error indicator

halt_loop:
    hlt                     ; Halt in case of error
    jmp halt_loop           ; Infinite loop on error

; Boot sector padding and signature
    times 510-($-$$) db 0   ; Pad the boot sector to 510 bytes
    dw 0xAA55               ; Boot sector signature (0xAA55), required for a bootable sector

section .data               ; Data section

    boot_drive db 0         ; Variable to store boot drive number