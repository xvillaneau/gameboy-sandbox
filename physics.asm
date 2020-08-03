; vim: filetype=rgbds

INCLUDE "macros.asm" 

; Constants
GRAVITY EQU $0010
BUMP_DV EQU $40


SECTION "Physics", ROM0


PhysicsInit:
    ; All ball variables are in an array
    ld hl, PhysicsVars
    ld de, .data
    ld bc, .data_end - .data
    call CopyBinary
    ret
.data
    ; YPos, YSpeed, XPos, XSpeed
    dw $1400, 0, $0a00, $00a0
    ; Rotation
    db 0, 1
    ; Collision calculations
    dw 0, 0, 0
.data_end


PhysicsMain:
    ; Run after each frame; computes and makes changes to the ball position

    ; Simulate gravity by applying a constant Y increment
    ld c, hYSpeed - $ff00
    ld de, GRAVITY
    ldh a, [c]
    add e
    ldh [c], a
    inc c
    ldh a, [c]
    adc d
    ldh [c], a

.add_speed
    ; Add Y speed to the ball's position
    dec c
    ld hl, hYPos
    ; Y Pos, low byte
    ldh a, [c]
    add [hl]
    ldi [hl], a
    inc c
    ; Y Pos, high byte
    ldh a, [c]
    adc [hl]
    ld [hl], a

    ; Add X speed to the ball's position
    ld c, hXSpeed - $ff00
    ld hl, hXPos
    ; X Pos, low byte
    ldh a, [c]
    add [hl]
    ldi [hl], a
    inc c
    ; X Pos, high byte
    ldh a, [c]
    adc [hl]
    ld [hl], a

    ; Add rotation speed to the rotation
    ld hl, hRotSpeed
    ldd a, [hl]
    add [hl]
    ld [hl], a


DetectCollisions:
    ld d, 0  ; Will hold collision ID

    ; Y collisions first
    ld hl, hYPos + 1
    ld a, SCREEN_Y - 16
    cp [hl] ; Carry set => Y > limit => collision
    jr nc, .collisions_X

    ld c, hYPos - $ff00
    ld b, hXSpeed - $ff00
    ld e, SCREEN_Y - 15
    jr .collisions_set

.collisions_X
    ; X collisions second
    ld hl, hXPos + 1
    ld a, SCREEN_X - 16
    cp [hl] ; Carry set => X > limit => collision
    ret nc

    ld c, hXPos - $ff00
    ld b, hYSpeed - $ff00
    ld e, SCREEN_X - 15
    set 1, d

.collisions_set

    ; Make HL point to high byte of relative Y speed
    ld h, $ff
    ld a, c
    add 3
    ld l, a

    ; Compute final value of D
    ld a, [hl]
    cp $80 ; Carry set => 0 ≤ A < 128 => Modes 01 or 11
    ld a, 0
    adc d
    ld d, a

    ; Also compute final value of E: in modes 01 or 11, keep it.
    ; Otherwise, set it to zero
    and 1
    sub 1
    cpl
    and e
    ld e, a


PreTransform:
    ; Variables at this point:
    ;  B: HRAM offset of the relative X Speed
    ;  C: HRAM offset of the relative Y Pos
    ;  D: Collision mode
    ;  E: Collision relative Y offset

    ; Copy the absolute position/speed values to the
    ; correct relative registers.

    ld hl, hCYPos
    ; Position, low byte
    ldh a, [c]
    ldi [hl], a
    inc c
    ; Position, high byte with limit subtracted
    ldh a, [c]
    sub e
    ldi [hl], a
    inc c
    ; Y relative speed, low byte
    ldh a, [c]
    ldi [hl], a
    inc c
    ; Y relative speed, high byte
    ldh a, [c]
    ldi [hl], a
    ; X relative speed, low byte
    ld a, c ; Swap B and C
    ld c, b
    ld b, a
    ldh a, [c]
    ldi [hl], a
    inc c
    ; X relative speed, high byte
    ldh a, [c]
    ld [hl], a

    ; Reset the C and B offsets, we'll need them later
    ld a, b
    dec c
    ld b, c
    sub 3
    ld c, a

    ; Finally, invert the registers where necessary
    ld a, d 
    cp 2
    jr nc, .pre_x_col

    and a
    jr nz, .pre_mode_01

