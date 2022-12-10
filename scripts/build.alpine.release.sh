#!/bin/bash

set -xe

ALPINE_VER="$(cat /etc/os-release | grep VERSION | cut -d = -f 2)"

apk add --no-cache --virtual .build-deps git gcc g++ libevent-dev pcre2-dev boost-dev icu-dev openssl-dev curl-dev python3 ninja && \
    python3 -m pip install --upgrade pip && python3 -m pip install cmake

bash ./build.sh
