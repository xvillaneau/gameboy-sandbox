; vim: filetype=rgbds

; "Bouncing Ball" Game Boy assembly code.
; You can control the *speed* of the ball using the D-Pad.

; This is my first time doing interruption handling or moving graphics
; on the Game Boy, so pardon the sloppy code.

; Hardware register ddresses
rJOYPAD  EQU $ff00  ; Joypad comm register
rSOUNDON EQU $ff25  ; Sound general on/off (bit 7 only)
rLCDCTRL EQU $ff40  ; LCD Controls
rLCDSTAT EQU $ff41  ; LCD controller status
rSCROLLY EQU $ff42  ; Y scroll, in pixels 
rSCROLLX EQU $ff43  ; X scroll
rLCDYPOS EQU $ff44  ; Y coord being rendered
rOBJPAL0 EQU $ff48  ; Object pallet 0
rOBJPAL1 EQU $ff49  ; Object pallet 1
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
GRAVITY EQU $0010


SECTION "VBlank Interrupt", ROM0[$0040]
    jp VSync


SECTION "Header", ROM0[$100]

EntryPoint:
    nop
    jp Init
    ; Make space for ROM header
    ds $0150 - @, $00


SECTION "Initialization", ROM0

Init:
    di
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
    call RenderBall

    ; Set palette intensities, 0 is default, 1 has 1/2 inverted
    ld a, %11100100  ; 3 2 1 0
    ld [rOBJPAL0], a
    ld a, %11011000  ; 3 1 2 0
    ld [rOBJPAL1], a

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

VSync:
    ; Run after each frame; computes and makes changes to the ball sprite

    ; TODO: Make joypad 16-bit compatible!
    ;call JoypadUpdate

    ; Simulate gravity by applying a constant Y increment
    ld hl, hYSpeed
    ld de, GRAVITY
    ld a, [hl]
    add e
    ldi [hl], a
    ld a, [hl]
    adc d
    ld [hl], a

    ; Process Y movement and collisions
    ld hl, hYPos
    ld de, hYSpeed
    ld b, SCREEN_Y - 16
    call ProcessAxis

    ; Process X movement and collisions
    ld hl, hXPos
    ld de, hXSpeed
    ld b, SCREEN_X - 16
    call ProcessAxis

    ; Rotation after X speed
    ld hl, hRot
    inc [hl]

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
;  @param hl  Address of the position (16 BIT!)
;  @param de  Address of the speed (16 BIT!)
;  @param b   Length along the axis
ProcessAxis:
    ld c, 0

    ; Add speed value to the position (16-bit)
    ld a, [de]
    add [hl]
    ldi [hl], a
    inc de
    ld a, [de]
    adc [hl]
    ld [hl], a

    ; Process collisions on the high byte (pixels) only
    ld a, b
    cp [hl]
    ret nc

    ; Compute new position after collision
    ld a, [de]
    cp $80
    ld a, c     ; Can't use XOR A, that would reset the carry!
    sbc a, c
    and b
    ld b, a

    ; DC now holds the limit; subtract that from the position
    ; Low byte of limit is always $00, so do high byte only
    ld a, [hl]
    sub b
    ld [hl], a

    ; Now, subtract that from the limit
    dec hl
    ld a, c
    sub [hl]
    ldi [hl], a
    ld a, b
    sbc [hl]
    ld [hl], a

    ; Inverse speed (16 bit!).
    dec de
    ld h, d
    ld l, e
    xor a
    sub [hl]
    ldi [hl], a
    ld a, c     ; Can't use XOR A, that would reset the carry!
    sbc [hl]
    ld [hl], a

    ret

; Write the new sprite position in the OAM
RenderBall:
    ; Put sprite params in bc depending on rotation
    call ComputeRotation

    ld hl, oSTART

    ; Left half 
    ldh a, [hYPos + 1]
    add a, 16
    ld [hli], a

    ldh a, [hXPos + 1]
    add a, 8
    ld [hli], a

    ld a, b
    ld [hli], a

    ld a, c
    ld [hli], a

    ; Right half
    ldh a, [hYPos + 1]
    add a, 16  ; 8 px to right of first half
    ld [hli], a

    ldh a, [hXPos + 1]
    add a, 16
    ld [hli], a

    ld a, b
    ld [hli], a

    ; Second half-sprite is rotated 180°, so X and Y flips are inverted
    ld a, c
    xor %01100000
    ld [hli], a

    ret

; Compute rotation sprite parameters
; At the end of this code, B will hold the offset of the 32-byte tile
; and C will hold the OAM flags (Y flip & Palette vary)
ComputeRotation:
    ldh a, [hRot]
    and %1111   ; Use low 4 bits for the rotation index

    ; Compute the address of the stored parameters
    ld hl, RotationParams
    ld b, 0
    ld c, a
    add hl, bc

    ; Extract data
    ld a, [hl]
    and a, $0f  ; Low bits are the sprite number
    add a, $80  ; Add 128 since those are in block 1
    ld b, a
    ld a, [hl]
    and a, $f0  ; High bits are the sprite flags
    ld c, a

    ret


SECTION "Data", ROM0

BallInit:
    ; YPos, XPos, YSpeed, XSpeed
    dw $1400, $0a00, 0, $00a0
    ; Rotation
    db 0
BallInitEnd:

RotationParams:
    db $00, $02, $04, $06   ; Sprites un-changed 
    db $46, $44, $42, $40   ; Reverse order, Y-flipped
    db $10, $12, $14, $16   ; Use Palette 1 (colors 1-2 flipped)
    db $56, $54, $52, $50   ; Palette 1, Y-flipped, reversed


SECTION "Sprites", ROM0

BallSprite:
INCBIN "Ball_16x8.2bpp"
BallSpriteEnd:


SECTION "High RAM", HRAM

hBallVars:
hYPos:
    dw
hYSpeed:
    dw
hXPos:
    dw
hXSpeed:
    dw
hRot:
    db
hJoyPressed:
    db
