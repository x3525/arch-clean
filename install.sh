#!/bin/bash

. functions.sh

if no::uefi
then
    echo "System is not booted in UEFI mode!"
    exit 1
fi

if [ $# -ne 2 ]
then
    echo "Usage: ${0} DEVICE LOGIN"
    exit 1
fi

DEVICE=${1}

if [ ! -b "${DEVICE}" ]
then
    echo "Device is not a block special!"
    exit 1
fi

LOGIN=${2}

if no::name "${LOGIN}"
then
    echo "Login entry is invalid!"
    exit 1
fi

PASS=$(systemd-ask-password --timeout=0 --echo=no --emoji=no "Password:")
ROOT=$(systemd-ask-password --timeout=0 --echo=no --emoji=no "Password (root):")

if [ -z "${PASS}" ] || [ -z "${ROOT}" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

if no::connection
then
    echo "Network is unreachable!"
    exit 1
fi

echo "Starting sanity checks..."

EPOCH=$(date +%s)

while no::ntp
do
    if [ $(( $(date +%s) - EPOCH )) -gt 10 ]
    then
        echo "Time synchronization not completing!"
        exit 1
    fi

    sleep 1
done

# Wait for automatic mirror selection to complete
unit::wait reflector.service

# Wait for Arch Linux keyring synchronization to complete
unit::wait archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

set -e
set -o pipefail

sfdisk "${DEVICE}" << EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

EFI_SYSTEM_PARTITION=$(part::get "${DEVICE}" C12A7328-F81F-11D2-BA4B-00A0C93EC93B)
LINUX_SWAP=$(part::get "${DEVICE}" 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F)
LINUX_ROOT_X86_64=$(part::get "${DEVICE}" 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709)

# Format the partitions
mkfs.fat "${EFI_SYSTEM_PARTITION}" -F 32
mkfs.ext4 "${LINUX_ROOT_X86_64}" -F

# Mount the file systems
mount -m "${LINUX_ROOT_X86_64}" /mnt
mount -m "${EFI_SYSTEM_PARTITION}" /mnt/boot/efi

# SWAP
mkswap "${LINUX_SWAP}"
swapon "${LINUX_SWAP}"

case "$(lspci -d ::03xx)" in
    *[aA][mM][dD]*)
        packages+=(vulkan-radeon)
        packages+=(xf86-video-amdgpu)
        packages+=(xf86-video-ati)
        ;;&
    *[iI][nN][tT][eE][lL]*)
        packages+=(intel-media-driver)
        packages+=(libva-intel-driver)
        packages+=(vulkan-intel)
        ;;&
    *[nN][vV][iI][dD][iI][aA]*)
        packages+=(xf86-video-nouveau)
        ;;
esac

# Determine additional packages to install
if grep -q snd_sof /proc/modules
then
    packages+=(sof-firmware)
fi

while ! pacstrap -K /mnt base linux linux-firmware linux-headers "${packages[@]}" - < PACKAGES
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]? "
    read -r

    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done

genfstab -U /mnt > /mnt/etc/fstab

# Set the Hardware Clock from the System Clock
hwclock --systohc --adjfile=/mnt/etc/adjtime

cp -r rootfs/. /mnt

# Generate the locales
arch-chroot /mnt locale-gen

useradd -R /mnt -m -G wheel -s /usr/bin/zsh "${LOGIN}" 2> /dev/null

echo "${ROOT}" | passwd -R /mnt --stdin
echo "${PASS}" | passwd -R /mnt --stdin "${LOGIN}"

arch-chroot /mnt systemctl enable fstrim.timer reflector.timer
arch-chroot /mnt systemctl enable lightdm.service NetworkManager.service systemd-timesyncd.service

case "$(lsblk "${DEVICE}" -o HOTPLUG -n -d)" in
    0)
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
        ;;&
    1)
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
        ;;&
    *)
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
        ;;
esac
