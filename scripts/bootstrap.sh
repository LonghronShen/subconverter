#!/bin/bash

set -x

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

pip3 install cmake cmake_format

apt update
apt install -y libboost-all-dev gcc-8 g++-8 g++-8-multilib
