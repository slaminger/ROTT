#!/bin/bash

while getopts ":h" opt; do
  case $opt in
    h)
      echo "This script takes two arguments, a device partition and an image out file path."
      echo "Usage is shown with default values. This script must be run as root."
      echo "================================"
      echo "Usage: squash_sd_img /dev/mmcblkp0p1 image_out.img"
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

DEV=${@:$OPTIND:1}
DISK_IMAGE=${@:$OPTIND+1:1}

DEV_PART=${DEV_PART:-/dev/mmcblk0p1}
DISK_IMAGE=${DISK_IMAGE:-image_out.img}

# The root device
DEV=/dev/$(lsblk $DEV_PART -no pkname)


echo "Squashing $DEV into image: $DISK_IMAGE..."

# ==== Get Deps ======

SCRIPT_DEPS=(parted e2fsprogs)

DEPS_TO_INSTALL=()
for DEP in ${SCRIPT_DEPS[@]}; do
    if [ $(dpkg-query -W -f='${Status}' $DEP 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        DEPS_TO_INSTALL+=($DEP)
    fi
done

if [ -n "$DEPS_TO_INSTALL" ]; then
    echo "========================================="
    echo "Installing missing script dependencies..."
    echo "========================================="
    apt-get install -y ${DEPS_TO_INSTALL[@]}
fi

# ====

get_sector_bounds(){
    fdisk -l $1 | tail -n1 | awk '{print $2 " " $3}'
}

get_sector_size(){
    cat /sys/block/$(basename $1)/queue/hw_sector_size
}

get_ext4_size(){
    dumpe2fs -h $1 |& awk -F: '/Block count/{count=$2} /Block size/{size=$2} END{printf "%f", count*size}' | cut -d'.' -f1
}


echo "============================"
echo "Gathering filesystem info..."
echo "============================"


SOURCE_SECTOR_SIZE_BYTES=$(get_sector_size $DEV)
SOURCE_PART_SECTOR_BOUNDS=($(get_sector_bounds $DEV))
SOURCE_FS_SIZE_BYTES=$(get_ext4_size $DEV_PART)
SOURCE_FS_SIZE_SECTORS=$(echo "$SOURCE_FS_SIZE_BYTES/$SOURCE_SECTOR_SIZE_BYTES" | bc)
SOURCE_PART_START_BYTE=$(echo "${SOURCE_PART_SECTOR_BOUNDS[0]}*$SOURCE_SECTOR_SIZE_BYTES" | bc)

echo "Source Sector Size Bytes:" ${SOURCE_SECTOR_SIZE_BYTES}
echo "Source Part Sector Bounds:" ${SOURCE_PART_SECTOR_BOUNDS[@]}
echo "Source Part Start Byte:" $SOURCE_PART_START_BYTE
echo "Source Part ext4 Size Bytes:" ${SOURCE_FS_SIZE_BYTES}
echo "Source Part ext4 Size Sectors:" ${SOURCE_FS_SIZE_SECTORS}

echo "======================="
echo "Shrinking filesystem..."
echo "======================="

umount $DEV_PART > /dev/null 2>&1
resize2fs -Mfp $DEV_PART

echo "=================================="
echo "Calculating new filesystem info..."
echo "=================================="

NEW_FS_SIZE_BYTES=$(get_ext4_size $DEV_PART)
NEW_FS_SIZE_SECTORS=$(echo "$NEW_FS_SIZE_BYTES/$SOURCE_SECTOR_SIZE_BYTES" | bc)

echo "New ext4 Size Bytes:" $NEW_FS_SIZE_BYTES
echo "New ext4 Size Sectors:" $NEW_FS_SIZE_SECTORS


NEW_PART_END_BYTE=$(echo "$NEW_FS_SIZE_BYTES+$SOURCE_PART_START_BYTE-1" | bc)
NEW_PART_END_SECTOR=$(echo "($NEW_PART_END_BYTE / $SOURCE_SECTOR_SIZE_BYTES)" | bc)

echo "New Part End Byte:" $NEW_PART_END_BYTE
echo "New Part End Sector:" $NEW_PART_END_SECTOR


echo "======================"
echo "Shrinking partition..."
echo "======================"

parted $DEV resizepart 1 ${NEW_PART_END_SECTOR}S Yes

echo "================================="
echo "Calculating new partition info..."
echo "================================="

NEW_PART_SIZE_BYTES=$(echo "$NEW_PART_END_BYTE-$SOURCE_PART_START_BYTE+1" | bc)
NEW_PART_SIZE_SECTORS=$(echo "$NEW_PART_SIZE_BYTES/$SOURCE_SECTOR_SIZE_BYTES" | bc)
NEW_PART_SIZE_512_SECTORS=$(echo "$NEW_PART_SIZE_BYTES/512" | bc)

echo "New Part Size Bytes:" $NEW_PART_SIZE_BYTES
echo "New Part Size Sectors:" $NEW_PART_SIZE_SECTORS
echo "New Part Size 512B Sectors:" $NEW_PART_SIZE_512_SECTORS

echo "=========================="
echo "Cloning device to image..."
echo "=========================="

pv $DEV -pte --size $NEW_PART_END_BYTE | dd of=$DISK_IMAGE bs=512 count=$(($NEW_PART_END_SECTOR+1))
chown $SUDO_USER:$SUDO_USER $DISK_IMAGE

echo "============================================="
echo "Restoring device partition/filesystem size..."
echo "============================================="

parted --script $DEV resizepart 1 ${SOURCE_PART_SECTOR_BOUNDS[1]}S
resize2fs -fp $DEV_PART

echo "====="
echo "Done!"




