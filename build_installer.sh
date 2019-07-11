#!/bin/bash
#Don't make big changes here
SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/installer_src"
CACHE_FILE="$SCRIPTPATH/build_installer.cache"

if [ -f "$CACHE_FILE" ]; then
    source "$CACHE_FILE"
fi

if [[ "$@" =~ -h || "$@" =~ --help ]]; then

    echo "\
TinkerRetroPie install package generator.

 Use --force-build-armbian to force an update
 of Armbian sources and a full rebuild.

 Armbian Build Parameters: 

  ARMBIAN_BUILD_PATH=(scriptpath)/armbian_build
  BUILD_ARMBIAN=(yes/no)
  KERNEL_CONFIGURE=(yes/no)
  KERNELBRANCH=(branch:linux-4.14.y / tag:v4.14.71)
  LIB_TAG=(master / sunxi-4.14)

 TinkerRetroPie Installer Parameters:

  TINKER_RETRO_PIE_CONFIG=(path to installer config file)

 e.g:

  ./build_installer.sh BUILD_ARMBIAN=yes \\ 
                       KERNEL_CONFIGURE=no \\
                       KERNELBRANCH=branch:linux-4.14.y \\
                       LIB_TAG=master
"
    exit 0
fi

FORCE_BUILD_ARMBIAN=0
if [[ $@ == --force-build-armbian ]]; then
    FORCE_BUILD_ARMBIAN=1
fi

source "$INSTALLER_DIR/lib/read_params.sh"

BUILD_CONTAINER=${BUILD_CONTAINER:-docker}

OUTPUT_DIR=${OUTPUT_DIR:-"$SCRIPTPATH/output"}

DEFAULT_ARMBIAN_BUILD_DIR_NAME='armbian_build'
ARMBIAN_OUTPUT_DIR_NAME='output'
ARMBIAN_OUTPUT_IMAGES_DIR_NAME='images'
ARMBIAN_OUTPUT_DEBS_DIR_NAME='debs'

ARMBIAN_BUILD_PATH=${ARMBIAN_BUILD_PATH:-"$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"}
ARMBIAN_OUTPUT_PATH="$ARMBIAN_BUILD_PATH/$ARMBIAN_OUTPUT_DIR_NAME"
ARMBIAN_OUTPUT_IMAGES_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
ARMBIAN_OUTPUT_DEBS_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

pushd() {
    command pushd "$@" >/dev/null
}

popd() {
    command popd "$@" >/dev/null
}

