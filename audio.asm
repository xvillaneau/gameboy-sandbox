
include "hardware.inc"


SECTION "Header", ROM0[$0000]
	; rst $00
	ds $08 - @, $00
	; rst $08
	ds $10 - @, $00
	; rst $10
	ds $18 - @, $00
	; rst $18
	ds $20 - @, $00
	; rst $20
	ds $28 - @, $00
	; rst $28
	ds $30 - @, $00
	; rst $30
	ds $38 - @, $00
	; rst $38
	ds $40 - @, $00

	; V-Blank interrupt
    reti
    ds $48 - @, $00

	; LCDC interrupt
    reti
    ds $50 - @, $00

	; Timer interrupt
    reti
    ds $58 - @, $00

	; Serial Com interrupt
    reti
    ds $60 - @, $00

	; Joypad interrupt
    reti
    ds $0100 - @, $00

EntryPoint:
    nop
    jp Init
    ; Make space for ROM header
    ds $0150 - @, $00


SECTION "Main", ROM0

Init:
    di
._sync
    ; Wait for the vertical blanking interval so that we can disable the LCD.
    ldh a, [rLY]
    cp 144				; Wait for first frame to draw
    jr c, ._sync		; carry unset => V-Blank started

    xor a
    ldh [rLCDC], a		; Disable LCD Controller to access VRAM
    ldh [rAUDENA], a	; Disable sound

	call InitSound

    ; Core loop of the program. All this does is wait for the next interrupt.
	ld a, LCDCF_ON
	ldh [rLCDC], a

    ld a, 1
    ldh [rIE], a 		; Enable VBlank interrupts handling
    ei      			; Enable interrupts

.loop:
    halt        		; Stop CPU until next interupt
    ; There needs to be a NOP after HALT, rgbasm does that for us
	call ReadInput
    jr .loop     		; Loop forever


InitSound:
	xor a
	ldh [rAUDENA], a	; Disable sound
	ld a, AUDENA_ON
	ldh [rAUDENA], a

	ld a, AUDTERM_2_LEFT | AUDTERM_2_RIGHT
	ldh [rAUDTERM], a
	ld a, $77
	ld [rAUDVOL], a
	ret


ReadInput:
	ld a, ~ P1F_GET_DPAD
	ldh [rP1], a
	
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	
	and a, $0f
	swap a
	ld b, a

	ld a, ~ P1F_GET_BTN
	ldh [rP1], a
	
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]

	and a, $0f
	or a, b
	cpl
	ldh [hINPUT], a

	ret


SECTION "HRAM", HRAM

hINPUT:
	; Holds the last value of all inputs.
	; Bit set => button pressed.
	;  Bit 7 - Start
	;  Bit 6 - Select
	;  Bit 5 - B
	;  Bit 4 - A
	;  Bit 3 - Down
	;  Bit 2 - Up
	;  Bit 1 - Left
	;  Bit 0 - Right
	ds 1
