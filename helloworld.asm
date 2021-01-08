; *************************************************************************
; * HelloWorld.asm - 'Hello World' program for the Entex Adventure Vision *
; *************************************************************************

        .include "av.h"

; Variable Locations

        .equ TextStringX     #32
        .equ TextStringY     #33
        .equ Temp1           #34
        .equ Temp2           #35

        ; 0x0000-0x03FF is shared between the first 1k of program ROM and the BIOS.  Only one can be loaded in at a time.
        .org 0x0000

        ; Jump to 0x8000 if we happen to start here so we can load the BIOS into this area
        SEL MB1
        JMP Startup

        ; The BIOS should jump to here if it was loaded on startup
        .org 0x0800
Startup:

       ; (0x0802-0x80B is reserved for certain BIOS routine callbacks so we should probably skip it)
        JMP Main

; ********
; * MAIN *
; ********

        .org 0x080C
Main:

; ******************
; * INITIALIZATION *
; ******************

        CLR A

        ; Load BIOS into 0x0000-0x07FF if not already loaded
        OUTL P1, A

        ; Reset the stack pointer, select register bank 0, and clear flags
        MOV PSW, A

        ; Clear the internal RAM (64 bytes)
        MOV R0, #63                 ; Start at the highest address and decrement with each loop
ClearInternalRAMLoopTop:
        MOV @R0, A                  ; Clear the current memory location
        DJNZ R0, ClearInternalRAMLoopTop
        MOV @R0, A                  ; Clear final memory location

        ; Clear the external RAM (4 banks, each one 256 bytes)
        MOV R0, #4                  ; Start at the highest bank and decrement with each loop
ClearExternalRAMLoopTop:
        DEC R0
        MOV A, R0
        OUTL P1, A                  ; Set the current bank
        MOV R1, #255                ; Start at the highest address and decrement with each loop
        CLR A
ClearExternalRAMInnerLoopTop:
        MOVX @R1, A                 ; Clear the current memory location for this bank
        DJNZ R1, ClearExternalRAMInnerLoopTop
        MOVX @R1, A                 ; Clear final memory location for this bank
        MOV A, R0
        JNZ ClearExternalRAMLoopTop

        ; Clear any sounds that might be playing
        MOV R1, #0x00               
        SEL MB0
        CALL WriteSound
        SEL MB1

        ; Initialize the text string's X and Y position
        MOV A, #30
        MOV R0, TextStringX
        MOV @R0, A
        MOV A, #16
        MOV R0, TextStringY
        MOV @R0, A

; *************
; * MAIN LOOP *
; *************

MainLoopTop:

        ; Blank the video RAM
        CALL BlankVideoRAM

        ; Copy the 'H' sprite (sprite byte offset 0) into video RAM at the correct position
        MOV R1, #0
        MOV R0, TextStringX
        MOV A, @R0
        MOV R2, A
        MOV R0, TextStringY
        MOV A, @R0
        MOV R3, A
        MOV R4, #8
        CALL CopySprite

        ; Copy the 'e' (sprite byte offset 8) into video RAM
        MOV R1, #8
        CALL CopySprite

        ; Copy the two 'l's (sprite byte offset 16) into video RAM
        MOV R1, #16
        CALL CopySprite
        CALL CopySprite

        ; Copy the 'o' (sprite byte offset 24) into video RAM
        MOV R1, #24
        CALL CopySprite

        ; Copy the 'W' (sprite byte offset 32) into video RAM
        MOV R1, #32
        MOV A, R2
        CLR C
        ADD A, #8
        MOV R2, A
        CALL CopySprite

        ; Copy the 'o' (sprite byte offset 24) into video RAM
        MOV R1, #24
        CALL CopySprite

        ; Copy the 'r' (sprite byte offset 40) into video RAM
        MOV R1, #40
        CALL CopySprite

        ; Copy the 'l (sprite byte offset 16) into video RAM
        MOV R1, #16
        CALL CopySprite

        ; Copy the 'd (sprite byte offset 48) into video RAM
        MOV R1, #48
        CALL CopySprite

        ; Call the BIOS routine to draw the screen
        SEL MB0
        CALL DisplayVideo
        SEL MB1

        ; Adjust the positioning of the text, based on the controller input
        CALL UpdateTextPositioning

        ; Loop forever
        JMP MainLoopTop

        .org 0x0E00

