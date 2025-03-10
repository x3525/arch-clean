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


installation_pre()
{
    # Erase all available signatures
    wipefs -f -a "$device"*

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
    mkswap "$swap"
    mkfs.ext4 "$ext4" -F

    # Mount the file systems
    mount "$ext4" /mnt
    mount "$uefi" /mnt/boot/efi --mkdir=0755

    # Enable the swap partition
    swapon "$swap"
}


installation() {
    # Install packages
    while ! pacstrap -q -K /mnt - < PACKAGES
    do
        echo "Alas, Pacman failed. Tr[Y] agai[n]?"
        read -r
        case $REPLY in
            [nN]*)
                exit 1
                ;;
        esac
    done

    # Generate an fstab file
    genfstab /mnt >> /mnt/etc/fstab

    # Change root into the new system
    cp install_chroot.sh /mnt
    arch-chroot /mnt "bash install_chroot.sh"
}


installation_pre
installation
