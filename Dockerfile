FROM n0madic/alpine-gcc:8.4.0 AS build

LABEL maintainer "tindy.it@gmail.com"

ARG THREADS="4"
ARG SHA=""

RUN apk add --no-cache --virtual .build-deps libevent-dev pcre2-dev boost-dev icu-dev openssl-dev python3 ninja && \
    python3 -m pip install --upgrade pip && python3 -m pip install cmake

WORKDIR /app

COPY . .

RUN mkdir build && cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. && \
    cmake --build . -j $THREADS

FROM alpine:3.16 AS runtime

RUN apk add --no-cache boost libevent icu pcre2

# set entry
WORKDIR /base

COPY --from=build /app/base /
COPY --from=build /app/build/bin .

RUN echo "/base" >> /etc/ld-musl-x86_64.path

CMD subconverter
