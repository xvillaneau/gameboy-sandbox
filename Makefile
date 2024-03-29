.PHONY: all clean

all: bouncing-ball.gb audio.gb

clean:
	find . \( -name '*.o' -o -name '*.gb' -o -name '*.sym' -o -name '*.2bpp' \) -delete

audio.o: audio.asm
	rgbasm -o $@ $<

bouncing-ball.o: bouncing-ball.asm Ball_8x8.2bpp Ball_16x8.2bpp
	rgbasm -o $@ $<

%.gb: %.o
	rgblink -t -n $*.sym -o $@ $<
	rgbfix -v -p 0 $@

%.2bpp: %.png
	rgbgfx -h -o $@ $<

