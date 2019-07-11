#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="mupen64plus"
rp_module_desc="N64 emulator MUPEN64Plus"
rp_module_help="ROM Extensions: .z64 .n64 .v64\n\nCopy your N64 roms to $romdir/n64"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mupen64plus/mupen64plus-core/master/LICENSES"
rp_module_section="main"
rp_module_flags="tinker"



function depends_mupen64plus() {
    local depends=(cmake libsamplerate0-dev libspeexdsp-dev libsdl2-dev libpng12-dev fonts-freefont-ttf libboost-all-dev)
    getDepends "${depends[@]}"
}

function sources_mupen64plus() {

    local repos=(
        "mupen64plus core MUPEN64PLUS_CORE_BRANCH MUPEN64PLUS_CORE_COMMIT"
        'mupen64plus ui-console MUPEN64PLUS_UI_CONSOLE_BRANCH MUPEN64PLUS_UI_CONSOLE_COMMIT'
        'mupen64plus audio-sdl MUPEN64PLUS_AUDIO_SDL_BRANCH MUPEN64PLUS_AUDIO_SDL_COMMIT'
        'mupen64plus input-sdl MUPEN64PLUS_INPUT_SDL_BRANCH MUPEN64PLUS_INPUT_SDL_COMMIT'
        'mupen64plus rsp-hle MUPEN64PLUS_RSP_HLE_BRANCH MUPEN64PLUS_RSP_HLE_COMMIT'
        'ricrpi video-gles2n64 RICRPI_VIDEO_GLES2N64_BRANCH RICRPI_VIDEO_GLES2N64_COMMIT'
        'mupen64plus video-glide64mk2 MUPEN64PLUS_VIDEO_GLIDE64MK2_BRANCH MUPEN64PLUS_VIDEO_GLIDE64MK2_COMMIT'
        'ricrpi video-gles2rice RICRPI_VIDEO_GLES2RICE_BRANCH RICRPI_VIDEO_GLES2RICE_COMMIT'
    )

    local repo
    local dir
    for repo in "${repos[@]}"; do
        repo=($repo)
        dir="$md_build/mupen64plus-${repo[1]}"
        gitPullOrClone "$dir" https://github.com/${repo[0]}/mupen64plus-${repo[1]} ${repo[2]} ${repo[3]}
    done
    gitPullOrClone "$md_build/GLideN64" https://github.com/gonetz/GLideN64.git \
                                        "GONETZ_GLIDEN64_BRANCH" \
                                        "GONETZ_GLIDEN64_COMMIT"

    # workaround for shader cache crash issue on Raspbian stretch. See: https://github.com/gonetz/GLideN64/issues/1665
    applyPatch "$md_data/0001-GLideN64-use-emplace.patch"

    local config_version=$(grep -oP '(?<=CONFIG_VERSION_CURRENT ).+?(?=U)' GLideN64/src/Config.h)
    echo "$config_version" > "$md_build/GLideN64_config_version.ini"
}

function build_mupen64plus() {
    rpSwap on 750

    local dir
    local params=("HOST_CPU=armv6" "USE_GLES=1" "NEON=1" "VFP_HARD=1" OPTFLAGS="-O3 -flto -ffast-math")
    for dir in *; do
        if [[ -f "$dir/projects/unix/Makefile" ]]; then
            [[ "$dir" == "mupen64plus-ui-console" ]] && params+=("COREDIR=$md_inst/lib/" "PLUGINDIR=$md_inst/lib/mupen64plus/")
            make -C "$dir/projects/unix" "${params[@]}" clean
            # MAKEFLAGS replace removes any distcc from path, as it segfaults with cross compiler and lto
            MAKEFLAGS="${MAKEFLAGS/\/usr\/lib\/distcc:/}" make -C "$dir/projects/unix" all "${params[@]}" OPTFLAGS="$CFLAGS -O3 -flto"
        fi
    done

    # build GLideN64
    "$md_build/GLideN64/src/getRevision.sh"
    pushd "$md_build/GLideN64/projects/cmake"

    params=("-DMUPENPLUSAPI=On" "-DVEC4_OPT=On" "-DUSE_SYSTEM_LIBS=On" "-DCRC_ARMV6=On" "-DNEON_OPT=On" "-DEGL=On")

    cmake "${params[@]}" ../../src/
    make
    popd

    rpSwap off
    md_ret_require=(
        'mupen64plus-ui-console/projects/unix/mupen64plus'
        'mupen64plus-core/projects/unix/libmupen64plus.so.2.0.0'
        'mupen64plus-audio-sdl/projects/unix/mupen64plus-audio-sdl.so'
        'mupen64plus-input-sdl/projects/unix/mupen64plus-input-sdl.so'
        'mupen64plus-rsp-hle/projects/unix/mupen64plus-rsp-hle.so'
        'GLideN64/projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so'
        'mupen64plus-video-gles2rice/projects/unix/mupen64plus-video-rice.so'
        'mupen64plus-video-gles2n64/projects/unix/mupen64plus-video-n64.so'
        'mupen64plus-video-glide64mk2/projects/unix/mupen64plus-video-glide64mk2.so'
    )
}

