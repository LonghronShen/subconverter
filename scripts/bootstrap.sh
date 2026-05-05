#!/bin/bash

set -x

install_ubuntu_apt() {
    if ! command -v apt >/dev/null 2>&1; then
        echo "apt is required on Ubuntu/Linux"
        exit 1
    fi

    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root for Ubuntu apt bootstrap"
        exit 1
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
}

install_macos_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required on macOS"
        exit 1
    fi

    brew install libevent zlib pcre2 pkgconfig openssl boost icu4c ninja
    brew link --force openssl boost pcre2 libevent icu4c
}

case "$(uname -s)" in
    Darwin)
        install_macos_brew
        ;;
    Linux)
        install_ubuntu_apt
        ;;
    *)
        echo "Unsupported platform: $(uname -s)"
        exit 1
        ;;
esac
