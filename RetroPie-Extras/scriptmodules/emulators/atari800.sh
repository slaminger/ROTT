#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="atari800"
rp_module_desc="Atari 8-bit/800/5200 emulator with added joystick support"
rp_module_help="ROM Extensions: .a52 .bas .bin .car .xex .atr .xfd .dcm .atr.gz .xfd.gz\n\nCopy your Atari800 games to $romdir/atari800\n\nCopy your Atari 5200 roms to $romdir/atari5200 You need to copy the Atari 800/5200 BIOS files (5200.ROM, ATARIBAS.ROM, ATARIOSB.ROM and ATARIXL.ROM) to the folder $biosdir and then on first launch configure it to scan that folder for roms (F1 -> Emulator Configuration -> System Rom Settings)"
rp_module_licence="GPL2 https://sourceforge.net/p/atari800/source/ci/master/tree/COPYING"
rp_module_section="exp"
rp_module_flags="!mali !kms"

function depends_atari800() {
    local depends=(libsdl1.2-dev autoconf zlib1g-dev libpng12-dev)
    isPlatform "rpi" && depends+=(libraspberrypi-dev)
    getDepends "${depends[@]}"
}

function sources_atari800() {
    gitPullOrClone "$md_build" https://github.com/futurechild/atari800-rpi.git
}

function build_atari800() {
    cd src
    autoreconf -v
    params=()
    isPlatform "rpi" && params+=(--target=rpi)
    ./configure --prefix="$md_inst" ${params[@]}
    make clean
    make
    md_ret_require="$md_build/src/atari800"
}

function install_atari800() {
    cd src
    make install
}

function configure_atari800() {
    mkRomDir "atari800"
    mkRomDir "atari5200"

    mkUserDir "$md_conf_root/atari800"

    # move old config if exists to new location
    if [[ -f "$md_conf_root/atari800.cfg" ]]; then
        mv "$md_conf_root/atari800.cfg" "$md_conf_root/atari800/atari800.cfg"
    fi
    moveConfigFile "$home/.atari800.cfg" "$md_conf_root/atari800/atari800.cfg"
    moveConfigFile "$home/.atari5200.cfg" "$md_conf_root/atari5200/atari5200.cfg"

    addEmulator 1 "atari800" "atari800" "$md_inst/bin/atari800 -config /home/pi/.atari800.cfg -800 %ROM%"
    addEmulator 1 "atari800" "atari5200" "$md_inst/bin/atari800 -config /home/pi/.atari5200.cfg -5200 -cart-type 4 -cart %ROM%"
    addSystem "atari800"
    addSystem "atari5200"
}
