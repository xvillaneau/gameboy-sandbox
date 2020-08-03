
; Make the 16-bit value in DE negative
NegDE: MACRO
    xor a
    sub e   ; Sets z flag if E was 0
    ld e, a
    ld a, d
    cpl     ; Doesn't change z flag
    ld d, a
    jr nz, .endNegDE\@
    inc d   ; Carry 1 to D if E == 0
.endNegDE\@
ENDM

; Make the 16-bit value at [HL] negative
NegAtHL: MACRO
    xor a
    sub [hl]
    ldi [hl], a
    ld a, [hl]
    cpl
    jr nz, .endNegAtHL\@
    inc a
.endNegAtHL\@
    ld [hl], a
ENDM

