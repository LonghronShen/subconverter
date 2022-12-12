#!/bin/bash

set -xe

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export THREADS="$(nproc)"
export SHA="$(git rev-parse HEAD)"

cd "$SCRIPTPATH/.."

mkdir -p build

pushd build
cmake --compile-no-warning-as-error -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
cmake --build . -j $THREADS
pushd bin
chmod +rx subconverter
chmod +r ./*
popd
popd

cp -r ./build/bin subconverter
