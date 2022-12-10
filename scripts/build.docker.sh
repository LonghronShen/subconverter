#!/bin/bash

set -ex

TAG="${1:-latest}"
SHA="$(git rev-parse --short HEAD)"

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd "$SCRIPTPATH"
docker build --build-arg SHA="$SHA" --build-arg THREADS="$(nproc)" -t "$TAG" ..