#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="ppsspp-tinker"
rp_module_desc="PlayStation Portable emulator PPSSPP"
rp_module_help="ROM Extensions: .iso .pbp .cso\n\nCopy your PlayStation Portable roms to $romdir/psp"
rp_module_licence="GPL2 https://raw.githubusercontent.com/hrydgard/ppsspp/master/LICENSE.TXT"
rp_module_section="opt"
rp_module_flags="tinker"

function depends_ppsspp-tinker() {
    local depends=(cmake libsdl2-dev libzip-dev)
    getDepends "${depends[@]}"
}

function sources_ppsspp-tinker() {
    gitPullOrClone "$md_build/ppsspp" https://github.com/hrydgard/ppsspp.git \
                                      "PPSSPP_TINKER_BRANCH" \
                                      "PPSSPP_TINKER_COMMIT"

    cd ppsspp

    # remove the lines that trigger the ffmpeg build script functions - we will just use the variables from it
    sed -i "/^build_ARMv6$/,$ d" ffmpeg/linux_arm.sh
}

function build_ffmpeg_ppsspp() {
    cd "$1"

    local MODULES
    local VIDEO_DECODERS
    local AUDIO_DECODERS
    local VIDEO_ENCODERS
    local AUDIO_ENCODERS
    local DEMUXERS
    local MUXERS
    local PARSERS
    local GENERAL
    local OPTS # used by older lr-ppsspp fork

    # get the ffmpeg configure variables from the ppsspp ffmpeg distributed script
    source linux_arm.sh

    # linux_arm.sh has set -e which we need to switch off
    set +e

    ./configure \
        --prefix="./linux/armv7" \
        --extra-cflags="-fasm -Wno-psabi -fno-short-enums -fno-strict-aliasing -finline-limit=300" \
        --disable-shared \
        --enable-static \
        --enable-zlib \
        --enable-pic \
        --disable-everything \
        ${MODULES} \
        ${VIDEO_DECODERS} \
        ${AUDIO_DECODERS} \
        ${VIDEO_ENCODERS} \
        ${AUDIO_ENCODERS} \
        ${DEMUXERS} \
        ${MUXERS} \
        ${PARSERS}

    make clean
    make install
}

function build_ppsspp-tinker() {
    # build ffmpeg
    build_ffmpeg_ppsspp "$md_build/ppsspp/ffmpeg"

    # build ppsspp
    cd "$md_build/ppsspp"
    rm -rf CMakeCache.txt CMakeFiles

    cmake -DCMAKE_TOOLCHAIN_FILE="$md_data/tinkerboard.cmake" .
    make clean
    make -j4

    md_ret_require="$md_build/ppsspp/PPSSPPSDL"
}

function install_ppsspp-tinker() {
    md_ret_files=(
        'ppsspp/assets'
        'ppsspp/PPSSPPSDL'
    )
}

function configure_ppsspp-tinker() {
    mkRomDir "psp"

    # Copy startup script to install dir

    cp "$md_data/ppsspp.sh" "$md_inst/"

    moveConfigDir "$home/.config/ppsspp" "$md_conf_root/psp"
    mkUserDir "$md_conf_root/psp/PSP"
    ln -snf "$romdir/psp" "$md_conf_root/psp/PSP/GAME"

    addEmulator 1 "$md_id" "psp" "$md_inst/ppsspp.sh %ROM%"
    addSystem "psp"
}
