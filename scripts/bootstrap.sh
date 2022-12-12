#!/bin/bash

set -x

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

apt update
apt install -y git build-essential gcc-8 g++-8 libboost-all-dev python3-pip libevent-dev libcurl4-openssl-dev libpcre2-dev ninja-build pkg-config

python3 -m pip install --upgrade pip
PIP_ONLY_BINARY=cmake python3 -m pip install cmake || true

hash cmake 2>/dev/null || {
    echo "Build CMake from source ..."
    cd /tmp
    git clone -b 'v3.25.1' --single-branch --depth 1 https://github.com/Kitware/CMake.git CMake
    cd CMake
    ./bootstrap --prefix=/usr/local
    make -j$(nproc)
    make install
    cd ..
    rm -rf CMake
}

cmake --version

curl -sSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash /dev/stdin -b /usr/local/bin
