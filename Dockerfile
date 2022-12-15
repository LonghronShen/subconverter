FROM longhronshens/alpine-cmake:latest AS build

LABEL maintainer "tindy.it@gmail.com"

ARG SHA=""

RUN apk add --no-cache libevent-dev pcre2-dev boost-dev icu-dev openssl-dev curl-dev

WORKDIR /app

COPY . .

RUN mkdir build && cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. && \
    cmake --build . -j $(nproc) && \
    cd bin && \
    rm ./*.a || true

FROM alpine:3.10 AS runtime

RUN apk add --no-cache boost libevent icu pcre2 libcurl libstdc++ libgcc

# set entry
WORKDIR /base

COPY --from=build /app/build/bin /base

EXPOSE 25500

CMD subconverter
