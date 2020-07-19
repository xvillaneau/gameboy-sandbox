; vim: filetype=rgbds

; "Bouncing Ball" Game Boy assembly code.
; You can control the *speed* of the ball using the D-Pad.

; This is my first time doing interruption handling or moving graphics
; on the Game Boy, so pardon the sloppy code.

include "constants.asm"
include "physics.asm"


SECTION "VBlank Interrupt", ROM0[_VSYNC_CALL]
    jp VSync


SECTION "Header", ROM0[_EXEC_BEGIN]

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

    ; Prepare ball sprite
    ld hl, $8800  ; VRAM block 1
    ld de, BallSprite
    ld bc, BallSpriteEnd - BallSprite
    call CopyBinary

    call PhysicsInit
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
    ld hl, _OAM
    ld b, 40 * 4
    xor a
.oam_reset
    ld [hli], a
    dec b
    ret z
    jr .oam_reset


SECTION "Handlers", ROM0

VSync:
    call PhysicsMain
    call RenderBall
    reti


SECTION "Render", ROM0

; Write the new sprite position in the OAM
RenderBall:
    ; Put sprite params in bc depending on rotation
    call ComputeRotation

    ld hl, _OAM

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


SECTION "Sprites", ROM0

RotationParams:
    db $00, $02, $04, $06   ; Sprites un-changed 
    db $46, $44, $42, $40   ; Reverse order, Y-flipped
    db $10, $12, $14, $16   ; Use Palette 1 (colors 1-2 flipped)
    db $56, $54, $52, $50   ; Palette 1, Y-flipped, reversed

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
