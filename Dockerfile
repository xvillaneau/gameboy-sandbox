# Most of this was copied from RGBDS' Dockerfile
#   https://github.com/rednex/rgbds
#
# Original License:
#   Copyright (c) 2018-2019, Phil Smith and RGBDS contributors.
#   Released under the MIT License

# Stage 1: download RGBDS code and build it
FROM alpine:latest
RUN apk add --update bison build-base libpng-dev

ENV VERSION=0.5.1

ADD https://github.com/rednex/rgbds/archive/v${VERSION}.tar.gz /
RUN tar -x -z -f v${VERSION}.tar.gz
RUN mv rgbds-${VERSION} rgbds

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
