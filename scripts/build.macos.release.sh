#!/bin/bash

set -xe

./bootstrap.sh

alias nproc="sysctl -n hw.logicalcpu"

./build.sh
