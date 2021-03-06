#!/bin/bash

set -e

source bin/version.sh

COUNTRIES="US EU433 EU865 CN JP ANZ KR"
#COUNTRIES=US
#COUNTRIES=CN

BOARDS_ESP32="tlora-v2 tlora-v1 tlora-v2-1-1.6 tbeam heltec tbeam0.7"

# FIXME note nrf52840dk build is for some reason only generating a BIN file but not a HEX file nrf52840dk-geeksville is fine
BOARDS_NRF52="lora-relay-v1"
BOARDS="$BOARDS_ESP32 $BOARDS_NRF52"
#BOARDS=tbeam

OUTDIR=release/latest

# We keep all old builds (and their map files in the archive dir)
ARCHIVEDIR=release/archive 

rm -f $OUTDIR/firmware*

mkdir -p $OUTDIR/bins $OUTDIR/elfs
rm -f $OUTDIR/bins/*

# build the named environment and copy the bins to the release directory
function do_build {
    echo "Building for $BOARD with $PLATFORMIO_BUILD_FLAGS"
    rm -f .pio/build/$BOARD/firmware.*

    # The shell vars the build tool expects to find
    export HW_VERSION="1.0-$COUNTRY"
    export APP_VERSION=$VERSION
    export COUNTRY

    pio run --jobs 4 --environment $BOARD # -v
    SRCELF=.pio/build/$BOARD/firmware.elf
    cp $SRCELF $OUTDIR/elfs/firmware-$BOARD-$COUNTRY-$VERSION.elf
}

# Make sure our submodules are current
git submodule update 

# Important to pull latest version of libs into all device flavors, otherwise some devices might be stale
platformio lib update 

for COUNTRY in $COUNTRIES; do 
    for BOARD in $BOARDS; do
        do_build $BOARD
    done

    echo "Copying ESP32 bin files"
    for BOARD in $BOARDS_ESP32; do
        SRCBIN=.pio/build/$BOARD/firmware.bin
        cp $SRCBIN $OUTDIR/bins/firmware-$BOARD-$COUNTRY-$VERSION.bin
    done

    echo "Generating NRF52 uf2 files"
    for BOARD in $BOARDS_NRF52; do
        SRCHEX=.pio/build/$BOARD/firmware.hex
        bin/uf2conv.py $SRCHEX -c -o $OUTDIR/bins/firmware-$BOARD-$COUNTRY-$VERSION.uf2 -f 0xADA52840
    done
done

# keep the bins in archive also
cp $OUTDIR/bins/firmware* $OUTDIR/elfs/firmware* $ARCHIVEDIR

cat >$OUTDIR/curfirmwareversion.xml <<XML
<?xml version="1.0" encoding="utf-8"?>

<!-- This file is kept in source control because it reflects the last stable
release.  It is used by the android app for forcing software updates.  Do not edit.
Generated by bin/buildall.sh -->

<resources>
    <string name="cur_firmware_version">$VERSION</string>
</resources>
XML

rm -f $ARCHIVEDIR/firmware-$VERSION.zip
zip --junk-paths $ARCHIVEDIR/firmware-$VERSION.zip $OUTDIR/bins/firmware-*-$VERSION.* images/system-info.bin bin/device-install.sh bin/device-update.sh

echo BUILT ALL
