#!/bin/bash

if [ "$(cat /sys/firmware/efi/fw_platform_size)" != "64" ]
then
    echo "System is not booted in 64-bit UEFI mode!"
    exit 1
fi

if [ $# -ne 2 ]
then
    echo "Usage: $0 <device> <user>"
    exit 1
fi

if [ ! -b "$1" ]
then
    echo "Device is not a block special!"
    exit 1
fi

printf 'Enter root password 1:'; set +a; stty -echo; read -rs r1; set -a; stty echo; echo
printf 'Enter root password 2:'; set +a; stty -echo; read -rs r2; set -a; stty echo; echo

if [ -z "$r1" ] || [ "$r1" != "$r2" ]
then
    echo "Passwords do not match!"
    exit 1
fi

printf 'Enter user password 1:'; set +a; stty -echo; read -rs u1; set -a; stty echo; echo
printf 'Enter user password 2:'; set +a; stty -echo; read -rs u2; set -a; stty echo; echo

if [ -z "$u1" ] || [ "$u1" != "$u2" ]
then
    echo "Passwords do not match!"
    exit 1
fi

if ! ping -q -c 1 -w 2 "$(ip route | grep "default" | cut -d " " -f 3)" >& /dev/null
then
    echo "Network is unreachable!"
    exit 1
fi

# Erase all available signatures
wipefs --force --all "$1"*

# Disk partiton
sfdisk "$1" << EOF
label: gpt

start=        2048, size=     2097152, type=U
start=     2099200, size=    33554432, type=S
start=    35653632,                    type=L
EOF

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$1" | grep "start" | cut -d ":" -f 1 | tr -d " ")
do
    partitions+=("$partition")
done

mkfs.ext4 "${partitions[2]}" -F
mkfs.fat  "${partitions[0]}" -F 32
mkswap    "${partitions[1]}"

# Mount the file systems
mount     "${partitions[2]}" /mnt
mount     "${partitions[0]}" /mnt/boot/efi --mkdir=0755
swapon    "${partitions[1]}"

# Install packages
while ! pacstrap -K /mnt - < PACKAGES
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r
    case $REPLY in
        [nN]*)
            umount --recursive /mnt
            swapoff -a
            exit 1
            ;;
    esac
done

# Generate an fstab file
genfstab /mnt >> /mnt/etc/fstab

# Add user
useradd --root /mnt -m -G wheel "$2"

# Change passwords
printf '%s' "$r1" | passwd --root /mnt --stdin
printf '%s' "$u1" | passwd --root /mnt --stdin "$2"

# sudoers
echo '%wheel ALL=(ALL:ALL) ALL' | tee /mnt/etc/sudoers.d/wheel
chown --recursive root:root /mnt/etc/sudoers.d/*
chmod --recursive 0440 /mnt/etc/sudoers.d/*

# GRUB
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
