; vim: filetype=rgbds


SECTION "rst_00", ROM0[$0000]
	ds $08 - @, $00

SECTION "rst_08", ROM0[$0008]
	ds $10 - @, $00

SECTION "rst_10", ROM0[$0010]
	ds $18 - @, $00

SECTION "rst_18", ROM0[$0018]
	ds $20 - @, $00

SECTION "rst_20", ROM0[$0020]
	ds $28 - @, $00

SECTION "rst_28", ROM0[$0028]
	ds $30 - @, $00

SECTION "rst_30", ROM0[$0030]
	ds $38 - @, $00

SECTION "rst_38", ROM0[$0038]
	ds $40 - @, $00

SECTION "VBlank Interrupt", ROM0[$0040]
    call RenderBall
    reti
    ds $48 - @, $00

SECTION "LCDC Interrupt", ROM0[$0048]
    reti
    ds $50 - @, $00

SECTION "Timer Interrupt", ROM0[$0050]
    reti
    ds $58 - @, $00

SECTION "Serial Com Interrupt", ROM0[$0058]
    reti
    ds $60 - @, $00

SECTION "Joypad Interrupt", ROM0[$0060]
    reti
    ds $0100 - @, $00

SECTION "Header", ROM0[$0100]

EntryPoint:
    nop
    jp Init
    ; Make space for ROM header
    ds $0150 - @, $00

