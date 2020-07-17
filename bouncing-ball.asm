; vim: filetype=rgbds

; "Bouncing Logo" Game Boy assembly code.
; This reproduces the "some logo bouncing around the screen" pattern that used
; to be a very popular screen saver. Maybe it'll hit the corner eventually!
; You can control the *speed* of the "ball" using the D-Pad.

; This effect is reproduced here by scrolling the background by one pixel in
; each direction after every frame. The directions of travel are reversed when
; the borders are reached. This is my first time doing interruption handling or
; moving graphics on the Game Boy, pardon the sloppy code.

; Hardware register ddresses
rJOYPAD  EQU $ff00  ; Joypad comm register
rSOUNDON EQU $ff25  ; Sound general on/off (bit 7 only)
rLCDCTRL EQU $ff40  ; LCD Controls
rLCDSTAT EQU $ff41  ; LCD controller status
rSCROLLY EQU $ff42  ; Y scroll, in pixels 
rSCROLLX EQU $ff43  ; X scroll
rLCDYPOS EQU $ff44  ; Y coord being rendered
rOBJPAL0 EQU $ff48  ; Object pallet 0
rIENABLE EQU $ffff  ; Interrup enable

; VRAM addresses
vBLOCK0 EQU $8000
vBLOCK1 EQU $8800
vBLOCK2 EQU $9000
vTILES0 EQU $9800
vTILES1 EQU $9c00

oSTART EQU $fe00

; Hardware constants
SCREEN_Y EQU 144  ; Screen Y size in pixels
SCREEN_X EQU 160  ; Screen X size in pixels

; Constants
MAX_SPEED EQU 10
BALL_CHAR EQU $19
GRAVITY EQU 1


SECTION "VBlank Interrupt", ROM0[$0040]
    jp VSync


SECTION "Header", ROM0[$100]

EntryPoint:
    nop
    jp Main
    ; Make space for ROM header
    ds $0150 - @, $00


SECTION "Main", ROM0

Main:
    di          ; Disable interrupts
.sync
    ; Wait for the vertical blanking interval so that we can disable the LCD.
    ld a, [rLCDYPOS]
    cp SCREEN_Y      ; Wait for first frame to draw
    jr c, .sync      ; carry set => V-Blank started

    ; Write 0 to the LDCD to disable the LCD and gain access to the VRAM.
    xor a
    ld [rLCDCTRL], a

    ; Disable sound
    ld [rSOUNDON], a

    ; Set Scan X and Y to 0
    ld [rSCROLLY], a
    ld [rSCROLLX], a

    ; Initialize HRAM variables
    ld [hJoyPressed], a
    ; All ball variables are in an array
    ld hl, hBallVars
    ld de, BallInit
    ld bc, BallInitEnd - BallInit
    call CopyBinary

    ; Prepare ball sprite
    ld hl, $8800  ; VRAM block 1
    ld de, BallSprite
    ld bc, BallSpriteEnd - BallSprite
    call CopyBinary

    call ResetOAM

    ld hl, oSTART
    ld de, OAMInit
    ld bc, OAMInitEnd - OAMInit
    call CopyBinary

    call RenderBall

    ; Set palette intensity to the default
    ld a, %11100100  ; 3 2 1 0
    ld [rOBJPAL0], a

    ; Enable the LCD with BG display
    ld a, %10000110 ; Main on, OBJ on, use tall sprites
    ld [rLCDCTRL], a

    ; Core loop of the program. All this does is wait for the next interrupt.
    ld a, 1
    ld [rIENABLE], a  ; Enable VBlank interrupts handling
    ei                ; Enable interrupts
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
    ld hl, oSTART
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
    ld d, SCREEN_Y - 16
    call ProcessAxis

    ; Process X movement and collisions
    inc hl
    inc bc
    ld d, SCREEN_X - 16
    call ProcessAxis

    call RenderBall
    reti

; Read the console inputs and update the ball's speed accordingly.
JoypadUpdate:
    ; Read the DPad
    ld a, 1 << 5
    ld [rJOYPAD], a

    ; Read multiple times for reliability
    REPT 6
    ld a, [rJOYPAD]
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
    ; Left half 
    ld hl, oSTART
    ld a, [hYPos]
    add a, 16
    ld [hli], a
    ld a, [hXPos]
    add a, 8
    ld [hl], a

    ; Right half
    ld de, 3
    add hl, de
    ld a, [hYPos]
    add a, 16
    ld [hli], a
    ld a, [hXPos]
    add a, 16
    ld [hl], a

    ret


SECTION "Data", ROM0

BallInit:
    db 20, 10, 0, 2
BallInitEnd:
OAMInit:
    db 0, 0, $80, $00
    db 0, 0, $80, $60
OAMInitEnd:


SECTION "Sprites", ROM0

BallSprite:
INCBIN "Ball_16x8.2bpp"
INCBIN "Ball_8x8.2bpp"
BallSpriteEnd:

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
