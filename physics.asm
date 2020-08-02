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
    db 0
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

.detect_collisions
    ld b, 0  ; Will hold collision ID

    ; Y collisions first
    ld hl, hYPos + 1
    ld a, SCREEN_Y - 16
    cp [hl] ; Carry set => Y > limit => collision
    jr nc, .collisions_X

    ldh a, [hYSpeed + 1]
    jr .collisions_set

.collisions_X
    ; X collisions second
    ld hl, hXPos + 1
    ld a, SCREEN_X - 16
    cp [hl] ; Carry set => X > limit => collision
    ret nc

    ldh a, [hXSpeed + 1]
    set 1, b

.collisions_set
    ; Reminder on X collision modes:
    ; 00 - Collision in Y0, vY < 0
    ; 01 - Collision in Yl, vY ≥ 0
    ; 10 - Collision in X0, vX < 0
    ; 11 - Collision in Xl, vX ≥ 0
    cp $80 ; Carry set => 0 ≤ A < 128
    ld a, 0
    adc b
    ld b, a

    ; Process Y movement and collisions
    ld hl, hYPos
    ld b, SCREEN_Y - 16
    call ProcessAxis

    ; Process X movement and collisions
    ld hl, hXPos
    ld b, SCREEN_X - 16
    call ProcessAxis

    ret

; Compute the next position along a given axis. If that position is out of
; bounds, a bounce is computed and the speed reversed.
;  @param hl  Address of the position (16 BIT!)
;  @param de  Address of the speed (16 BIT!)
;  @param b   Length along the axis
ProcessAxis:
    ld c, 0

    ; Process collisions on the high byte (pixels) only
    inc hl
    ld a, b
    cp [hl]
    ret nc
    inc b

    ; Set B to 0 if the speed is negative
    inc hl
    inc hl
    ldd a, [hl]
    cp $80
    ld a, c     ; Can't use XOR A, that would reset the carry!
    sbc a, c
    and b
    ld b, a

    ; BC now holds the limit; subtract that from the position
    ; Low byte of limit is always $00, so do high byte only
    dec hl
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
    ldi [hl], a  ; HL now points to the speed

    ; Inverse speed (16 bit!).
    xor a
    sub [hl]
    ldi [hl], a
    ld a, c     ; Can't use XOR A, that would reset the carry!
    sbc [hl]
    ld [hl], a

    ; Subtract constant bump friction
    ld a, $80
    cp [hl]
    dec hl
    jr c, .negative_friction ; Carry => V < 0 => Add friction

    ; Otherwise, subtract friction
    ld a, [hl]
    sub BUMP_DV
    ldi [hl], a
    ld a, [hl]
    sbc c
    ldd [hl], a
    ret nc
    jr .set_zero

.negative_friction
    ld a, [hl]
    add BUMP_DV
    ldi [hl], a
    ld a, [hl]
    adc c
    ldd [hl], a
    ret nc

.set_zero
    ; HL points at speed; set it to zero
    xor a
    ldi [hl], a
    ldd [hl], a

    ; Compute position: If BC == 0 then keep it zero.
    ; If not, subtract 1 from BC.
    xor a
    cp b
    ld a, c
    sbc c
    ld c, a
    ld a, b
    sbc 0
    ld b, a

    ; Set position to value in BC
    dec hl
    ld [hl], b
    dec hl
    ld [hl], c
 
    ret


ProcessCollision:
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
    ret

.set_zero
    ; Set speed to 0
    xor a
    ldi [hl], a  ; Speed, low byte
    ldd [hl], a  ; Speed, high byte

    ; Set position to 1 sub-pixel
    dec hl
    ldd [hl], a  ; Pos, high byte
    inc a
    ld [hl], a   ; Pos, low byte
 
    ret


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
hCFlags:    db
