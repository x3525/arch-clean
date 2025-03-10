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

read -r -s -p "Enter root password:" password_root
echo
read -r -s -p "Enter root password (again):"
echo

if [ -z "$REPLY" ] || [ "$password_root" != "$REPLY" ]
then
    echo "Passwords do not match!"
    exit 1
fi

read -r -s -p "Enter user password:" password_user
echo
read -r -s -p "Enter user password (again):"
echo

if [ -z "$REPLY" ] || [ "$password_user" != "$REPLY" ]
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

# Partiton the disks
sfdisk "$1" << EOF
label: gpt

start=        2048, size=     2097152, type=U
start=     2099200, size=    33554432, type=S
start=    35653632,                    type=L
EOF

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$1" | grep "start" | cut -d ":" -f 1)
do
    partitions+=("$partition")
done

mkfs.fat -F 32 "${partitions[0]}"
mkswap "${partitions[1]}"
mkfs.ext4 "${partitions[2]}" -F

# Mount the file systems
mount "${partitions[2]}" /mnt
mount "${partitions[0]}" /mnt/boot/efi --mkdir=0755

# Enable the swap partition
swapon "${partitions[1]}"

# Install packages
while ! pacstrap -K /mnt - < PACKAGES
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r
    case $REPLY in
        [nN]*)
            umount -R /mnt
            swapoff "${partitions[1]}"
            exit 1
            ;;
    esac
done

# Generate an fstab file
genfstab /mnt >> /mnt/etc/fstab

# Add a new user
useradd --root /mnt -m -G wheel "$2"

# Change passwords
echo "$password_root" | passwd --root /mnt --stdin
echo "$password_user" | passwd --root /mnt --stdin "$2"

# Change root into the new system
cp install_chroot.sh /mnt
arch-chroot /mnt "bash install_chroot.sh"
