#!/bin/bash

set -xe

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"


# Prefer nproc when available, but fall back to sysctl on platforms like macOS.
if command -v nproc >/dev/null 2>&1; then
    export THREADS="$(nproc)"
elif command -v sysctl >/dev/null 2>&1; then
    export THREADS="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)"
else
    export THREADS="1"
fi

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
        ;;
esac

cd "$SCRIPTPATH/.."

mkdir -p build

pushd build

if [[ -n "$TOOLCHAIN_FILE" ]]; then
    cmake -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" ..
else
    cmake -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
fi

cmake --build . -j "$THREADS"
pushd bin
# Windows cross/native toolchains generate subconverter.exe, while host builds may generate subconverter.
if [[ -f subconverter ]]; then
    chmod +rx subconverter
elif [[ -f subconverter.exe ]]; then
    chmod +rx subconverter.exe
fi
chmod +r ./*
popd
popd

cp -r ./build/bin subconverter