; **************************************
; * UPDATE TEXT POSITIONING SUBROUTINE *
; **************************************
;
; Registers used:
;
; * R0-R1 = Temp storage
;

UpdateTextPositioning:

        MOV A, Controller_Read
        OUTL P1, A                   ; Write to port 1 bits 3-7 to ready them for input
        IN A, P1                     ; Read port 1 to get the controller input
        ANL A, Controller_Read       ; (AND the lower 3 bits out just to be safe)
        MOV R0, A                    ; Store the controller input in R0
        XRL A, Controller_Read       ; XOR with controller read bitmask to see if anything is being pressed at all
        JZ EndUpdateTextPositioning  ; If not, return

        ; Check for controller stick 'up' and increment the Y position if it's being pressed
        MOV A, R0                    ; Load the controller input again
        XRL A, Stick_Up              ; XOR with the bit pattern for 'stick up' to see if it's being pressed
        JNZ NoStickUp
        MOV R1, TextStringY
        MOV A, @R1                   ; Load the Y position
        INC A                        ; Add 1
        MOV @R1, A                   ; Store the Y position
        XRL A, #33                   ; XOR with 33 to see if we've gone off the top edge of the screen
        JNZ EndUpdateTextPositioning
        MOV A, #32
        MOV @R1, A                   ; If so, just reset the Y position to 32
        JMP EndUpdateTextPositioning

NoStickUp:

        ; Check for controller stick 'down' and decrement the Y position if it's being pressed
        MOV A, R0                    ; Load the controller input again
        XRL A, Stick_Down            ; XOR with the bit pattern for 'stick down' to see if it's being pressed
        JNZ NoStickDown
        MOV R1, TextStringY
        MOV A, @R1                   ; Load the Y position
        DEC A                        ; Subtract 1
        MOV @R1, A                   ; Store the Y position
        XRL A, #255                  ; XOR with 255 to see if we've gone off the bottom edge of the screen
        JNZ EndUpdateTextPositioning
        CLR A
        MOV @R1, A                   ; If so, just reset the Y position to 0
        JMP EndUpdateTextPositioning

NoStickDown:

        ; Check for controller stick 'left' and decrement the X position if it's being pressed
        MOV A, R0                    ; Load the controller input again
        XRL A, Stick_Left            ; XOR with the bit pattern for 'stick left' to see if it's being pressed
        JNZ NoStickLeft
        MOV R1, TextStringX
        MOV A, @R1                   ; Load the X position
        DEC A                        ; Subtract 1
        MOV @R1, A                   ; Store the X position
        XRL A, #255                  ; XOR with 255 to see if we've gone off the left edge of the screen
        JNZ EndUpdateTextPositioning
        CLR A
        MOV @R1, A                   ; If so, just reset the X position to 0
        JMP EndUpdateTextPositioning

NoStickLeft:

        ; Check for controller stick 'right' and increment the X position if it's being pressed
        MOV A, R0                    ; Load the controller input again
        XRL A, Stick_Right           ; XOR with the bit pattern for 'stick right' to see if it's being pressed
        JNZ EndUpdateTextPositioning
        MOV R1, TextStringX
        MOV A, @R1                   ; Load the X position
        INC A                        ; add 1
        MOV @R1, A                   ; Store the X position
        XRL A, #62                   ; XOR with 62 to see if we've gone off the right edge of the screen
        JNZ EndUpdateTextPositioning
        MOV A, #61
        MOV @R1, A                   ; If so, just reset the X position to 61
        JMP EndUpdateTextPositioning

EndUpdateTextPositioning:

        RET

; ******************************
; * BLANK VIDEO RAM SUBROUTINE *
; ******************************
;
; Registers used:
;
; * R0-R1 = Temp storage
;

BlankVideoRAM:
        ; Blank video RAM (aka external RAM banks 1-3 addresses 6-255) by filling with 0xFFs.
        ; 0xFF is actually an 'off' pixel and 0x00 is 'on' for whatever reason.
        MOV R0, #3                  ; Start at the highest bank and decrement with each loop
BlankVideoRAMLoopTop:
        MOV A, R0
        OUTL P1, A                  ; Set the current bank
        MOV R1, #255                ; Start at the highest address and decrement with each loop
