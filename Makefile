.PHONY: all clean

all: bouncing-ball.gb

clean:
	find . \( -name '*.o' -o -name '*.gb' -o -name '*.sym' -o -name '*.2bpp' \) -delete

bouncing-ball.o: bouncing-ball.asm Ball_8x8.2bpp
	rgbasm -o $@ $<

%.gb: %.o
	rgblink -t -n $*.sym -o $@ $<
	rgbfix -v -p 0 $@

%.2bpp: %.png
	rgbgfx -h -o $@ $<