# 1 parameter, the default if no input
ask_yes_no() {
    local answer

    while [[ "$answer" != y* && "$answer" != n* ]]; do
        read -e -p "(y)es / (n)o: " -i "${1,,}" answer
        answer=${answer:-$1}
        answer="${answer,,}"
    done
 
    if [[ $answer == y* ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

check_val_yes_no() {
    local arg=${1,,}

    if [[ $arg -eq 1 || "$arg" == y* ]]; then
        echo $2
        return 0
    elif [[ $arg -eq 0 || "$arg" == n* ]]; then
        echo $3
        return 0
    else
        return 1
    fi
}

# Return 1 if images exist in $ARMBIAN_OUTPUT_IMAGES_DIR else 0
armbian_images_exist() {
    if [ -d "$ARMBIAN_OUTPUT_IMAGES_DIR" ]; then
        find "$ARMBIAN_OUTPUT_IMAGES_DIR" -maxdepth 1 -name "*.img" -exec false {} +
        echo $?
    else
        echo 0
    fi
}

kconfig_file(){
    _KCONFIG_FILE=$1
}

kconfig_set(){
    local prop=$1
    local value=$2

    if grep -q "$prop" "$_KCONFIG_FILE"; then
        sed -i "s/# ${prop} is not set/${prop}=${value}/
                s/${prop}=[ynm]/${prop}=${value}/" "$_KCONFIG_FILE"
    else
        echo "${prop}=${value}" >> "$_KCONFIG_FILE"
    fi
}

compile_armbian() {

    if [ "$BUILD_CONTAINER" == "docker" ]; then
        if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            echo "You do not have docker installed, install docker and try again. Exiting."
            echo "See: https://docs.docker.com/install/"
            exit 1
        fi
    fi
 
    if [ -z "$LIB_TAG" ]; then
        echo "===================="
        echo "What Armbian build branch do you want to use?"
        echo "Enter a branch \"master\" or a tag, e.g. \"sunxi-4.14\""
        echo "Enter nothing to default to \"master\"."
        echo "===================="
        read -e -p "Armbian Build Branch: " -i "master" LIB_TAG
        echo ""
        LIB_TAG=${LIB_TAG:-master}
    fi

    if [ -z "$KERNELBRANCH" ]; then
        echo "===================="
        echo "What kernel branch do you want to compile?"
        echo "Enter a branch \"branch:linux-4.14.y\" or a tag \"tag:v4.14.71\""
        echo "Enter nothing to default to \"branch:linux-4.14.y\", using the latest tag."
        echo "===================="
        read -e -p "Kernel Branch: " -i "branch:linux-4.14.y" KERNELBRANCH
        echo ""
        KERNELBRANCH=${KERNELBRANCH:-"branch:linux-4.14.y"}
    fi

    if [ -z "$KERNEL_CONFIGURE" ]; then
        echo "===================="
        echo "Do you want to open the kernel config menu before the build starts?"
        echo "===================="

        KERNEL_CONFIGURE=$(ask_yes_no "no")
        echo ""
    else
        KERNEL_CONFIGURE=$(check_val_yes_no "$KERNEL_CONFIGURE" "yes" "no")
        if [ $? -ne 0 ]; then
            echo "Value of KERNEL_CONFIGURE must be 1/0, y/n, or yes/no."
            exit 1
        fi
    fi

    local kernel_short_version=$(echo "$KERNELBRANCH" | sed -n 's|\([^0-9]\+\)\([0-9.]*\)\(-rc[0-9]\+\)\{0,1\}|\2|p')
    local kernel_major=$(echo "$kernel_short_version" | cut -d'.' -f1)
    local kernel_minor=$(echo "$kernel_short_version" | cut -d'.' -f2)

    if [ -z "$BRANCH" ]; then



        if [ "$kernel_major" -eq 4 ]; then
            if [ "$kernel_minor" -gt 14 ]; then
                BRANCH=dev
            elif [ "$kernel_minor" -gt 4 ]; then
                BRANCH=next
            else
                BRANCH=default
            fi
        else
            echo "===================="
            echo "Build Failed: Unable to build a non major version 4 kernel!"
            exit 1
        fi
        
        echo "===================="
        echo "Kernel Version - Maj: $kernel_major, Min: $kernel_minor"
        echo "Selected Armbian Branch: $BRANCH, according to Kernel Branch: $KERNELBRANCH"
        echo "===================="
    fi

    if [ -d "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME" ]; then
        set -e
        if ! [ -z "$LIB_TAG" ]; then
            pushd "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"
                git pull origin master
            popd
        fi
        set +e
    else
        git clone https://github.com/Armbian/build "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"
    fi

    pushd "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"

    mkdir -p userpatches

    # Pick kernel branch

    echo "KERNELBRANCH='$KERNELBRANCH'" >./userpatches/lib.config

    if ! [ -z "$BOOTBRANCH" ]; then
        echo "BOOTBRANCH='$BOOTBRANCH'" >>./userpatches/lib.config
    fi

    local kernel_config_in="./config/kernel/linux-rockchip-${BRANCH}.config"
    local kernel_config_out="./userpatches/linux-rockchip-${BRANCH}.config"

    cp "$kernel_config_in" "$kernel_config_out"

    # Set the kernel config file to edit

    kconfig_file "$kernel_config_out"

    # Enable MALI devfreq support

    kconfig_set "CONFIG_MALI_DEVFREQ" "y"
    kconfig_set "CONFIG_JOYSTICK_XPAD" "n"
    kconfig_set "CONFIG_JOYSTICK_XPAD_FF" "n"
    kconfig_set "CONFIG_JOYSTICK_XPAD" "n"
    kconfig_set "CONFIG_JOYSTICK_XPAD_LEDS" "n"
    kconfig_set "CONFIG_INPUT_JOYDEV" "m"
    kconfig_set "CONFIG_INPUT_EVDEV" "m"
    
    # Fix tinker bluetooth for next and dev kernels

    if [ "$kernel_minor" -ge 14 ] && ! grep -q 'CONFIG_BT_HCIUART_3WIRE=y' "$kernel_config_out"; then

        echo "===================="
        echo "Enabling HCIUART_3WIRE (H5 Protocol) for kernel minor version >= 14"
        echo "Needed for bluetooth support on tinker"
        echo "===================="
        
        # Enable h5 protocol for bluetooth if not enabled

        # Depends...

        kconfig_set "CONFIG_SERIAL_DEV_BUS" "y"
        kconfig_set "CONFIG_BT_HCIUART_SERDEV" "y"

        # h5 support

        kconfig_set "CONFIG_BT_HCIUART_3WIRE" "y"

        # Extra stuff that its going to ask if you want...

        kconfig_set "CONFIG_BT_HCIUART_NOKIA" "n"
        kconfig_set "CONFIG_BT_HCIUART_LL" "n"
        kconfig_set "CONFIG_BT_HCIUART_BCM" "n"
        kconfig_set "CONFIG_QCA7000_UART" "n"
        kconfig_set "CONFIG_SERIAL_DEV_CTRL_TTYPORT" "n"
    fi

    ./compile.sh $BUILD_CONTAINER KERNEL_CONFIGURE=$KERNEL_CONFIGURE \
        KERNEL_ONLY=no BUILD_DESKTOP=no BOARD=tinkerboard \
        RELEASE=stretch BRANCH=$BRANCH LIB_TAG=$LIB_TAG \
        BSPFREEZE=yes CLEAN_LEVEL="$CLEAN_LEVEL"

    local compile_status=$?

    popd

    if [[ $(armbian_images_exist) -eq 0 || $compile_status -ne 0 ]]; then
        exit 1
    fi
}

main() {

    if [[ $(armbian_images_exist) -eq 0 || $FORCE_BUILD_ARMBIAN -eq 1 ]]; then

        local clone_or_update="clone"

        if [ -d "$ARMBIAN_BUILD_PATH" ]; then
            clone_or_update="update"
        fi

        if [ -z "$BUILD_ARMBIAN" ]; then

            echo "===================="
            echo "Would you like to $clone_or_update the Armbian-build repo and build Armbian?"
            echo "This script will automaticly enable Mali Midgard devfreq kernel support."
            echo "The build requires docker be installed."
            echo "===================="

            BUILD_ARMBIAN=$(ask_yes_no "yes")
            echo ""
        else
            BUILD_ARMBIAN=$(check_val_yes_no "$BUILD_ARMBIAN" "yes" "no")
            if [ $? -ne 0 ]; then
                echo "Value of BUILD_ARMBIAN must be 1/0, y/n, or yes/no."
                exit 1
            fi
        fi

        if [[ $BUILD_ARMBIAN == y* ]]; then
            if ! (compile_armbian); then
                echo "================================="
                echo "Failed to Build Armbian, exiting."
                exit 1
            fi
        else
            echo "===================="
            echo "Please specify the full path to your completed Armbian build."
            echo "===================="

            local found_valid_armbian_build=0

            while [ $found_valid_armbian_build -eq 0 ]; do

                local user_build_path

                read -e -p 'Armbian build repo path: ' -i "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME" user_build_path
                echo ""
                user_build_path=${user_build_path:-"$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"}

                local images_dir_struct="$ARMBIAN_OUTPUT_DIR_NAME/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
                local debs_dir_struct="$ARMBIAN_OUTPUT_DIR_NAME/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

                local user_images_dir="$user_build_path/$images_dir_struct"
                local user_debs_dir="$user_build_path/$debs_dir_struct"

                if ! [ -d "$user_images_dir" ]; then
                    echo "===================="
                    echo "\"$user_build_path\" does not contain an \"$images_dir_struct\" folder."
                    echo "Build Armbian first or try another path."
                    echo "===================="
                elif ! [ -d "$user_debs_dir" ]; then
                    echo "===================="
                    echo "\"$user_build_path\" does not contain an \"$debs_dir_struct\" folder."
                    echo "Build Armbian first or try another path."
                    echo "===================="
                else
                    ARMBIAN_BUILD_PATH=$(realpath "$user_build_path")
                    ARMBIAN_OUTPUT_PATH="$ARMBIAN_BUILD_PATH/$ARMBIAN_OUTPUT_DIR_NAME"
                    ARMBIAN_OUTPUT_IMAGES_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
                    ARMBIAN_OUTPUT_DEBS_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

                    if [ $(armbian_images_exist) -eq 0 ]; then
                        echo "===================="
                        echo "\"$user_build_path/$images_dir_struct\" does not contain any built Armbian images."
                        echo "Build Armbian first or try another path."
                        echo "===================="
                    else
                        found_valid_armbian_build=1
                        echo "===================="
                        echo "Found Armbian build at: \"$ARMBIAN_BUILD_PATH\""
                        echo "===================="
                    fi

                fi
            done
        fi
    else
        ARMBIAN_BUILD_PATH=$(realpath "$ARMBIAN_BUILD_PATH")
        ARMBIAN_OUTPUT_PATH="$ARMBIAN_BUILD_PATH/$ARMBIAN_OUTPUT_DIR_NAME"
        ARMBIAN_OUTPUT_IMAGES_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
        ARMBIAN_OUTPUT_DEBS_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

        echo "===================="
        echo "Found Armbian build at: \"$ARMBIAN_BUILD_PATH\""
        echo "===================="
    fi

    echo "ARMBIAN_BUILD_PATH=\"$ARMBIAN_BUILD_PATH\"" >"$CACHE_FILE"

    echo "========================"
    echo "Configuring installer..."
    echo "========================"

    set -x

    pushd "$INSTALLER_DIR"
    rm -f packages/linux-headers-*-rockchip_*_armhf.deb
    rm -f packages/armbian-config_*_all.deb
    rm -f packages/armbian-firmware-full_*_all.deb
    rm -f packages/armbian-tools-stretch_*_armhf.deb
    popd

    pushd "$ARMBIAN_OUTPUT_DEBS_DIR"
    cp linux-headers-*-rockchip_*_armhf.deb "$INSTALLER_DIR/packages"
    cp armbian-config_*_all.deb "$INSTALLER_DIR/packages"
    cp armbian-firmware-full_*_all.deb "$INSTALLER_DIR/packages"
    cp armbian-tools-stretch_*_armhf.deb "$INSTALLER_DIR/packages"
    popd

    pushd "$ARMBIAN_OUTPUT_IMAGES_DIR"
    RECENT_ARMBIAN_IMG=$(ls -t *.img | head -1)
    popd

    set +x

    echo "======================"
    echo "Packaging installer..."
    echo "======================"

    mkdir -p "$OUTPUT_DIR"
    pushd "$OUTPUT_DIR"

    set -x

    if [ -f "$TINKER_RETROPIE_CONFIG" ]; then
        cp "$TINKER_RETROPIE_CONFIG" "$INSTALLER_DIR/installer.cfg"
    fi

    INSTALLER_DIR_NAME=$(basename $INSTALLER_DIR)
    tar -czvf TinkerRetroPieInstaller.tar.gz \
        --transform "s/^$INSTALLER_DIR_NAME/TinkerRetroPieInstaller/" \
        -C "$SCRIPTPATH/" $INSTALLER_DIR_NAME

    if [ -f "$INSTALLER_DIR/installer.cfg" ]; then
        rm "$INSTALLER_DIR/installer.cfg"
    fi

    set +x

    echo "============================================"
    echo "Copying Armbian image to output directory..."
    echo "============================================"

    rm -f $RECENT_ARMBIAN_IMG
    rsync -ah --progress "$ARMBIAN_OUTPUT_IMAGES_DIR/$RECENT_ARMBIAN_IMG" .

    echo "====="
    echo "Done."
    echo "====="

    SHORT_OUTPUT_DIR_PATH=$(basename "$OUTPUT_DIR")

    echo "Flash: \"$SHORT_OUTPUT_DIR_PATH/$RECENT_ARMBIAN_IMG\""
    echo "Transfer \"$SHORT_OUTPUT_DIR_PATH/TinkerRetroPieInstaller.tar.gz\" to your Tinker Board."
    echo "Extract the archive and run: TinkerRetroPieInstaller/install.sh"

    popd

}

main
