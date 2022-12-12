# FROM n0madic/alpine-gcc:8.4.0 AS build
FROM alpine:3.10 AS build

LABEL maintainer "tindy.it@gmail.com"

ARG SHA=""

RUN mkdir -p /tmp && echo  $'\n\
    #!/bin/bash\n\
    set -x\n\
    python3 -m pip install --upgrade pip\n\
    PIP_ONLY_BINARY=cmake python3 -m pip install cmake || true\n\
    hash cmake 2>/dev/null || {\n\
        echo "Build CMake from source ..."\n\
        cd /tmp\n\
        git clone -b \"v3.25.1\" --single-branch --depth 1 https://github.com/Kitware/CMake.git CMake\n\
        cd CMake\n\
        ./bootstrap --prefix=/usr/local\n\
        make -j$(nproc)\n\
        make install\n\
        cd ..\n\
        rm -rf CMake\n\
    }\n\
    cmake --version\n'\
  > /tmp/install_cmake.sh

RUN apk add --no-cache --virtual .build-deps bash git make gcc g++ libevent-dev pcre2-dev boost-dev icu-dev openssl-dev curl-dev python3 ninja && \
    bash /tmp/install_cmake.sh

WORKDIR /app

COPY . .

RUN mkdir build && cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. && \
    cmake --build . -j $(nproc)

FROM alpine:3.10 AS runtime

RUN apk add --no-cache boost libevent icu pcre2 libcurl

# set entry
WORKDIR /base

COPY --from=build /app/build/bin /base

RUN echo "/base" >> /etc/ld-musl-x86_64.path

CMD subconverter
