#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/../.."
LIB_DIR="$INSTALLER_DIR/lib"

if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

MODULE_DIR="$1/scriptmodules/emulators"
MODULE_DEST="$MODULE_DIR/mupen64plus-tinker.sh"
MODULE_DATA_DIR="$MODULE_DIR/mupen64plus/tinker"

# Default Mupen module versions

MUPEN64PLUS_CORE_BRANCH="master"
MUPEN64PLUS_CORE_COMMIT=""

MUPEN64PLUS_UI_CONSOLE_BRANCH="master"
MUPEN64PLUS_UI_CONSOLE_COMMIT=""

MUPEN64PLUS_AUDIO_SDL_BRANCH="master"
MUPEN64PLUS_AUDIO_SDL_COMMIT=""

MUPEN64PLUS_INPUT_SDL_BRANCH="master"
MUPEN64PLUS_INPUT_SDL_COMMIT=""

MUPEN64PLUS_RSP_HLE_BRANCH="master"
MUPEN64PLUS_RSP_HLE_COMMIT=""

MUPEN64PLUS_VIDEO_GLIDE64MK2_BRANCH="master"
MUPEN64PLUS_VIDEO_GLIDE64MK2_COMMIT=""

RICRPI_VIDEO_GLES2RICE_BRANCH="pandora-backport"
RICRPI_VIDEO_GLES2RICE_COMMIT=""

RICRPI_VIDEO_GLES2N64_BRANCH="master"
RICRPI_VIDEO_GLES2N64_COMMIT=""

GONETZ_GLIDEN64_BRANCH="master"
GONETZ_GLIDEN64_COMMIT=""

# ===


if [ -f "$INSTALLER_DIR/installer.cfg" ]; then
    source "$INSTALLER_DIR/installer.cfg"
fi

source "$LIB_DIR/read_params.sh"

if grep 'rp_module_flags\s*=\s*".*!kms.*"' "$MODULE_DIR/mupen64plus.sh"; then
    # Only use this patch if the existing script module does not support kms

    echo "==============================="
    echo "Applying full-mupen64plus-patch"
    echo "==============================="

    set -e
    set -x

    mkdir -p "$MODULE_DATA_DIR"

    cp "$SCRIPTPATH/data/mupen64plus-tinker.sh" $MODULE_DEST

    sed -i "s|MUPEN64PLUS_CORE_BRANCH|$MUPEN64PLUS_CORE_BRANCH|
            s|MUPEN64PLUS_CORE_COMMIT|$MUPEN64PLUS_CORE_COMMIT|" "$MODULE_DEST"

    sed -i "s|MUPEN64PLUS_UI_CONSOLE_BRANCH|$MUPEN64PLUS_UI_CONSOLE_BRANCH|
            s|MUPEN64PLUS_UI_CONSOLE_COMMIT|$MUPEN64PLUS_UI_CONSOLE_COMMIT|" "$MODULE_DEST"

    sed -i "s|MUPEN64PLUS_AUDIO_SDL_BRANCH|$MUPEN64PLUS_AUDIO_SDL_BRANCH|
            s|MUPEN64PLUS_AUDIO_SDL_COMMIT|$MUPEN64PLUS_AUDIO_SDL_COMMIT|" "$MODULE_DEST"

    sed -i "s|MUPEN64PLUS_INPUT_SDL_BRANCH|$MUPEN64PLUS_INPUT_SDL_BRANCH|
            s|MUPEN64PLUS_INPUT_SDL_COMMIT|$MUPEN64PLUS_INPUT_SDL_COMMIT|" "$MODULE_DEST"

    sed -i "s|MUPEN64PLUS_RSP_HLE_BRANCH|$MUPEN64PLUS_RSP_HLE_BRANCH|
            s|MUPEN64PLUS_RSP_HLE_COMMIT|$MUPEN64PLUS_RSP_HLE_COMMIT|" "$MODULE_DEST"

    sed -i "s|MUPEN64PLUS_VIDEO_GLIDE64MK2_BRANCH|$MUPEN64PLUS_VIDEO_GLIDE64MK2_BRANCH|
            s|MUPEN64PLUS_VIDEO_GLIDE64MK2_COMMIT|$MUPEN64PLUS_VIDEO_GLIDE64MK2_COMMIT|" "$MODULE_DEST"

    sed -i "s|RICRPI_VIDEO_GLES2RICE_BRANCH|$RICRPI_VIDEO_GLES2RICE_BRANCH|
            s|RICRPI_VIDEO_GLES2RICE_COMMIT|$RICRPI_VIDEO_GLES2RICE_COMMIT|" "$MODULE_DEST"

    sed -i "s|RICRPI_VIDEO_GLES2N64_BRANCH|$RICRPI_VIDEO_GLES2N64_BRANCH|
            s|RICRPI_VIDEO_GLES2N64_COMMIT|$RICRPI_VIDEO_GLES2N64_COMMIT|" "$MODULE_DEST"

    sed -i "s|GONETZ_GLIDEN64_BRANCH|$GONETZ_GLIDEN64_BRANCH|
            s|GONETZ_GLIDEN64_COMMIT|$GONETZ_GLIDEN64_COMMIT|" "$MODULE_DEST"


    cp "$SCRIPTPATH/data/start-mupen64plus-tinker.patch" "$MODULE_DATA_DIR"

    set +x
    set +e

    echo "=============="
    echo "Patch Applied."
    echo "=============="

else
    echo "===================================="
    echo "full-mupen64plus-patch not required."
    echo "===================================="
fi
