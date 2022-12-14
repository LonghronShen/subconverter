#!/bin/bash

set -xe

bash ./build.sh

cd ../build/bin
objdump -p ./subconverter.exe
