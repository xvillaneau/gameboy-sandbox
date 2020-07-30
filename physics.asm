; vim: filetype=rgbds

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
    inc b

    ; Set B to 0 if the speed is negative
    ld a, [de]
    cp $80
    ld a, c     ; Can't use XOR A, that would reset the carry!
    sbc a, c
    and b
    ld b, a

    ; BC now holds the limit; subtract that from the position
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


SECTION "Physics Variables", HRAM

PhysicsVars:
hYPos:      dw
hYSpeed:    dw
hXPos:      dw
hXSpeed:    dw
hRot:       db

