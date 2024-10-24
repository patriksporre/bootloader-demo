BITS 16                     ; Instruct NASM that this is 16 bit (real mode) code
org 0x7c00                  ; Set the origin to 0x7c00 which is where BIOS loads the bootloader

start:
    cli                     ; Disable all interrupts to prevent interruptions during the boot process
    xor ax, ax              ; Set AX to zero (0)
    mov ss, ax              ; Set SS (stack segment) to 0x0000
    mov sp, 0x7c00          ; Set SP (stack pointer) to 0x7c00 (the stack grows downward)

    ; Load the main application from disk (we assume it's in sector 2 of the floppy)
    mov ah, 0x02            ; BIOS function for reading sectors
    mov al, 0x01            ; Specifies the number of sectors to read. In this case one (1)
    mov ch, 0x00            ; Specifies the cylinder to read. In this case zero (0)
    mov cl, 0x02            ; Specifies the sector to read. In this case two (2)
    mov dh, 0x00            ; Specifies the head number of the disk. In this case zero (0)
    mov dl, 0x00            ; Specifies the drive number. In this case zero (0) which typically is the first floppy drive (A:)
    lea bx, [unpack_buffer] ; The memory buffer where the read sector will be stored
    int 0x13                ; BIOS interrupt to read from disk

    jc  error               ; Jump to 'error' if reading failed (the carry flag (CF) is set)

    call unpack             ; Jump to the unpacking routine to uncompress the main application

error:
    hlt                     ; Halt the CPU

; Unpacking routine (RLE + XOR decryption)
unpack:
    lea si, [unpack_buffer] ; Source (the packed and encrypted data)
    mov di, 0x9000          ; Destination (the memory address to put the unpacked data)
    mov bl, [xor_key]       ; Put the XOR key in BL

next:
    mov al, [si]            ; Load the next byte (the length)
    inc si                  ; Move to the next byte (the byte to repeat)
    cmp al, 0x00            ; Check if it's the end of the data
    je  done                ; If 0, jump to 'done'

    mov cl, al              ; CL now hold the length (repeat count)
    mov al, [si]            ; Load the byte to repeat
    inc si                  ; Move to the next byte (the length)
    xor al, bl              ; Decrypt the byte to write

repeat:
    mov [di], al            ; Write the decrypted byte to memory
    inc di                  ; Increment the position in memory
    dec cl                  ; Decrement the length in CL
    jnz repeat              ; Repeat until CL is zero

    jmp next                ; Unpack next block

done:
    ret



; Boot sector padding and signature
    times 510-($-$$) db 0   ; Pad the boot sector to 510 bytes (ensuring the total size is 512 bytes)
    dw 0xAA55               ; Boot sector signature (0xAA55), required for a valid bootable sector

section .bss                ; The .bss section is used for uninitialized data
unpack_buffer resb 512      ; Reserve 512 bytes for loading the packaged application
    
section .data               ; The .data section is used for initialized data
xor_key db  0x69            ; XOR key for decryption