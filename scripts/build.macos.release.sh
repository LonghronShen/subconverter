#!/bin/bash

set -xe

brew install libevent zlib pcre2 pkgconfig openssl boost icu4c
brew link --force openssl boost pcre2 libevent icu4c

bash ./build.sh
