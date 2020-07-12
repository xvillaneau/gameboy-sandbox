.PHONY: all clean

all: hello-world.gb bouncing-logo.gb

clean:
	find . \( -name '*.o' -name '*.gb' \) -delete

%.o: %.asm
	rgbasm -o $@ $<

%.gb: %.o
	rgblink -t -o $@ $<
	rgbfix -v -p 0 $@
