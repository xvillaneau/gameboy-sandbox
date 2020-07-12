; vim: filetype=rgbds

; "Bouncing Logo" Game Boy assembly code.
; This reproduces the "some logo bouncing around the screen" pattern that used
; to be a very popular screen saver. Maybe it'll hit the corner eventually!

; This effect is reproduced here by scrolling the background by one pixel in
; each direction after every frame. The directions of travel are reversed when
; the borders are reached. This is my first time doing interruption handling or
; moving graphics on the Game Boy, pardon the sloppy code.

INCLUDE "hardware.inc"


SECTION "VBlank Interrupt", ROM0[$0040]
    jp Update


SECTION "Header", ROM0[$100]

EntryPoint:
    nop
    jp Main
    ; Make space for ROM header
    ds $0150 - @, $00


SECTION "Main", ROM0

Main:
    di          ; Disable interrupts
    ; Wait for the vertical blanking interval so that we can disable the LCD.
    ; The rLY value can be 0-153, and the VBlank is in 144-153.
    ld a, [rLY]
    cp 144
    jr c, Main ; Carry set => a < 144

    ; Write 0 to the LDCD to disable the LCD and gain access to the VRAM.
    xor a
    ld [rLCDC], a

    ; Disable sound
    ld [rNR52], a

    ; Set Scan X and Y to 0
    ld [rSCX], a
    ld [rSCY], a

    ; Initialize "Physics"
    ld [hYPos], a
    ld [hXPos], a
    ld a, 1
    ld [hYSpeed], a
    ld [hXSpeed], a

    ; Prepare ball sprite
    call ResetOAM
    ld a, $19  ; Nintendo (R) logo
    ld [oTile], a
    call MoveBall

    ; Set palette intensity to the default
    ld a, %11100100  ; 3 2 1 0
    ld [rOBP0], a

    ; Enable the LCD with BG display
    ld a, LCDCF_ON | LCDCF_OBJON
    ld [rLCDC], a

    ; Core loop of the program. All this does is wait for the next interrupt.
    ld a, 1
    ld [rIE], a  ; Enable VBlank interrupts handling
    ei           ; Enable interrupts
.loop:
    halt         ; Stop CPU until next interupt
    jr .loop     ; Loop forever


SECTION "Tools", ROM0

; Copy data around
;  @param hl  Pointer to the first address to write to
;  @param de  Pointer to the first address to read from
;  @param bc  Number of bytes to copy
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

ResetOAM:
    ; Reset the sprite data in the OAM
    ld hl, _OAMRAM
    ld b, 40 * 4
    xor a
.oam_reset
    ld [hli], a
    dec b
    ret z
    jr .oam_reset


SECTION "Mechanics", ROM0

; This code is run at the end of each frame. It updates the scrolling
; so that a "bouncing" effect is created. In fact, the background is
; static and it's the viewport that's moving...
Update:
    ld hl, hYSpeed
    ld bc, hYPos
    ld d, SCRN_Y - 8
    call ProcessAxis

    inc hl
    inc bc
    ld d, SCRN_X - 8
    call ProcessAxis

    call MoveBall
    reti

; Compute the next position along a given axis. If that position is out of
; bounds
;  @param hl  Address of the speed
;  @param bc  Address of the position
;  @param d   Length along the axis
ProcessAxis:
    ; Update the position
    ld a, [bc]
    add [hl]
    ld [bc], a

    ld e, a  ; Store new position for later

    ; Check if new position is in range
    inc d  ; Make limit exclusive (if lim := $A0, then x == $A0 is in bounds)
    cp a, d
    ret c ; Carry => Pos < Limit

    ; Check if speed positive of negative
    ld a, [hl]
    and a
    ret z ; In case speed is zero, do nothing
    cp a, $80
    jr c, .max_bump ; Carry => Speed >= 0

    ; Speed < 0 => New position: 0 - pos
    xor a
    jr .inv_speed

.max_bump
    ; New position: ((max - 1) << 1) - pos
    ld a, d
    dec a
    rlca

.inv_speed
    ; Set new position after bump
    sub a, e
    ld [bc], a

    ; Invert speed
    xor a
    sub a, [hl]
    ld [hl], a

    ret

; Write the new sprite position in the OAM
MoveBall:
    ld hl, oYPos
    ld a, [hYPos]
    add a, 16
    ld [hli], a
    ld a, [hXPos]
    add a, 8
    ld [hli], a
    ret


SECTION "OAM Labels", OAM

; Some labels pointing to our one sprite in the OAM
oYPos:
    db
oXPos:
    db
oTile:
    db
oFlags:
    db


SECTION "Memory", HRAM

; High RAM variables
hYPos:
    db
hXPos:
    db
hYSpeed:
    db
hXSpeed:
    db

