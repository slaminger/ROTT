#!/usr/bin/env bash

ROM="$1"

rootdir="/opt/retropie"

"$rootdir/emulators/ppsspp-tinker/PPSSPPSDL" --fullscreen "$ROM"

sudo systemctl restart keyboard-setup