; Mode 00
    ld hl, hCXSpeed
    NegAtHL
    jr RunCollisions

; Mode 01
.pre_mode_01
    ld hl, hCYPos
    NegAtHL
    inc hl ; hCYSpeed
    NegAtHL
    jr RunCollisions

.pre_x_col
    and 1
    ; Nothing to do for mode 10
    jr z, RunCollisions

; Mode 11
    ld hl, hCYPos
    NegAtHL
    inc hl ; hCYSpeed
    NegAtHL
    inc hl ; hCXSpeed
    NegAtHL


RunCollisions:
    ; Negate the relative position (now positive)
    ld hl, hCYPos
    NegAtHL
    inc hl

    ; Y Speed in the collision referential is always negative,
    ; therefore we need to add the friction.
    ld a, [hl]
    add BUMP_DV
    ldi [hl], a
    ld a, [hl]
    adc 0
    ldd [hl], a
    ; If adding the friction made the speed positive, then we
    ; set it to zero and stick the ball against the wall.
    jr c, .set_zero

    ; Otherwise, negate the Y speed (now positive)
    NegAtHL
    jr PostTransform

.set_zero
    ; Set speed and position to 0
    xor a
    ldi [hl], a  ; Speed, low byte
    ldd [hl], a  ; Speed, high byte

    dec hl
    ldd [hl], a  ; Pos, high byte
    ld [hl], a   ; Pos, low byte


PostTransform:
    ; Variables reminder:
    ;  B: HRAM offset of the relative X Speed
    ;  C: HRAM offset of the relative Y Pos
    ;  D: Collision mode
    ;  E: Collision relative Y offset

    ; Add one subpixel to the position; this is to avoid issues when
    ; the ball lands EXACTLY on the limit.
    ld hl, hCYPos
    ld a, [hl]
    add 1
    ldi [hl], a
    ld a, [hl]
    adc 0
    ld [hl], a

    ld a, d 
    cp 2
    jr nc, .post_x_col

    and a
    jr nz, .post_mode_01

; Mode 00
    ld hl, hCXSpeed
    NegAtHL
    jr .post_end

; Mode 01
.post_mode_01
    ld hl, hCYPos
    NegAtHL
    inc hl ; hCYSpeed
    NegAtHL
    jr .post_end

.post_x_col
    and 1
    ; Mode 10: Nothing to do
    jr z, .post_end

; Mode 11
    ld hl, hCYPos
    NegAtHL
    inc hl ; hCYSpeed
    NegAtHL
    inc hl ; hCXSpeed
    NegAtHL

.post_end

    ; Copy all relative values back into the correct
    ; absolute registers.

    ld hl, hCYPos
    ; Position, low byte
    ldi a, [hl]
    ldh [c], a
    inc c
    ; Position, high byte with limit subtracted
    ldi a, [hl]
    add e
    ldh [c], a
    inc c
    ; Y relative speed, low byte
    ldi a, [hl]
    ldh [c], a
    inc c
    ; Y relative speed, high byte
    ldi a, [hl]
    ldh [c], a
    inc c
    ; X relative speed, low byte
    ld c, b
    ldi a, [hl]
    ldh [c], a
    inc c
    ; X relative speed, high byte
    ld a, [hl]
    ldh [c], a

    ; Restart the process, in case that there is more than 1 collision
    jp DetectCollisions


SECTION "Physics Variables", HRAM

PhysicsVars:
hYPos:      dw
hYSpeed:    dw
hXPos:      dw
hXSpeed:    dw
hRot:       db
hRotSpeed:  db
; Collision calculations
hCYPos:     dw
hCYSpeed:   dw
hCXSpeed:   dw
