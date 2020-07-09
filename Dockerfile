FROM rgbds:v0.4.0

RUN apk add --update \
      build-base

VOLUME ["/source"]
WORKDIR /source

CMD make clean all
