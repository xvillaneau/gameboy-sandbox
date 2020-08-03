
# Game Boy Stuff

This is a small collection of very short Game Boy programs (calling those
"games" would be quite a stretch). I'm a beginner in Assembly programming,
so expect some roughness.

## Bouncing Ball

So far this is the only project here. It's just a ball bouncing around.

I started with "Hello World", then tried to make the message bounce around the
screen. After one weekend of poking around, I now have a small ball bouncing
more convincingly and that loses its speed after a while.

Next steps:
- [x] Make proper sprite for the ball
- [x] Experiment with using larger sprites (16x16 px?)
- [x] Implement 16-bit physics, make the game slower
- [x] Implement drag & friction
- [x] Make rotation depend on collisions
- [ ] Implement proper controls
- [ ] Add sound effects
- [ ] Extend collisions detection to other objects

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

## Acknowledgements 

This was made possible thanks to:

- [ISSOtm's GB ASM Programming tutorial][issotm-gbasm],
- the [Rednex Game Boy Development System][rgbds-docs] (RGBDS),
- the [Pan Docs Game Boy technical reference][pandocs],
- [ChibiAkumas' GBZ80 cheatsheet][chibiakumas-gbz80],
- the [Pokémon Red and Blue disassembly][pret-pokered] project
  (for structural and build/make ideas),
- the [BGB Game Boy emulator][bgb],
- [Retro Game Mechanics Explained][rgme-yt] for the motivation to look into
  Game Boy programming in the first place.

[issotm-gbasm]: https://eldred.fr/gb-asm-tutorial/index.html
[rgbds-docs]: https://rednex.github.io/rgbds/
[pandocs]: https://gbdev.io/pandocs/
[chibiakumas-gbz80]: https://www.chibiakumas.com/z80/Gameboy.php
[pret-pokered]: https://github.com/pret/pokered
[bgb]: https://bgb.bircd.org/
[rgme-yt]: https://www.youtube.com/c/RetroGameMechanicsExplained

## License

Copyright ©2020 Xavier Villaneau, distributed under the Mozilla Public License 2.0

