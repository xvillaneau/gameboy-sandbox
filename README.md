
# Game Boy Stuff

This is a small collection of very short Game Boy programs (calling those
"games" would be quite a stretch). I'm a beginner in Assembly programming,
so expect some roughness.

## Bouncing Ball

So far this is the only project here. It's just a ball bouncing around.

I started with "Hello World", then tried to make the message bounce around the
screen. After one weekend of poking around, I now have a small ball bouncing
more convincingly and that can be (somewhat) controlled.

Next steps:
- [x] Make proper sprite for the ball
- [x] Experiment with using larger sprites (16x16 px?)
- [ ] Implement 16-bit physics, make the game slower
- [ ] Implement drag & friction
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

## License

Copyright ©2020 Xavier Villaneau, distributed under the Mozilla Public License 2.0

Except the following files:
- `Dockerfile`: See description inside
- `hardware.inc`: See description inside

