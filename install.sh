#!/bin/bash

online () {
    command ping 1.1.1.1 -c 1 -W 3 > /dev/null
}

zzzz () {
    for u
    do
        command echo "Currently waiting for ${u} to complete..."

        case ${u} in
            *.timer)
                while [ -z "$(command systemctl show -P ActiveEnterTimestamp "${u}")" ]
                do
                    if online; then command sleep 1; else exit 1; fi
                done
                ;;
            *.service)
                while [ "$(command systemctl is-active "${u}")" != "inactive" ]
                do
                    if online; then command sleep 1; else exit 1; fi
                done
                ;;
        esac
    done
}

if [ ! -e /sys/firmware/efi/fw_platform_size ]
then
    command echo "System is not booted in UEFI mode!"
    exit 1
fi

if [ $# -ne 2 ]
then
    command echo "Usage: ${0} BLOCK LOGIN"
    exit 1
fi

BLOCK=${1}
LOGIN=${2}

if [ ! -b "${BLOCK}" ]
then
    command echo "Device is not a block special!"
    exit 1
fi

LC_CTYPE=C

if [[ ! ${LOGIN} =~ ^[a-z][a-z0-9_][a-z0-9_]{,30}$ ]]
then
    command echo "Login entry is invalid!"
    exit 1
fi

P=$(command systemd-ask-password --timeout=0 --echo=yes --emoji=no "password (user)")
R=$(command systemd-ask-password --timeout=0 --echo=yes --emoji=no "password (root)")

if [ -z "${P}" ] || [ -z "${R}" ]
then
    command echo "Empty passwords are not allowed!"
    exit 1
fi

case "$(command lspci -d ::03xx)" in
    *[aA][mM][dD]*)
        packages+=(mesa)
        packages+=(vulkan-radeon)
        packages+=(xf86-video-ati)
        packages+=(xf86-video-amdgpu)
        ;;&
    *[iI][nN][tT][eE][lL]*)
        packages+=(mesa)
        packages+=(vulkan-intel)
        packages+=(intel-media-driver)
        packages+=(libva-intel-driver)
        ;;&
    *[nN][vV][iI][dD][iI][aA]*)
        command echo "[1] NVIDIA kernel modules - module sources"
        command echo "[2] NVIDIA open kernel modules - module sources"
        command echo "[3] Open Source 3D acceleration driver for nVidia cards"
        command echo "[q]"

        while true
        do
            command echo -n "What is your choice? "

            read -r || command echo

            case $REPLY in
                1)
                    packages+=(dkms)
                    packages+=(nvidia-dkms)
                    packages+=(libva-nvidia-driver)
                    break
                    ;;
                2)
                    packages+=(dkms)
                    packages+=(nvidia-open-dkms)
                    packages+=(libva-nvidia-driver)
                    break
                    ;;
                3)
                    packages+=(mesa)
                    packages+=(vulkan-nouveau)
                    packages+=(xf86-video-nouveau)
                    break
                    ;;
                [qQ])
                    exit 1
                    ;;
            esac
        done
        ;;
esac

case "$(command grep vendor_id /proc/cpuinfo)" in
    *[aA][mM][dD]*)
        packages+=(amd-ucode)
        ;;
    *[iI][nN][tT][eE][lL]*)
        packages+=(intel-ucode)
        ;;
esac

if command grep -q snd_sof /proc/modules
then
    packages+=(sof-firmware)
fi

command echo "Starting sanity checks..."

while [ "$(command timedatectl show -P NTPSynchronized)" != "yes" ]
do
    if online; then command sleep 1; else exit 1; fi
done

# Wait for automatic mirror selection to complete
zzzz reflector.service

# Wait for Arch Linux keyring synchronization to complete
zzzz archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

set -x
set -e

command sfdisk -w always -W always "${BLOCK}" << EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

DUMP=$(command sfdisk "${BLOCK}" -d)

U=$(command awk '/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/ {print $1}' <<< "${DUMP}")
S=$(command awk '/0657FD6D-A4AB-43C4-84E5-0933C84B4F4F/ {print $1}' <<< "${DUMP}")
L=$(command awk '/0FC63DAF-8483-4772-8E79-3D69D8477DE4/ {print $1}' <<< "${DUMP}")

command mkfs.vfat "${U}" -F 32
command mkfs.ext4 "${L}" -F

command mount -m "${L}" /mnt
command mount -m "${U}" /mnt/efi

command mkswap "${S}"
command swapon "${S}"

while ! command pacstrap -K /mnt base base-devel linux linux-firmware linux-headers "${packages[@]}" - < PACKAGES
do
    command echo -n "Alas, Pacman failed. Tr[Y] agai[n]? "

    read -r || command echo

    case $REPLY in
        [nN])
            exit 1
            ;;
    esac
done

command cp -r -- */ /mnt

# Generate fstab file
command genfstab -U /mnt > /mnt/etc/fstab

# Create a new user
command useradd -R /mnt -s /usr/bin/zsh -G wheel -m "${LOGIN}"

# Change password (user)
command echo "${P}" | command passwd -R /mnt -s "${LOGIN}"

# Change password (root)
command echo "${R}" | command passwd -R /mnt -s

# Generate the locales
command arch-chroot /mnt locale-gen

# Set the Hardware Clock from the System Clock
command arch-chroot /mnt hwclock -w

# Enable timers
command arch-chroot /mnt systemctl enable fstrim.timer
command arch-chroot /mnt systemctl enable reflector.timer

# Enable services
command arch-chroot /mnt systemctl enable NetworkManager.service
command arch-chroot /mnt systemctl enable lightdm.service
command arch-chroot /mnt systemctl enable systemd-timesyncd.service

# Install GRUB to a device
command arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --removable

# Generate a GRUB configuration file
command arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
