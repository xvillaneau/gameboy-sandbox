; vim: filetype=rgbds

; Constants
GRAVITY EQU $0010


SECTION "Physics", ROM0

PhysicsInit:
    ; All ball variables are in an array
    ld hl, PhysicsVars
    ld de, .data
    ld bc, .data_end - .data
    call CopyBinary
    ret
.data
    ; YPos, YSpeed, YAbsSpeed, XPos, XSpeed, XAbsSpeed
    dw $1400, 0, 0, $0a00, $00a0, $00a0
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
    ld c, a

    ld a, [hl]
    adc d
    ld [hl], a
    ld b, a

    ; Store the speed's absolute value
    call AbsValBC
    ld hl, hYAbsSpeed
    ld a, c
    ldi [hl], a
    ld [hl], b

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


SECTION "Physics Variables", HRAM

PhysicsVars:
hYPos:      dw
hYSpeed:    dw
hYAbsSpeed: dw
hXPos:      dw
hXSpeed:    dw
hXAbsSpeed: dw
hRot:       db

