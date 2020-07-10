# Most of this was copied from RGBDS' Dockerfile
#   https://github.com/rednex/rgbds
#
# Original License:
#   Copyright (c) 2018-2019, Phil Smith and RGBDS contributors.
#   Released under the MIT License

# Stage 1: download RGBDS code and build it
FROM alpine:latest
RUN apk add --update build-base byacc flex libpng-dev

ADD https://github.com/rednex/rgbds/archive/v0.4.0.tar.gz /
RUN tar -x -z -f v0.4.0.tar.gz
RUN mv rgbds-0.4.0 rgbds

WORKDIR /rgbds
RUN make Q='' all

# Stage 2: Take the RGBDS binaries, make minimal image
FROM alpine:latest
RUN apk add --update make libpng

COPY --from=0 \
    /rgbds/rgbasm /rgbds/rgbfix /rgbds/rgblink /rgbds/rgbgfx \
    /bin/

VOLUME ["/source"]
WORKDIR /source

CMD /usr/bin/make clean all
