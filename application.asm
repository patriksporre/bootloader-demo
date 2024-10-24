BITS 16                     ; Instruct NASM that this is 16 bit (real mode) code
org 0x9000                  ; Set the origin to 0x9000 which is where the bootloader will put it

start:
    mov ax, 0xb800          ; Set AX to the video memory segment (0xb800)
    mov es, ax              ; Load ES with the video memory segment
    
    xor di, di              ; Start at the beginning of the video memory (offset 0)
    mov cx, 2000            ; 80 characters wide and 25 characters tall

clearscreen:
    mov byte [es:di], 0x20  ; Write character (space character) to video memory at ES:DI
    inc di                  ; Move to next byte (the attribute)

    mov byte [es:di], 0x07  ; Write attribute (light gray on black) to video memory at ES:DI
    inc di                  ; Move to the next byte (the character)

    dec cx                  ; Decrement CX
    jnz clearscreen         ; Jump to 'clearscreen' if CX is not zero

    lea si, [message]       ; Load the effective address of 'message' into SI
    xor di, di              ; Start at the beginning of the video memory (offset 0)

printchar:
    mov al, [si]            ; Load the next byte from [SI] into AL
    cmp al, 0               ; Compare the byte with 0 (the null terminator)
    je end                  ; If the byte is 0 jump to 'end'

    mov [es:di], al         ; Write character to video memory at ES:DI
    inc di                  ; Move to next byte (the attribute)

    mov byte [es:di], 0x07  ; Attribute byte (light gray on black)
    inc di                  ; Move to the next byte (the character)

    inc si                  ; Move to the next character

    jmp printchar           ; Repeat for the next character

end:
    hlt                     ; Halt the CPU

message db 'Hello World', 0 ; The 'Hello World' message followed by a null terminator (0)