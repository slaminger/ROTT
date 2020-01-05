#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

TIMESTAMP=$(date "+%Y%m%d_%H%M")
LOG_FILE="$SCRIPTPATH/install_$TIMESTAMP.log"

PACKAGES_DIR="$SCRIPTPATH/packages"
PATCHES_DIR="$SCRIPTPATH/patches"
ETC_DIR="$SCRIPTPATH/etc"

RETROPIE_SETUP_DIR=$(realpath "$SCRIPTPATH/../RetroPie-Setup")


if [[ "$@" =~ "-h" || $@ =~ "--help" ]]; then

    echo "\
Tinker RetroPie  Installer

 Select RetroPie-Setup branch/tag (default is master):
 
  RETROPIE_BRANCH=(RetroPie-Setup git branch)

  git --branch option ...

 e.g:

  ./installer.sh RETROPIE_BRANCH=master

  ./installer.sh RETROPIE_BRANCH=4.4

 =======

 Select a RetroPie-Setup commit (default is latest):

  RETROPIE_COMMIT=(commit hash)

 e.g:

  ./installer.sh RETROPIE_COMMIT=31ffdb0

 =======

 Auto start RetroPie basic install (No GUI, default no):

  RETROPIE_BASIC_INSTALL=(1,0,yes,no)

 e.g:

  ./installer.sh RETROPIE_BASIC_INSTALL=1

 =======

 Automaticly install additional modules (No GUI, default none):

  RETROPIE_INSTALL_MODULES=\"modules1 modules2 modules3\"

 e.g:

  RETROPIE_INSTALL_MODULES=\"xpad reicast-latest-tinker\"

"
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

if [ -f "$SCRIPTPATH/installer.cfg" ]; then
    source "$SCRIPTPATH/installer.cfg"
fi

source "$SCRIPTPATH/lib/read_params.sh"

RETROPIE_BRANCH=${RETROPIE_BRANCH:-"master"}
RETROPIE_COMMIT=${RETROPIE_COMMIT:-""}
RETROPIE_BASIC_INSTALL=${RETROPIE_BASIC_INSTALL:-0}
RETROPIE_INSTALL_MODULES=${RETROPIE_INSTALL_MODULES:-""}


if [[ "${RETROPIE_BASIC_INSTALL,,}" == n* || "$RETROPIE_BASIC_INSTALL" == "0" ]]; then
    RETROPIE_BASIC_INSTALL=0
else
    RETROPIE_BASIC_INSTALL=1
fi


pushd() {
    command pushd "$@" >/dev/null
}

popd() {
    command popd "$@" >/dev/null
}

