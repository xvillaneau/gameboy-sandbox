.PHONY: all clean

all: bouncing-ball.gb

clean:
	find . \( -name '*.o' -o -name '*.gb' -o -name '*.sym' \) -delete

%.o: %.asm
	rgbasm -o $@ $<

%.gb: %.o
	rgblink -t -n $*.sym -o $@ $<
	rgbfix -v -p 0 $@

