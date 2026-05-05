#!/bin/bash

set -xe

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export THREADS="$(nproc)"
export SHA="$(git rev-parse HEAD)"

case "$TOOLCHAIN_KIND" in
    cross)
        TOOLCHAIN_FILE="/opt/cmake-toolchain/cross-toolchain.cmake"
        # Runtime DLLs for dynamically-linked cross-compiled binaries.
        CROSS="${CROSS_PREFIX:-/opt/cross-toolchain}"
        RUNTIME_DLL_DIR="$CROSS/i686-w64-mingw32/lib"
        ;;
    native)
        TOOLCHAIN_FILE="/opt/cmake-toolchain/native-toolchain.cmake"
        NATIVE="${NATIVE_PREFIX:-/opt/native-toolset}"
        RUNTIME_DLL_DIR="$NATIVE/i686-w64-mingw32/lib"
        ;;
    *)
        echo "Using Host toolchain (no CMake toolchain file)"
        TOOLCHAIN_FILE=""
        ;;
esac

cd "$SCRIPTPATH/.."

mkdir -p build

pushd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" ..
cmake --build . -j "$THREADS"
pushd bin
chmod +rx subconverter
chmod +r ./*
popd
popd

cp -r ./build/bin subconverter
