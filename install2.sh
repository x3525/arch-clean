#!/bin/bash

if [ $# -ne 1 ]
then
    echo "Usage: $0 <device>"
    exit 1
else
    device=$1

    if [ ! -b "$device" ]
    then
        echo "Not a block special!"
        exit 1
    fi
fi

if [ "$(cat /sys/firmware/efi/fw_platform_size)" -ne 64 ]
then
    echo "System is not booted in 64-bit UEFI mode!"
    exit 1
fi

if ! ping -q -c 1 -w 2 "$(ip route | grep "default" | cut -d " " -f 3)" >& /dev/null
then
    echo "Network is unreachable!"
    exit 1
fi

# Erase all available signatures
wipefs -a -f "$device"*
read -r "Press enter to continue..."

# Partiton the disks
if ! sfdisk "$device" << EOF
label: gpt

start=        2048, size=     2097152, type=U
start=     2099200, size=    33554432, type=S
start=    35653632,                    type=L
EOF
then
    exit 1
fi
read -r "Press enter to continue..."

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$1" | grep "start" | cut -d ":" -f 1)
do
    partitions+=("$partition")
done

U=${partitions[0]}
S=${partitions[1]}
L=${partitions[2]}

mkfs.fat -F 32 "$U"
read -r "Press enter to continue..."
mkswap "$S"
read -r "Press enter to continue..."
mkfs.ext4 "$L" -F
read -r "Press enter to continue..."

# Mount the file systems
mount "$L" /mnt
read -r "Press enter to continue..."
mount "$U" /mnt/boot/efi --mkdir=0755
read -r "Press enter to continue..."

# Enable the swap partition
swapon "$S"
read -r "Press enter to continue..."

# Update the mirror list
reflector --country Germany --download-timeout 60 --latest 10 --protocol https --save /etc/pacman.d/mirrorlist
read -r "Press enter to continue..."
