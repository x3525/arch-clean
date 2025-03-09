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
echo "Press enter to continue..."
read -r

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
echo "Press enter to continue..."
read -r

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
echo "Press enter to continue..."
read -r
mkswap "$S"
echo "Press enter to continue..."
read -r
mkfs.ext4 "$L" -F
echo "Press enter to continue..."
read -r

# Mount the file systems
mount "$L" /mnt
echo "Press enter to continue..."
read -r
mount "$U" /mnt/boot/efi --mkdir=0755
echo "Press enter to continue..."
read -r

# Enable the swap partition
swapon "$S"
echo "Press enter to continue..."
read -r

# Update the mirror list
reflector --country Germany --download-timeout 60 --latest 10 --protocol https --save /etc/pacman.d/mirrorlist
echo "Press enter to continue..."
read -r

# Install essential packages
pacstrap -K /mnt base linux linux-firmware
echo "Press enter to continue..."
read -r

# Generate an fstab file
genfstab /mnt >> /mnt/etc/fstab

# Change root into the new system (chroot)
arch-chroot /mnt
echo "Press enter to continue..."
read -r

# Verify the master keys
pacman-key --init
pacman-key --populate
echo "Press enter to continue..."
read -r

# Install other packages
while ! cat -- PACKAGES | pacman -Syu --noconfirm --needed -
do
    echo "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r
    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done
echo "Press enter to continue..."
read -r
