; I/O Port 1 Flags

.equ RAM_Bank_0_Enable,   #0x00
.equ RAM_Bank_1_Enable,   #0x01
.equ RAM_Bank_2_Enable,   #0x02
.equ RAM_Bank_3_Enable,   #0x03
.equ BIOS_Disable,        #0x04

.equ Controller_Read      #0xF8
.equ Stick_Up             #0xD8
.equ Stick_Down           #0xE8
.equ Stick_Left           #0x78
.equ Stick_Right          #0xB8  
.equ Button_Up            #0xC8
.equ Button_Down          #0xF0
.equ Button_Left          #0xA8
.equ Button_Right         #0x68

; BIOS Routines

.equ DisplayVideo         #0x0003
.equ WriteSound           #0x001B