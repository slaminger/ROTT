#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/../.."
LIB_DIR="$INSTALLER_DIR/lib"


MODULE_DEST="$1/scriptmodules/emulators/reicast-latest-tinker.sh"
MODULE_DATA_DIR="$1/scriptmodules/emulators/reicast-latest-tinker"


if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

REICAST_LATEST_TINKER_BRANCH="master"
REICAST_LATEST_TINKER_COMMIT=""

if [ -f "$INSTALLER_DIR/installer.cfg" ]; then
    source "$INSTALLER_DIR/installer.cfg"
fi

source "$LIB_DIR/read_params.sh"

echo "============================="
echo "Applying latest_reicast_patch"
echo "============================="

set -e
set -x

mkdir -p "$MODULE_DATA_DIR"

cp "$SCRIPTPATH/data/reicast-latest-tinker.sh" "$MODULE_DEST"

sed -i "s|REICAST_LATEST_TINKER_BRANCH|$REICAST_LATEST_TINKER_BRANCH|
        s|REICAST_LATEST_TINKER_COMMIT|$REICAST_LATEST_TINKER_COMMIT|" "$MODULE_DEST"

cp "$SCRIPTPATH/data/tinker-kms-makefile.patch" "$MODULE_DATA_DIR"
cp "$SCRIPTPATH/data/start-reicast-tinker.patch" "$MODULE_DATA_DIR"

set +x
set +e

echo "=============="
echo "Patch Applied."
echo "=============="
