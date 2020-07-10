.PHONY: all clean

all: hello-world.gb

clean:
	find . \( -name '*.o' -name '*.gb' \) -delete

%.o: %.rgbasm
	rgbasm -o $@ $<

%.gb: %.o
	rgblink -t -o $@ $<
	rgbfix -v -p 0 $@
