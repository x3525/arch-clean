#!/bin/bash

if [ "$(cat /sys/firmware/efi/fw_platform_size)" != "64" ]
then
    echo "System is not booted in 64-bit UEFI mode!"
    exit 1
fi

if [ $# -ne 2 ]
then
    echo "Usage: $0 DEVICE USER"
    exit 1
fi

if [ ! -b "$1" ]
then
    echo "Device is not a block special!"
    exit 1
fi

if ! grep -qP '^[a-z][a-z0-9]{,15}$' <<< "$2"
then
    echo "Given name is invalid!"
    exit 1
fi

printf 'Enter password:'; set +a; read -r -s PASS_USER; set -a; echo
printf 'Enter password:'; set +a; read -r -s USER_PASS; set -a; echo

if [ "$PASS_USER" != "$USER_PASS" ]
then
    echo "Passwords do not match!"
    exit 1
fi

printf 'Enter password (root):'; set +a; read -r -s PASS_ROOT; set -a; echo
printf 'Enter password (root):'; set +a; read -r -s ROOT_PASS; set -a; echo

if [ "$PASS_ROOT" != "$ROOT_PASS" ]
then
    echo "Passwords do not match!"
    exit 1
fi

if [ -z "$PASS_ROOT" ] || [ -z "$PASS_USER" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

if ! ping -q -c 1 -w 2 "$(ip route | grep default | cut -d ' ' -f 3)" >& /dev/null
then
    echo "Network is unreachable!"
    exit 1
fi


unmount()
{
    umount -q -R /mnt
    swapoff -a
}


unmount

# Erase all available signatures
wipefs --force --all "$1"*

# Disk partiton
sfdisk "$1" <<- EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$1" | grep start | cut -d ':' -f 1 | tr -d ' ')
do
    partitions+=("$partition")
done

mkfs.ext4 "${partitions[2]}" -F
mkfs.fat  "${partitions[0]}" -F 32
mkswap    "${partitions[1]}"

# Mount the file systems
mount     "${partitions[2]}" /mnt
mount     "${partitions[0]}" /mnt/boot/efi -m
swapon    "${partitions[1]}"

# Determine additional packages to install
packages=()

if grep -q snd_sof /proc/modules
then
    packages+=(sof-firmware)
fi

if [ "$(systemd-detect-virt)" != "none" ]
then
    packages+=(mesa)
    packages+=(xf86-video-vmware)
else
    case "$(lspci -d ::03xx)" in
        *[aA][mM][dD]*)
            packages+=(libva-mesa-driver)
            packages+=(mesa)
            packages+=(vulkan-radeon)
            packages+=(xf86-video-amdgpu)
            packages+=(xf86-video-ati)
            ;;&
        *[iI][nN][tT][eE][lL]*)
            packages+=(intel-media-driver)
            packages+=(libva-intel-driver)
            packages+=(mesa)
            packages+=(vulkan-intel)
            ;;&
        *[nN][vV][iI][dD][iI][aA]*)
            packages+=(libva-mesa-driver)
            packages+=(mesa)
            packages+=(xf86-video-nouveau)
            ;;&
    esac
fi

# Install packages
while ! pacstrap -K /mnt - < PACKAGES
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r
    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done

# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab

# Add user
useradd --root /mnt -m -G wheel "$2"

# Change passwords
printf '%s' "$PASS_ROOT" | passwd --root /mnt --stdin
printf '%s' "$PASS_USER" | passwd --root /mnt --stdin "$2"

# sudoers
echo '%wheel ALL=(ALL:ALL) ALL' | tee /mnt/etc/sudoers.d/wheel
chown -R root:root /mnt/etc/sudoers.d/*
chmod -R 0440 /mnt/etc/sudoers.d/*

# GRUB
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
