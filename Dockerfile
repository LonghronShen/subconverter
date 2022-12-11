# FROM n0madic/alpine-gcc:8.4.0 AS build
FROM alpine:3.10 AS build

LABEL maintainer "tindy.it@gmail.com"

ARG THREADS="4"
ARG SHA=""

RUN apk add --no-cache --virtual .build-deps git make gcc g++ libevent-dev pcre2-dev boost-dev icu-dev openssl-dev curl-dev python3 Ninja

RUN echo "Build CMake from source ..." && \
    mkdir -p /tmp && \
    cd /tmp && \
    git clone --depth 1 --branch v3.25.1 https://github.com/Kitware/CMake.git && \
    cd CMake && \
    ./boostrap.sh --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf CMake

WORKDIR /app

COPY . .

RUN mkdir build && cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. && \
    cmake --build . -j $THREADS

FROM alpine:3.10 AS runtime

RUN apk add --no-cache boost libevent icu pcre2 libcurl

# set entry
WORKDIR /base

COPY --from=build /app/subconverter /base

RUN echo "/base" >> /etc/ld-musl-x86_64.path

CMD subconverter
