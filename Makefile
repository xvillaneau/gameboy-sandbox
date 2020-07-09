.PHONY: all clean

all: hello-world.gb

clean:
	find . -name '*.o' -delete
	rm -f hello-world.gb

main.o:
	rgbasm -o main.o main.rgbasm

hello-world.gb: main.o
	rgblink -o hello-world.gb main.o
	rgbfix -v -p 0 hello-world.gb
