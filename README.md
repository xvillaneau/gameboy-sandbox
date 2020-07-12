
# Game Boy Stuff

This is a small collection of very short Game Boy programs (calling those
"games" would be quite a stretch). I'm a beginner in Assembly programming,
so expect some roughness.

## Usage

The ROMs in this project are built using RGBDS, you will need to install it:
https://github.com/rednex/rgbds

Once that's done, run:

    make clean all

Alternatively, the `Dockerfile` in here can do it for you. Assuming that you
have Docker installed, you can do:

    docker build -t 'gameboy_sandbox:latest' .
    docker run --rm --name 'gameboy_sandbox' \
        -v <project directory>:/source \
        gameboy_sandbox:latest

## License

Copyright ©2020 Xavier Villaneau, distributed under the Mozilla Public License 2.0

Except the following files:
- `Dockerfile`: See description inside
- `hardware.inc`: See description inside
- `hello-world.asm`: From https://eldred.fr/gb-asm-tutorial/hello-world.html
- `font.chr`: Ditto.

