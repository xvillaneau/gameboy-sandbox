; vim: syntax=rgbds

; "Hello World" Game Boy assembly code.
; All this does is display "Hello World!"

; This code is a copy of the "Hello World!" example in the Game Boy programming
; tutorial by Eldred "ISSOtm" Habert. So this is pretty much his copyright.
; Comments are my own.
; https://eldred.fr/gb-asm-tutorial/index.html

INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

EntryPoint:
    di          ; Disable interrupts
    jp Start

; Make space for ROM header
REPT $150 - $104
    db 0
ENDR

SECTION "Game code", ROM0

Start:
.waitVBlank
    ; Wait for the vertical blanking interval so that we can disable the LCD.
    ; The rLY value can be 0-153, and the VBlank is in 144-153.
    ld a, [rLY]
    cp 144
    jr c, .waitVBlank ; Carry set => a < 144

    ; Write 0 to the LDCD to disable the LCD and gain access to the VRAM.
    xor a
    ld [rLCDC], a

    ; Copy the font tiles to the VRAM byte by byte
    ld hl, $9000 ; pointer to the VRAM (start in third block)
    ld de, FontTiles ; pointer to the font in the ROM
    ld bc, FontTilesEnd - FontTiles ; bytes left to copy
.copyFont
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ; Continue until bc == 0
    ld a, b
    or c
    jr nz, .copyFont

    ; Copy the string ASCII values in the VRAM tilemap. Because the font tiles
    ; are offset by their ASCII value, this should print the string.
    ld hl, $9800 ; Pointer to the VRAM tilemap
    ld de, HelloWorldStr ; Point to the string in ROM
.copyString
    ld a, [de]
    ld [hli], a
    inc de
    ; Continue until we read a null byte
    and a
    jr nz, .copyString

    ; Set palette intensity to the default
    ld a, %11100100
    ld [rBGP], a

    ; Set Scan X and Y to 0
    xor a
    ld [rSCY], a
    ld [rSCX], a

    ; Disable sound
    ld [rNR52], a

    ; Enable the LCD with BG display
    ld a, %10000001
    ld [rLCDC], a

    ; Loop forever
.lockup
    jr .lockup

SECTION "Font", ROM0

FontTiles:
INCBIN "font.chr"
FontTilesEnd:

SECTION "Hello World", ROM0

HelloWorldStr:
    db "Hello World!", 0 ; Terminate with null byte
