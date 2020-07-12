; vim: syntax=rgbds

; "Bouncing Logo" Game Boy assembly code.
; This reproduces the "some logo bouncing around the screen" pattern that used
; to be a very popular screen saver. Maybe it'll hit the corner eventually!

; This effect is reproduced here by scrolling the background by one pixel in
; each direction after every frame. The directions of travel are reversed when
; the borders are reached. This is my first time doing interruption handling or
; moving graphics on the Game Boy, pardon the sloppy code.

INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

EntryPoint:
    di          ; Disable interrupts
    jp Start

; Make space for ROM header
REPT $150 - $104
    db 0
ENDR


SECTION "VBlank Interrupt", ROM0[$0040]

; This code is run at the end of each frame. It updates the scrolling
; so that a "bouncing" effect is created. In fact, the background is
; static and it's the viewport that's moving...
Bounce:

    ; Start by processing X axis. We first read the value of the
    ; scrolling and check if we've reached a border.
    ld a, [rSCX]
    ; Test for SCX == 0 (left bounce)
    ld b, -1
    and a
    jr z, .xbounce
    ; Next, test for right bounce, this depends on the size of the "ball"
    ld b, 1
    cp SCRN_VX - SCRN_X + (DisplayedStrEnd - DisplayedStr) * 8 
    jr c, .xbounce
    ; Neither border is reached: Don't update scrolling speed
    ldh a, [hXScroll]
    jr .xmove

.xbounce
    ; Update the scrolling speed, set as the value in B
    ld a, b
    ldh [hXScroll], a

.xmove
    ; Update the X position. Note: a scrolling speed of -1 is actually 255,
    ; but the position is also a byte so the overflow makes it work out.
    ld hl, rSCX
    add [hl]
    ld [hl], a

    ; Same for the Y axis
    ld a, [rSCY]
    ld b, -1
    and a
    jr z, .ybounce
    ld b, 1
    cp SCRN_VY - SCRN_Y + 8
    jr c, .ybounce
    ldh a, [hYScroll]
    jr .ymove

.ybounce
    ld a, b
    ldh [hYScroll], a

.ymove
    ld hl, rSCY
    add [hl]
    ld [hl], a

    ; Re-enable interrupts and wait for next frame
    reti


SECTION "Initialization", ROM0

Start:
    ; Wait for the vertical blanking interval so that we can disable the LCD.
    ; The rLY value can be 0-153, and the VBlank is in 144-153.
    ld a, [rLY]
    cp 144
    jr c, Start ; Carry set => a < 144

    ; Write 0 to the LDCD to disable the LCD and gain access to the VRAM.
    xor a
    ld [rLCDC], a

    ; Copy the font tiles to the VRAM byte by byte
    ld hl, $9000 ; pointer to the VRAM (start in third block)
    ld de, FontTiles ; pointer to the font in the ROM
    ld bc, FontTilesEnd - FontTiles ; bytes left to copy
    call CopyBinary
 
    ; Copy the string ASCII values in the VRAM tilemap. Because the font tiles
    ; are offset by their ASCII value, this should print the string.
    ld hl, $9800; Pointer to the VRAM tilemap
    ld de, DisplayedStr ; Point to the string in ROM
    ld bc, DisplayedStrEnd - DisplayedStr
    call CopyBinary

    ; Set palette intensity to the default
    ld a, %11100100  ; 3 2 1 0
    ld [rBGP], a

    ; Set Scan X and Y to 0
    xor a
    ld [rSCX], a
    ld [rSCY], a

    ; Disable sound
    ld [rNR52], a

    ; Enable the LCD with BG display
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a


Main:
    ; Core loop of the program. All this does is wait for the next interrupt.
    ld a, 1
    ld [rIE], a  ; Enable VBlank interrupts
    ei           ; Enable interrupts
.loop:
    halt         ; Stop CPU until next interupt
    jr .loop     ; Loop forever


; Binary data copying macro
; @param hl  Pointer to the first address to write to
; @param de  Pointer to the first address to read from
; @param bc  Number of bytes to copy
CopyBinary:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ; Continue until bc == 0
    ld a, b
    or c
    ret z
    jr CopyBinary


; Binaries 
SECTION "Font", ROM0

FontTiles:
INCBIN "font.chr"
FontTilesEnd:


; Text that we will be displaying
SECTION "Displayed Text", ROM0

DisplayedStr:
    db "(I'm a Ball)"
DisplayedStrEnd:


; RAM variables
SECTION "Memory", HRAM

hXScroll:
    db
hYScroll:
    db

