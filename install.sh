#!/bin/bash

if [ $# -ne 1 ]
then
    echo "Usage: $0 <device>"
    exit 1
else
    device=$1

    if [ ! -b "$device" ]
    then
        echo "Device is not a block special!"
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
wipefs -f -a "$device"*
echo "wipefs: Done..."
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
echo "sfdisk: Done..."
echo "Press enter to continue..."
read -r

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$device" | grep "start" | cut -d ":" -f 1)
do
    partitions+=("$partition")
done

uefi=${partitions[0]}
swap=${partitions[1]}
ext4=${partitions[2]}

mkfs.fat -F 32 "$uefi"
echo "mkfs.fat: Done..."
echo "Press enter to continue..."
read -r
mkswap "$swap"
echo "mkswap: Done..."
echo "Press enter to continue..."
read -r
mkfs.ext4 "$ext4" -F
echo "mkfs.ext4: Done..."
echo "Press enter to continue..."
read -r

# Mount the file systems
mount "$ext4" /mnt
echo "mount ext4: Done..."
echo "Press enter to continue..."
read -r
mount "$uefi" /mnt/boot/efi --mkdir=0755
echo "mount uefi: Done..."
echo "Press enter to continue..."
read -r

# Enable the swap partition
swapon "$swap"
echo "swapon swap: Done..."
echo "Press enter to continue..."
read -r

# Install packages
while ! pacstrap -K /mnt - < PACKAGES
do
    echo "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r
    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done
echo "pacstrap: Done..."
echo "Press enter to continue..."
read -r

# Generate an fstab file
genfstab /mnt >> /mnt/etc/fstab
echo "genfstab: Done..."
echo "Press enter to continue..."
read -r

# Change root into the new system
cp install_chroot.sh /mnt
arch-chroot /mnt "bash install_chroot.sh"
