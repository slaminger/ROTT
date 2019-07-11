#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/../.."
LIB_DIR="$INSTALLER_DIR/lib"


MODULE_DEST="$1/scriptmodules/admin/tinker-basic-install.sh"


if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

if [ -f "$INSTALLER_DIR/installer.cfg" ]; then
    source "$INSTALLER_DIR/installer.cfg"
fi

source "$LIB_DIR/read_params.sh"

echo "================================"
echo "Patching in tinker-basic-install"
echo "================================"

set -e
set -x

cp "$SCRIPTPATH/data/tinker-basic-install.sh" "$MODULE_DEST"

set +x
set +e

echo "=============="
echo "Patch Applied."
echo "=============="
