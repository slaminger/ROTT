#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/../.."
LIB_DIR="$INSTALLER_DIR/lib"


MODULE_DEST="$1/scriptmodules/emulators/ppsspp-tinker.sh"
MODULE_DATA_DIR="$1/scriptmodules/emulators/ppsspp-tinker"


if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

PPSSPP_TINKER_BRANCH="master"
PPSSPP_TINKER_COMMIT=""

if [ -f "$INSTALLER_DIR/installer.cfg" ]; then
    source "$INSTALLER_DIR/installer.cfg"
fi

source "$LIB_DIR/read_params.sh"

echo "============================="
echo "Applying full-ppsspp-patch"
echo "============================="

set -e
set -x

mkdir -p "$MODULE_DATA_DIR"

cp "$SCRIPTPATH/data/ppsspp-tinker.sh" "$MODULE_DEST"

sed -i "s|PPSSPP_TINKER_BRANCH|$PPSSPP_TINKER_BRANCH|
        s|PPSSPP_TINKER_COMMIT|$PPSSPP_TINKER_COMMIT|" "$MODULE_DEST"

cp "$SCRIPTPATH/data/ppsspp.sh" "$MODULE_DATA_DIR"
cp "$SCRIPTPATH/data/tinkerboard.cmake" "$MODULE_DATA_DIR"

set +x
set +e

echo "=============="
echo "Patch Applied."
echo "=============="