function install_mupen64plus() {
    for source in *; do
        if [[ -f "$source/projects/unix/Makefile" ]]; then
            # optflags is needed due to the fact the core seems to rebuild 2 files and relink during install stage most likely due to a buggy makefile
            local params=("HOST_CPU=armv6" "USE_GLES=1" "NEON=1" "VFP_HARD=1" OPTFLAGS="-O3 -flto -ffast-math")
            make -C "$source/projects/unix" PREFIX="$md_inst" OPTFLAGS="$CFLAGS -O3 -flto" "${params[@]}" install
        fi
    done
    cp "$md_build/GLideN64/ini/GLideN64.custom.ini" "$md_inst/share/mupen64plus/"
    cp "$md_build/GLideN64/projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so" "$md_inst/lib/mupen64plus/"
    cp "$md_build/GLideN64_config_version.ini" "$md_inst/share/mupen64plus/"
    # remove default InputAutoConfig.ini. inputconfigscript writes a clean file
    rm -f "$md_inst/share/mupen64plus/InputAutoCfg.ini"
}

function configure_mupen64plus() {
    addEmulator 0 "${md_id}-gles2n64" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-n64 %ROM%"
    addEmulator 0 "${md_id}-GLideN64" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-GLideN64 %ROM%"
    addEmulator 0 "${md_id}-glide64" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-glide64mk2 %ROM%"
    addEmulator 0 "${md_id}-gles2rice" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-rice %ROM%"
    addEmulator 0 "${md_id}-auto" "n64" "$md_inst/bin/mupen64plus.sh AUTO %ROM%"

    addSystem "n64"

    mkRomDir "n64"

    [[ "$md_mode" == "remove" ]] && return

    # copy hotkey remapping start script
    cp "$md_data/mupen64plus.sh" "$md_inst/bin/"

    patch "$md_inst/bin/mupen64plus.sh" "$md_data/tinker/start-mupen64plus-tinker.patch" || exit 1

    chmod +x "$md_inst/bin/mupen64plus.sh"

    mkUserDir "$md_conf_root/n64/"

    # Copy config files
    cp -v "$md_inst/share/mupen64plus/"{*.ini,font.ttf} "$md_conf_root/n64/"

    cp -v "$md_inst/share/mupen64plus/"*.conf "$md_conf_root/n64/"

    local config="$md_conf_root/n64/mupen64plus.cfg"
    local cmd="$md_inst/bin/mupen64plus --configdir $md_conf_root/n64 --datadir $md_conf_root/n64"

    # if the user has an existing mupen64plus config we back it up, generate a new configuration
    # copy that to rp-dist and put the original config back again. We then make any ini changes
    # on the rp-dist file. This preserves any user configs from modification and allows us to have
    # a default config for reference
    if [[ -f "$config" ]]; then
        mv "$config" "$config.user"
        su "$user" -c "$cmd"
        mv "$config" "$config.rp-dist"
        mv "$config.user" "$config"
        config+=".rp-dist"
    else
        su "$user" -c "$cmd"
    fi

    # GLideN64 settings
    iniConfig " = " "" "$config"

    # Create GlideN64 section in .cfg
    if ! grep -q "\[Video-GLideN64\]" "$config"; then
        echo "[Video-GLideN64]" >> "$config"
    fi

    # Settings version. Don't touch it.
    iniSet "configVersion" "17"
    # Bilinear filtering mode (0=N64 3point, 1=standard)
    iniSet "bilinearMode" "1"
    # Size of texture cache in megabytes. Good value is VRAM*3/4
    iniSet "CacheSize" "50"
    # Disable FB emulation until visual issues are sorted out
    iniSet "EnableFBEmulation" "True"
    # Use native res
    iniSet "UseNativeResolutionFactor" "1"
    # Enable legacy blending
    iniSet "EnableLegacyBlending" "True"
    # Enable FPS Counter. Fixes zelda depth issue
    iniSet "ShowFPS " "True"
    iniSet "fontSize" "14"
    iniSet "fontColor" "1F1F1F"


    addAutoConf mupen64plus_compatibility_check 1
    addAutoConf mupen64plus_audio 1
    addAutoConf mupen64plus_hotkeys 1
    addAutoConf mupen64plus_texture_packs 1
    addAutoConf mupen64plus_auto_ini_resolution 1

    chown -R $user:$user "$md_conf_root/n64"
}
