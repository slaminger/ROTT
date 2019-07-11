#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="reicast-latest-tinker"
rp_module_desc="Dreamcast emulator Reicast"
rp_module_help="ROM Extensions: .cdi .gdi\n\nCopy your Dreamcast roms to $romdir/dreamcast\n\nCopy the required BIOS files dc_boot.bin and dc_flash.bin to $biosdir/dc"
rp_module_licence="GPL2 https://raw.githubusercontent.com/reicast/reicast-emulator/master/LICENSE"
rp_module_section="opt"
rp_module_flags="tinker"

function depends_reicast-latest-tinker() {
    local depends=(libsdl2-dev python-dev python-pip alsa-oss python-setuptools libevdev-dev)
    getDepends "${depends[@]}"
    pip install evdev
}

function sources_reicast-latest-tinker() {
    gitPullOrClone "$md_build" https://github.com/reicast/reicast-emulator.git \
                               "REICAST_LATEST_TINKER_BRANCH" \
                               "REICAST_LATEST_TINKER_COMMIT"

    applyPatch "$md_data/tinker-kms-makefile.patch"
}

function build_reicast-latest-tinker() {
    # Stop SDL input from being initialized
    # it conflicts with evdev input and causes
    # weird input glitches

    sed -i 's|input_sdl_init();||; s|input_sdl_handle(port);||' core/linux-dist/main.cpp

    cd shell/linux
    make platform=tinker-kms clean
    make platform=tinker-kms
    md_ret_require="$md_build/shell/linux/reicast.elf"
}

function install_reicast-latest-tinker() {
    cd shell/linux

    make platform=tinker-kms PREFIX="$md_inst" install

    md_ret_files=(
        'LICENSE'
        'README.md'
    )
}

function configure_reicast-latest-tinker() {
    # copy hotkey remapping start script
    cp "$md_data/../reicast/reicast.sh" "$md_inst/bin/"

    patch "$md_inst/bin/reicast.sh" "$md_data/start-reicast-tinker.patch" || exit 1

    chmod +x "$md_inst/bin/reicast.sh"

    mkRomDir "dreamcast"

    # move any old configs to the new location
    moveConfigDir "$home/.reicast" "$md_conf_root/dreamcast/"

    # Create home VMU, cfg, and data folders. Copy dc_boot.bin and dc_flash.bin to the ~/.reicast/data/ folder.
    mkdir -p "$md_conf_root/dreamcast/"{data,mappings}

    # symlink bios
    mkUserDir "$biosdir/dc"
    ln -sf "$biosdir/dc/"{dc_boot.bin,dc_flash.bin} "$md_conf_root/dreamcast/data"

    # copy default mappings
    cp "$md_inst/share/reicast/mappings/"*.cfg "$md_conf_root/dreamcast/mappings/"

    chown -R $user:$user "$md_conf_root/dreamcast"

    cat > "$romdir/dreamcast/+Start Reicast.sh" << _EOF_
#!/bin/bash
$md_inst/bin/reicast.sh
_EOF_
    chmod a+x "$romdir/dreamcast/+Start Reicast.sh"
    chown $user:$user "$romdir/dreamcast/+Start Reicast.sh"

    # remove old systemManager.cdi symlink
    rm -f "$romdir/dreamcast/systemManager.cdi"

    # add system
    # possible audio backends: alsa, oss, omx

    addEmulator 1 "$md_id" "dreamcast" "CON:$md_inst/bin/reicast.sh oss %ROM%"
    addSystem "dreamcast"

    addAutoConf reicast_input 1
}

function input_reicast-latest-tinker() {
    local temp_file="$(mktemp)"
    cd "$md_inst/bin"
    ./reicast-joyconfig -f "$temp_file" >/dev/tty
    iniConfig " = " "" "$temp_file"
    iniGet "mapping_name"
    local mapping_file="$configdir/dreamcast/mappings/controller_${ini_value// /}.cfg"
    mv "$temp_file" "$mapping_file"
    chown $user:$user "$mapping_file"
}

function gui_reicast-latest-tinker() {
    while true; do
        local options=(
            1 "Configure input devices for Reicast"
        )
        local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option" 22 76 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        case "$choice" in
            1)
                clear
                input_reicast-latest-tinker
                ;;
        esac
    done
}
