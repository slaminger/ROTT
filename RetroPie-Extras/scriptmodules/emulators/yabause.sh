#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="yabause"
rp_module_desc="Saturn emulator - Yabuase"
rp_module_help="ROM Extensions: .bin .iso .zip\n\nCopy your saturn roms to $romdir/saturn"
rp_module_licence="https://raw.githubusercontent.com/Yabause/yabause/master/README.md"
rp_module_section="exp"
rp_module_flags=""

function depends_yabause() {
    getDepends libsdl1.2-dev libboost-thread-dev libboost-system-dev libsdl-ttf2.0-dev libasound2-dev
}

function sources_yabause() {
    gitPullOrClone "$md_build" https://github.com/RetroPie-Expanded/yabause.git
}

function build_yabause() {
    cd yabause/mini18n
    cmake .	
    make
    make install
    md_ret_require="$md_build/yabause"
}

function install_yabause() {
    md_ret_files=(
        'changes.txt'
        'hardware.txt'
        'problems.txt'
        'readme.txt'
        'README.md'
        'yabause'
    )
}

function configure_yabause() {
    mkRomDir "saturn"

    setDispmanx "$md_id" 1

    addEmulator 0 "$md_id" "saturn" "$md_inst/yabause %ROM%"
    addSystem "saturn"
}
