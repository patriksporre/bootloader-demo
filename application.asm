; application.asm
;
; This simple application displays the text "hello!" on the screen using BIOS teletype interrupts 
; and then halts the CPU. It is designed to run after being loaded by a bootloader and demonstrates 
; the basics of BIOS video interrupts for text output in real mode.
;
; Usage:
; - This program should be loaded to memory at address 0xa000 (specified by 'org 0xa000') and
;   executed directly. It assumes the system is in 16 bit real mode with video services enabled
;
; Requirements:
; - 16 bit real mode (e.g., in an emulator or a 16- bit capable system)
; - Loaded by a bootloader that sets up segments correctly and jumps to 0a000
;
; Author: Patrik Sporre
; License: MIT License

BITS 16                       ; Instruct NASM that this code is 16-bit (real mode)
org 0xa000                    ; Set origin to 0xA000, where this application is loaded by the bootloader

section .text                 ; Code section

start:
    ; Display the string "hello!" on the screen, character by character
    mov ah, 0x0e              ; Set AH to 0x0E - BIOS teletype function (for character output)

    ; Display 'h'
    mov al, 'h'               ; Load ASCII value of 'h' into AL
    int 0x10                  ; BIOS interrupt to display character in AL

    ; Display 'e'
    mov al, 'e'               ; Load ASCII value of 'e' into AL
    int 0x10                  ; BIOS interrupt to display character in AL

    ; Display 'l'
    mov al, 'l'               ; Load ASCII value of 'l' into AL
    int 0x10                  ; BIOS interrupt to display character in AL

    ; Display 'l'
    mov al, 'l'               ; Load ASCII value of 'l' into AL
    int 0x10                  ; BIOS interrupt to display character in AL

    ; Display 'o'
    mov al, 'o'               ; Load ASCII value of 'o' into AL
    int 0x10                  ; BIOS interrupt to display character in AL

    ; Display '!'
    mov al, '!'               ; Load ASCII value of '!' into AL
    int 0x10                  ; BIOS interrupt to display character in AL

    ; Halt the CPU
    cli                       ; Disable interrupts to prevent further interrupt handling
    hlt                       ; Halt the CPU indefinitely