BlankVideoRAMInnerLoopTop:
        MOV A, #0xFF
        MOVX @R1, A                 ; Fill the current memory location for this bank with 0xFF
        DEC R1
        MOV A, R1
        XRL A, #5                   ; XOR mask current loop iteration with 5 so that we stop at 5
        JNZ BlankVideoRAMInnerLoopTop
        DJNZ R0, BlankVideoRAMLoopTop

        RET

; **************************
; * COPY SPRITE SUBROUTINE *
; **************************
;
; Input parameters:
;
; * R1 = Byte offset of the 8 pixel high sprite to read from the data page
; * R2 = X position of the sprite, where 0 is the left side of the screen and 152 is the right
;        (R2 gets incremented automatically by the subroutine)
; * R3 = Y position of the sprite, where 0 is the bottom of the screen and 32 is the top
; * R4 = The width of the sprite in pixels
;
; Additional registers/memory used:
;
; * R0    = Temp storage
; * Temp1 = Temp storage for sprite width that gets passed in via R4
; * R4    = Byte offset location where the sprite will be copied into video memory
; * R5-R6 = Temp storage, sprite data upper and lower registers
; * R7    = Loop iterator
;
CopySprite:

        ; Save sprite width in Temp1
        MOV R0, Temp1
        MOV A, R4
        MOV @R0, A

        MOV R7, #0

CopySpriteTop:

        ; Select the appropriate RAM bank for the given X position.  Also get the RAM bank column index and save it in R0
        MOV A, R2
        MOV R0, A                   ; The default column index will just be the original X position.
        MOV A, #206
        CLR C
        ADD A, R2                   ; Add X position to 206 to see if it overflows
        JC SpriteBankNotBank1       ; If carry is set, then X position was >= 50, so we don't want bank 1
        MOV A, RAM_Bank_1_Enable    ; Select external RAM bank 1
        JMP SpriteBankEndIf
SpriteBankNotBank1:
        MOV R0, A                   ; Update the column index to the outcome of the last addition (which presumably overflowed and wrapped around)
        MOV A, #156
        CLR C
        ADD A, R2                   ; Add X position to 156 to see if it overflows
        JC SpriteBankNotBank2       ; If carry is set, then X position was >= 100, so we don't want bank 2
        MOV A, RAM_Bank_2_Enable    ; Select external RAM bank 2
        JMP SpriteBankEndIf
SpriteBankNotBank2:
        MOV R0, A                   ; Update the column index to the outcome of the last addition (which presumably overflowed and wrapped around)
        MOV A, RAM_Bank_3_Enable    ; Select external RAM bank 3
SpriteBankEndIf:
        OUTL P1, A                  ; Do the actual RAM bank selection

        ; Take the column index and multiply it by 5 to compute the column byte offset.  Store it in R4
        MOV A, R0
        RL A
        RL A
        ANL A, #0xFC                ; First multiply it by 4 using bit shifts
        CLR C
        ADD A, R0                   ; Then add R0 to the result of that to get 'multiply by 5'
        MOV R4, A
        
        ; Compute the sprite's vertical positioning byte offset and add that to the column byte offset
        MOV A, R3                   ; Load the sprite Y position
        RR A                        ; Divide TextStringY by 8 to determine the starting byte index to place the sprite at
        RR A
        RR A
        ANL A, #0x07
        CLR C
        ADD A, #6                   ; Add 6 to the starting byte index, since video RAM goes from 6-255 in each bank
        ADD A, R4                   ; Add this to the column byte offset computed above
        MOV R4, A

        ; Now get the fine positioning bit offset and copy that into R0
        MOV A, R3                   ; Load the sprite Y position again
        ANL A, #0x07                ; AND with the low 3 bytes to get the fine positioning offset
        MOV R0, A

        ; Load the current line of sprite data from the data page
        MOV A, R1                   ; Get the byte offset of the sprite we want
        CLR C
        ADD A, R7                   ; Now add to that the current loop iteration
        MOV R5, A                   ; Save it in R5 which will be the input parameter to 'GetSpriteData'
        CALL GetSpriteData

        ; Load the sprite data into R5.  Fill R6 with 0xFF - it will be the upper sprite register we rotate bits into
        MOV R5, A
        MOV A, #0xFF
        MOV R6, A

        ; Fine positioning while loop - bit shift the sprite data left by one bit for each iteration
