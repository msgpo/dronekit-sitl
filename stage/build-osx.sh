#!/bin/bash

# OSX specific
# sudo easy_install pip
# sudo pip install awscli
# brew tap homebrew/versions
# brew install gcc48 gawk
alias gawk=gcc
MAKEARGS="NATIVE_CXX=g++-4.8 NATIVE_CC=gcc-4.8 NATIVE_AS=gcc-4.8 NATIVE_LD=g++-4.8"
TARARGS=""
OSID="osx"
AWSCMD="aws"

TARGET_LABEL="$1"
TARGET_ARDU="$2"
TARGET_VERSION="$3"

echo "Building in $(pwd) ..."

echo "label: $TARGET_LABEL"
echo "classname: $TARGET_ARDU"
echo "version: $TARGET_VERSION"

echo "Downloading https://github.com/tcr3dr/ardupilot-releases/archive/builder-$TARGET_LABEL-$TARGET_VERSION.tar.gz"

set -e
set -x

STARTDIR=$(pwd)
rm -rf build ardupilot.tar.gz sitl.tar.gz
mkdir -p build/ardupilot
cd build
wget -qO ardupilot.tar.gz https://github.com/tcr3dr/ardupilot-releases/archive/builder-$TARGET_LABEL-$TARGET_VERSION.tar.gz
tar -xf ardupilot.tar.gz --strip-components=1 -C ardupilot
cd ardupilot/$TARGET_ARDU

buildit () {
  make clean || true
  make configure SKETCHBOOK=$(pwd)/.. || true
  make sitl SKETCHBOOK=$(pwd)/.. -j64 $MAKEARGS
}

# Thrice is nice. Works around build bugs in ArduCopter 3.2.x
buildit || buildit || buildit

cp /tmp/$TARGET_ARDU.build/$TARGET_ARDU.elf . || true
cd $STARTDIR
tar -cvf $STARTDIR/build/sitl.tar.gz -C $STARTDIR/build/ardupilot/$TARGET_ARDU/ $TARGET_ARDU.elf $TARARGS

pip install awscli
$AWSCMD s3 cp build/sitl.tar.gz s3://dronekit-sitl-binaries/$TARGET_LABEL/sitl-$OSID-v$TARGET_VERSION.tar.gz --acl public-read