(

    # Install all package/*.deb files which have not been installed

    DEBS_TO_INSTALL=()

    for i in "$PACKAGES_DIR"/*; do
        pkg_name=$(dpkg --info $i | sed -n 's/Package:\s*\(.*\)/\1/p')
        if [ $(dpkg-query -W -f='${Status}' $pkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            DEBS_TO_INSTALL+=("$i")
        fi
    done

    if ! [ ${#DEBS_TO_INSTALL[@]} -eq 0 ]; then

        echo "==========================="
        echo "Installing prebuilt debs..."
        echo "==========================="

        dpkg -i "${DEBS_TO_INSTALL[@]}"

        echo "======================================="
        echo "Installing prebuilt deb dependencies..."
        echo "======================================="

        apt-get install -y -f || exit 1
    fi

    echo "=========================="
    echo "Installing dev packages..."
    echo "=========================="

    set -e

    apt-get install -y libavdevice-dev libxkbcommon-dev libsm-dev libffi-dev libexpat1-dev libxml2-dev zlib1g-dev

    # The packages below are required specifically to build SDL2-2.0.8

    apt-get install -y libgl1-mesa-dev libx11-dev libxcursor-dev libxext-dev libxi-dev \
        libxinerama-dev libxrandr-dev libxss-dev libxxf86vm-dev 

    set +e

    echo "========================="
    echo "Installing build tools..."
    echo "========================="

    apt-get install -y libtool pkg-config || exit 1

    echo "========================"
    echo "Installing pulseaudio..."
    echo "========================"

    apt-get install -y pulseaudio pulseaudio-utils || exit 1

    echo "======================="
    echo "Installing bluetooth..."
    echo "======================="

    apt-get install -y bluetooth || exit 1

    echo "======================================"
    echo "Creating GLESv1 shared object symlinks"
    echo "======================================"

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1_CM.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1_CM.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1_CM.so.1.0.0
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1.so.1.0.0

    echo "======================================"
    echo "Creating GLESv2 shared object symlinks"
    echo "======================================"

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2_CM.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2_CM.so.2
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2_CM.so.2.0.0
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0

    echo "==================================="
    echo "Creating EGL shared object symlinks"
    echo "==================================="

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libEGL.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0

    echo "==================================="
    echo "Creating gbm shared object symlinks"
    echo "==================================="

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.1.0.0
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.9
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.9.0.0

    echo "========================================================"
    echo "Cloning, building, and installing wayland from source..."
    echo "========================================================"

    set -e

    if [ -d "$SCRIPTPATH/wayland" ]; then
        pushd "$SCRIPTPATH/wayland"
            git pull
        popd
    else
        git clone git://anongit.freedesktop.org/wayland/wayland "$SCRIPTPATH/wayland"
    fi

    pushd "$SCRIPTPATH/wayland"

    ln -s -f /usr/share/libtool/build-aux/ltmain.sh .

    ./autogen.sh --disable-documentation && make -j4 && make install

    popd

    set +e

    echo "=================================="
    echo "Configuring pulseaudio defaults..."
    echo "=================================="

    cp -v "$ETC_DIR/pulse/default.pa" /etc/pulse/ || exit 1
    chmod 644 /etc/pulse/default.pa

    echo "====================================="
    echo "Configuring GPU clockspeed service..."
    echo "====================================="

    set -e

    cp -v "$ETC_DIR/init.d/gpu-freqboost-tinker" /etc/init.d

    chmod 755 /etc/init.d/gpu-freqboost-tinker

    systemctl enable gpu-freqboost-tinker

    systemctl start gpu-freqboost-tinker

    set +e

    echo "========================================="
    echo "Configuring retropie group and sudoers..."
    echo "========================================="

    set -e

    if ! getent group retropie; then
        echo "Creating group: retropie"
        groupadd retropie
    fi

    if ! id -nG $SUDO_USER | grep -qw retropie; then
        echo "Adding user $SUDO_USER to group retropie."
        usermod -a -G retropie $SUDO_USER
    fi

    echo "Adding passwordless sudo for important retropie commands..."
    cp -v "$ETC_DIR/sudoers.d/retropie" /etc/sudoers.d

    set -x

    echo "%retropie ALL=(ALL:ALL) NOPASSWD: $RETROPIE_SETUP_DIR/retropie_setup.sh" >>/etc/sudoers.d/retropie
    echo "%retropie ALL=(ALL:ALL) NOPASSWD: $RETROPIE_SETUP_DIR/retropie_packages.sh" >>/etc/sudoers.d/retropie

    chmod 440 /etc/sudoers.d/retropie

    set +x

    set -e

    echo "============================="
    echo "Cloning RetroPie-Setup to ../"
    echo "============================="
    
    set -e

    if [ -d "$RETROPIE_SETUP_DIR" ]; then
        pushd "$RETROPIE_SETUP_DIR"
            git pull origin "$RETROPIE_BRANCH"
            if [[ "$RETROPIE_COMMIT" ]]; then
                git checkout "$RETROPIE_COMMIT"
            fi
        popd
    else
        git clone --branch "$RETROPIE_BRANCH" https://github.com/slaminger/RetroPie-Setup-1 "$RETROPIE_SETUP_DIR"

        if [[ "$RETROPIE_COMMIT" ]]; then
            echo "Rewinding RetroPie-Setup to commit: $RETROPIE_COMMIT"
            pushd "$RETROPIE_SETUP_DIR"
                git checkout "$RETROPIE_COMMIT"
            popd
        fi
    fi

    set +e

    echo "=================================="
    echo "Applying RetroPie-Setup Patches..."
    echo "=================================="

    set -e

    for patch_dir in "$PATCHES_DIR"/*; do
        "$patch_dir/patch.sh" "$RETROPIE_SETUP_DIR"
    done

    set +e

    # Install any modules the user requested from the 
    # command line first.

    RETROPIE_INSTALL_MODULES=($RETROPIE_INSTALL_MODULES)

    if [ ${#RETROPIE_INSTALL_MODULES[@]} -ne 0 ]; then
        echo "======================================"
        echo "Installing RETROPIE_INSTALL_MODULES..."
        echo "======================================"

        pushd "$RETROPIE_SETUP_DIR"
    
        for module in "${RETROPIE_INSTALL_MODULES[@]}"; do

            ./retropie_packages.sh "$module" || exit 1

            if [[ "$module" == xpad ]]; then
                modprobe xpad
            fi
        done

        popd
    fi

    # Do an automated basic install if requested
    # and log it since auto logging is not enabled
    # when doing it this way.

    if [ $RETROPIE_BASIC_INSTALL -eq 1 ]; then

        echo "========================================"
        echo "Starting RetroPie-Setup basic install..."
        echo "========================================"

        pushd "$RETROPIE_SETUP_DIR"

        ./retropie_packages.sh tinker-basic-install install || exit 1

        popd

        echo "=============================="
        echo "Install Completed Successfully"
    fi

) 2>&1 | tee "$LOG_FILE"


INSTALL_STATUS=${PIPESTATUS[0]}

if [ $INSTALL_STATUS -ne 0 ]; then
    echo "===================="
    echo "Install failed, see: \"$LOG_FILE\" for details."
    exit $INSTALL_STATUS
fi

# Let retropie_setup.sh use its own built in logging
# if the user did not request an automated basic install.

if [ $RETROPIE_BASIC_INSTALL -eq 0 ]; then

    echo "=============================="
    echo "Starting RetroPie-Setup GUI..."
    echo "=============================="

    pushd "$RETROPIE_SETUP_DIR"

    ./retropie_setup.sh

    popd
fi