FinePositioningLoopTop:
        MOV A, R0
        JZ FinePositioningLoopEnd
        MOV A, R5                   ; Load the sprite data lower register
        CLR C
        CPL C                       ; '1' is an off pixel so we want to make sure the carry is set
        RLC A                       ; Shift it left one bit
        MOV R5, A                   ; Save the data back into the sprite data lower register
        MOV A, R6                   ; Load the sprite data upper register
        RLC A                       ; Shift it left one bit, shifting the carry from the previous shift into bit 0
        MOV R6, A                   ; Save the data back into the sprite data upper register
        DEC R0
        JMP FinePositioningLoopTop
FinePositioningLoopEnd:
 
        ; Write the shifted sprite registers to the video display at the proper locations
        MOV A, R4
        MOV R0, A                   ; Load the video memory starting byte index
        MOVX A, @R0                 ; Get the current value in video memory
        ANL A, R5                   ; AND it with the sprite data lower register
        MOVX @R0, A                 ; Store it in video memory
        INC R0
        MOVX A, @R0                 ; Get the current value in video memory
        ANL A, R6                   ; AND it with the sprite data upper register
        MOVX @R0, A                 ; Store it in video memory

        INC R2                      ; Increment the X position

        INC R7                      ; Increment the loop counter

        MOV R0, Temp1               ; Put the address of Temp1 into R0.  Temp1 is where the sprite width is saved

        MOV A, R7
        XRL A, @R0                  ; XOR mask current loop iteration with the sprite width so that we stop at the right place
        JNZ CopySpriteTop

        ; Put the sprite width back into R4
        MOV R0, Temp1
        MOV A, @R0
        MOV R4, A

        RET

; ******************************
; * GET SPRITE DATA SUBROUTINE *
; ******************************
;
; Input parameters:
;
; * R5 = Byte offset to fetch the data from
;
        .org 0x0F00
GetSpriteData:

        MOV A, #SpriteData % 256
        CLR C
        ADD A, R5
        MOVP A, @A
        
        RET

SpriteData:

        ; Capital H
        .db 0xFF                    ; 11111111
        .db 0x80                    ; 10000000
        .db 0xF7                    ; 11110111
        .db 0xF7                    ; 11110111
        .db 0xF7                    ; 11110111
        .db 0xF7                    ; 11110111
        .db 0x80                    ; 10000000
        .db 0xFF                    ; 11111111

        ; Lowercase E
        .db 0xFF                    ; 11111111
        .db 0xF1                    ; 11110001
        .db 0xEA                    ; 11101010
        .db 0xEA                    ; 11101010
        .db 0xEA                    ; 11101010
        .db 0xEA                    ; 11101010
        .db 0xF3                    ; 11110011
        .db 0xFF                    ; 11111111

        ; Lowercase L
        .db 0xFF                    ; 11111111
        .db 0xFF                    ; 11111111
        .db 0xFF                    ; 11111111
        .db 0x81                    ; 10000001
        .db 0xFE                    ; 11111110
        .db 0xFF                    ; 11111111
        .db 0xFF                    ; 11111111
        .db 0xFF                    ; 11111111

        ; Lowercase O
        .db 0xFF                    ; 11111111
        .db 0xF1                    ; 11110001
        .db 0xEE                    ; 11101110
        .db 0xEE                    ; 11101110
        .db 0xEE                    ; 11101110
        .db 0xEE                    ; 11101110
        .db 0xF1                    ; 11110001
        .db 0xFF                    ; 11111111

        ; Capital W
        .db 0xFF                    ; 11111111
        .db 0x80                    ; 10000000
        .db 0xFD                    ; 11111101
        .db 0xFB                    ; 11111011
        .db 0xFB                    ; 11111011
        .db 0xFD                    ; 11111101
        .db 0x80                    ; 10000000
        .db 0xFF                    ; 11111111

        ; Lowercase R
        .db 0xFF                    ; 11111111
        .db 0xFF                    ; 11111111
        .db 0xF0                    ; 11110000
        .db 0xEF                    ; 11101111
        .db 0xEF                    ; 11101111
        .db 0xEF                    ; 11101111
        .db 0xEF                    ; 11101111
        .db 0xFF                    ; 11111111

        ; Lowercase D
        .db 0xFF                    ; 11111111
        .db 0xF1                    ; 11110001
        .db 0xEE                    ; 11101110
        .db 0xEE                    ; 11101110
        .db 0xEE                    ; 11101110
        .db 0xEE                    ; 11101110
        .db 0x80                    ; 10000000
        .db 0xFF                    ; 11111111

        .org 0x1000 ; End of the 4K ROM memory area