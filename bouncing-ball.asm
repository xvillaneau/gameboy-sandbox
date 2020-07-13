; vim: filetype=rgbds

; "Bouncing Logo" Game Boy assembly code.
; This reproduces the "some logo bouncing around the screen" pattern that used
; to be a very popular screen saver. Maybe it'll hit the corner eventually!
; You can control the *speed* of the "ball" using the D-Pad.

; This effect is reproduced here by scrolling the background by one pixel in
; each direction after every frame. The directions of travel are reversed when
; the borders are reached. This is my first time doing interruption handling or
; moving graphics on the Game Boy, pardon the sloppy code.

INCLUDE "hardware.inc"


SECTION "VBlank Interrupt", ROM0[$0040]
    jp VSync


SECTION "Header", ROM0[$100]

EntryPoint:
    nop
    jp Main
    ; Make space for ROM header
    ds $0150 - @, $00


; Constants
MAX_SPEED EQU 10
BALL_CHAR EQU $19
GRAVITY EQU 1

BallInit:
    db 20, 10, 0, 2
BallInitEnd:


SECTION "Main", ROM0

Main:
    di          ; Disable interrupts
.sync
    ; Wait for the vertical blanking interval so that we can disable the LCD.
    ; The rLY value can be 0-153, and the VBlank is in 144-153.
    ld a, [rLY]
    cp 144
    jr c, .sync ; Carry set => a < 144

    ; Write 0 to the LDCD to disable the LCD and gain access to the VRAM.
    xor a
    ld [rLCDC], a

    ; Disable sound
    ld [rNR52], a

    ; Set Scan X and Y to 0
    ld [rSCX], a
    ld [rSCY], a

    ; Initialize HRAM variables
    ld [hJoyPressed], a
    ; All ball variables are in an array
    ld hl, hBallVars
    ld de, BallInit
    ld bc, BallInitEnd - BallInit
    call CopyBinary

    ; Prepare ball sprite
    call ResetOAM
    ld a, BALL_CHAR  ; Nintendo (R) logo
    ld [oTile], a
    call RenderBall

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

; This code is run at the end of each frame. It detects the inputs, computes
; the next sprite positions and collisions, then updates the sprite.
VSync:
    ; Apply Joypad inputs
    call JoypadUpdate

    ; Simulate gravity by applying a constant Y increment
    ld hl, hYSpeed
    ld a, GRAVITY
    add [hl]
    ld [hl], a

    ; Process Y movement and collisions
    ld bc, hYPos
    ld d, SCRN_Y - 8
    call ProcessAxis

    ; Process X movement and collisions
    inc hl
    inc bc
    ld d, SCRN_X - 8
    call ProcessAxis

    call RenderBall
    reti

; Read the console inputs and update the ball's speed accordingly.
JoypadUpdate:
    ; Read the DPad
    ld a, 1 << 5
    ld [rP1], a

    ; Read multiple times for reliability
    REPT 6
    ld a, [rP1]
    ENDR

    ; Filter the DPad presses. Warning: 0 means pressed!
    ; Bits: 3-Down, 2-Up, 1-Left, 0-Right
    ld hl, hJoyPressed  ; Buttons pressed at previous frame
    and a, %1111        ; Keep lower nibble only
    ld c, a             ; Save for later
    xor a, [hl]         ; Discard same states
    and a, [hl]         ; Keep falling edges only
    ld b, a

    ld hl, hYSpeed

    ; Down: increase Y speed
    bit 3, b
    jr z, .skipDown
    ld a, MAX_SPEED
    cp [hl]
    jr z, .skipDown
    inc [hl]
.skipDown

    ; Up: decrease Y speed
    bit 2, b
    jr z, .skipUp
    ld a, -MAX_SPEED
    cp [hl]
    jr z, .skipUp
    dec [hl]
.skipUp

    ld hl, hXSpeed

    ; Left: decrease X speed
    bit 1, b
    jr z, .skipLeft
    ld a, -MAX_SPEED
    cp [hl]
    jr z, .skipLeft
    dec [hl]
.skipLeft

    ; Right: increase X speed
    bit 0, b
    jr z, .skipRight
    ld a, MAX_SPEED
    cp [hl]
    jr z, .skipRight
    inc [hl]
.skipRight

    ; Store the current pressed buttons
    ld a, c
    ld [hJoyPressed], a

    ret

; Compute the next position along a given axis. If that position is out of
; bounds, a bounce is computed and the speed reversed.
;  @param hl  Address of the speed
;  @param bc  Address of the position
;  @param d   Length along the axis
ProcessAxis:
    ; Update the position by adding the speed to it.
    ld a, [bc]
    add [hl]
    ld [bc], a

    ld e, a  ; Store new position for later

    ; Check if the new position is between zero and the axis length (included).
    cp d
    ret z ; Zero set means pos == limit, which is in bounds
    ret c ; Carry set means 0 <= pos < Limit, therefore no collisions

    ; Compare unsigned speed with 128. If carry is set, then the signed speed
    ; is positive and we are computing an upper bound collision.
    ld a, [hl]
    cp $80
    jr c, .limit_bump 

    ; Speed < 0 => New position: 0 - pos
    xor a
    jr .inv_speed

.limit_bump
    ; New position: (max << 1) - pos
    ld a, d
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
RenderBall:
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
hBallVars:
hYPos:
    db
hXPos:
    db
hYSpeed:
    db
hXSpeed:
    db
hJoyPressed:
    db
