#!/bin/bash

function wait()
{
    for u
    do
        echo "Currently waiting for ${u} to complete..."

        case ${u} in
            *.timer)
                while [ -z "$(systemctl show -P ActiveEnterTimestamp "${u}")" ]
                do
                    sleep 1
                done
                ;;
            *)
                while [ "$(systemctl is-active "${u}")" != "inactive" ]
                do
                    sleep 1
                done
                ;;
        esac
    done
}

if [ ! -d /sys/firmware/efi ]
then
    echo "System is not booted in UEFI mode!"
    exit 1
fi

if [ $# -ne 2 ]
then
    echo "Usage: ${0} DEVICE LOGIN"
    exit 1
fi

if [ ! -b "${1}" ]
then
    echo "Device is not a block special!"
    exit 1
fi

LC_CTYPE=C

if [[ ! ${2} =~ ^[a-z][a-z0-9][a-z0-9]{,30}$ ]]
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

if ! ping -q -c 1 -w 2 "$(ip route | grep -m 1 default | cut -d ' ' -f 3)" &> /dev/null
then
    echo "Network is unreachable!"
    exit 1
fi

echo "Starting sanity checks..."

while [ "$(timedatectl show -P NTPSynchronized)" != "yes" ]
do
    sleep 1
done

# Wait for automatic mirror selection to complete
wait reflector.service

# Wait for Arch Linux keyring synchronization to complete
wait archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

set -e
set -o pipefail

sfdisk "${1}" << EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

DUMP=$(sfdisk "${1}" --dump)

# Format the partitions
mkfs.fat "(sed -nE 's/(^[^ ]+).+type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,.+/\1/p' <<< "${DUMP}")" -F 32
mkfs.ext4 "(sed -nE 's/(^[^ ]+).+type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709,.+/\1/p' <<< "${DUMP}")" -F

# Mount the file systems
mount -m "(sed -nE 's/(^[^ ]+).+type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709,.+/\1/p' <<< "${DUMP}")" /mnt
mount -m "(sed -nE 's/(^[^ ]+).+type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,.+/\1/p' <<< "${DUMP}")" /mnt/boot/efi

# SWAP
mkswap "(sed -nE 's/(^[^ ]+).+type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F,.+/\1/p' <<< "${DUMP}")"
swapon "(sed -nE 's/(^[^ ]+).+type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F,.+/\1/p' <<< "${DUMP}")"

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

useradd -R /mnt -m -G wheel -s /usr/bin/zsh "${2}" 2> /dev/null

echo "${ROOT}" | passwd -R /mnt --stdin
echo "${PASS}" | passwd -R /mnt --stdin "${2}"

cp -r rootfs/. /mnt

# Generate the locales
arch-chroot /mnt locale-gen

arch-chroot /mnt systemctl enable fstrim.timer reflector.timer
arch-chroot /mnt systemctl enable lightdm.service NetworkManager.service systemd-timesyncd.service

case "$(lsblk "${1}" -o HOTPLUG -n -d)" in
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
