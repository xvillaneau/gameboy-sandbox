; vim: filetype=rgbds

; Constants
MAX_SPEED EQU 10
BUMP_FRICTION_SHIFT EQU 4
GRAVITY EQU $0010

FLAGS_COL EQU 0


SECTION "Mechanics", ROM0

PhysicsInit:
    ; All ball variables are in an array
    ld hl, hBallVars
    ld de, .data
    ld bc, .data_end - .data
    call CopyBinary
    ret
.data
    ; YPos, XPos, YSpeed, XSpeed
    dw $1400, $0a00, 0, $00a0
    ; Rotation
    db 0
.data_end

PhysicsMain:
    ; Run after each frame; computes and makes changes to the ball sprite

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

    ; Rotation, constant for now
    ld hl, hRot
    inc [hl]

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

