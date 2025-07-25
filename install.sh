#!/bin/bash

zzzz()
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
            *.service)
                while [ "$(systemctl is-active "${u}")" != "inactive" ]
                do
                    sleep 1
                done
                ;;
        esac
    done
}

if [ ! -e /sys/firmware/efi/fw_platform_size ]
then
    echo "System is not booted in UEFI mode!"
    exit 1
fi

if [ $# -ne 2 ]
then
    lsblk
    echo "Usage: ${0} BLOCK LOGIN"
    exit 1
fi

BLOCK=${1}
LOGIN=${2}

if [ ! -b "${BLOCK}" ]
then
    echo "Device is not a block special!"
    exit 1
fi

LC_CTYPE=C

if [[ ! ${LOGIN} =~ ^[a-z][a-z0-9][a-z0-9]{,30}$ ]]
then
    echo "Login entry is invalid!"
    exit 1
fi

P=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Password (user)")
R=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Password (root)")

if [ -z "${P}" ] || [ -z "${R}" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

if ! ping 1.1.1.1 -c 1 -W 3 > /dev/null 2>&1
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
zzzz reflector.service

# Wait for Arch Linux keyring synchronization to complete
zzzz archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

set -x
set -e
set -o pipefail

sfdisk -w always -W always "${BLOCK}" << EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

DUMP=$(sfdisk "${BLOCK}" --dump)

U=$(awk '/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/ {print $1}' <<< "${DUMP}")
S=$(awk '/0657FD6D-A4AB-43C4-84E5-0933C84B4F4F/ {print $1}' <<< "${DUMP}")
L=$(awk '/0FC63DAF-8483-4772-8E79-3D69D8477DE4/ {print $1}' <<< "${DUMP}")

mkfs.vfat "${U}" -F 32
mkfs.ext4 "${L}" -F

mount -m "${L}" /mnt
mount -m "${U}" /mnt/efi

mkswap "${S}"
swapon "${S}"

# Determine additional packages to install

case "$(grep vendor_id /proc/cpuinfo)" in
    *[aA][mM][dD]*)
        packages+=(amd-ucode)
        ;;
    *[iI][nN][tT][eE][lL]*)
        packages+=(intel-ucode)
        ;;
esac

case "$(lspci -d ::03xx)" in
    *[aA][mM][dD]*)
        packages+=(vulkan-radeon)
        packages+=(xf86-video-amdgpu)
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

if grep -q snd_sof /proc/modules
then
    packages+=(sof-firmware)
fi

while ! pacstrap -K /mnt base base-devel linux linux-firmware linux-headers "${packages[@]}" - < PACKAGES
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]? "

    read -r

    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done

# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab

useradd -R /mnt -m -s "$(which zsh)" -G wheel "${LOGIN}"

echo "${R}" | passwd -R /mnt --stdin
echo "${P}" | passwd -R /mnt --stdin "${LOGIN}"

cp -r -- */ /mnt

# Generate the locales
arch-chroot /mnt locale-gen

# Set the Hardware Clock from the System Clock
arch-chroot /mnt hwclock --systohc

arch-chroot /mnt systemctl enable fstrim.timer reflector.timer
arch-chroot /mnt systemctl enable lightdm.service NetworkManager.service systemd-timesyncd.service

case "$(lsblk -n -d "${BLOCK}" -o HOTPLUG)" in
    0)
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --removable
        ;;&
    1)
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --removable
        ;;&
    *)
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
        ;;
esac
