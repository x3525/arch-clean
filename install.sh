#!/bin/bash

online() {
    ping 1.1.1.1 -c 1 -W 3 > /dev/null
}

zzzz() {
    for u
    do
        echo "Currently waiting for $u to complete..."

        case $u in
            *.timer)
                while [ -z "$(systemctl show -P ActiveEnterTimestamp "$u")" ]
                do
                    online || exit 1
                    sleep 1
                done
                ;;
            *.service)
                while [ "$(systemctl is-active "$u")" != "inactive" ]
                do
                    online || exit 1
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
    printf "Usage: %s \e[4m%s\e[0m \e[4m%s\e[0m\n" "$0" "BLOCK" "LOGIN"
    exit 1
fi

Block=$1
Login=$2

if [ ! -b "$Block" ]
then
    echo "Device is not a block special!"
    exit 1
fi

LC_CTYPE=C

if [[ ! $Login =~ ^[a-z][a-z0-9_][a-z0-9_]{,30}$ ]]
then
    echo "Login entry is invalid!"
    exit 1
fi

User=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (user)")
Root=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (root)")

if [ -z "$User" ] || [ -z "$Root" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

case "$(lspci -d ::03xx)" in
    *[aA][mM][dD]*)
        Packages+=(mesa)
        Packages+=(vulkan-radeon)
        Packages+=(xf86-video-ati)
        Packages+=(xf86-video-amdgpu)
        ;;&
    *[iI][nN][tT][eE][lL]*)
        Packages+=(mesa)
        Packages+=(vulkan-intel)
        Packages+=(intel-media-driver)
        Packages+=(libva-intel-driver)
        ;;&
    *[nN][vV][iI][dD][iI][aA]*)
        echo "[1] NVIDIA kernel modules - module sources (nvidia-dkms ...)"
        echo "[2] NVIDIA open kernel modules - module sources (nvidia-open-dkms ...)"
        echo "[3] Open Source 3D acceleration driver for nVidia cards (xf86-video-nouveau ...)"

        while true
        do
            echo -n "What is your choi[c]e? "

            read -r || echo

            case $REPLY in
                1)
                    Packages+=(dkms)
                    Packages+=(nvidia-dkms)
                    Packages+=(libva-nvidia-driver)
                    break
                    ;;
                2)
                    Packages+=(dkms)
                    Packages+=(nvidia-open-dkms)
                    Packages+=(libva-nvidia-driver)
                    break
                    ;;
                3)
                    Packages+=(mesa)
                    Packages+=(vulkan-nouveau)
                    Packages+=(xf86-video-nouveau)
                    break
                    ;;
                [cC])
                    exit 1
                    ;;
            esac
        done
        ;;
esac

case "$(grep vendor_id /proc/cpuinfo)" in
    *[aA][mM][dD]*)
        Packages+=(amd-ucode)
        ;;
    *[iI][nN][tT][eE][lL]*)
        Packages+=(intel-ucode)
        ;;
esac

if grep -q snd_sof /proc/modules
then
    Packages+=(sof-firmware)
fi

echo "Starting sanity checks..."

while [ "$(timedatectl show -P NTPSynchronized)" != "yes" ]
do
    online || exit 1
    sleep 1
done

zzzz reflector.service archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

set -o xtrace
set -o errexit
set -o pipefail

sfdisk -w always -W always "$Block" << EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

read -r U S L < <(awk '
/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/ {print $1}
/0657FD6D-A4AB-43C4-84E5-0933C84B4F4F/ {print $1}
/0FC63DAF-8483-4772-8E79-3D69D8477DE4/ {print $1}
' <<< "$(sfdisk "$Block" -d)" | paste -s)

mkfs.vfat "$U" -F 32
mkfs.ext4 "$L" -F

mount -m "$L" /mnt
mount -m "$U" /mnt/efi

mkswap "$S"
swapon "$S"

while ! pacstrap -K /mnt base base-devel linux linux-firmware linux-headers "${packages[@]}" - < PACKAGES
do
    echo -n "Alas, Pacman failed. Try agai[n]? "

    read -r || echo

    case $REPLY in
        [nN])
            exit 1
            ;;
    esac
done

cp -r -- */ /mnt

# Generate fstab file
genfstab -U /mnt > /mnt/etc/fstab

# Create a new user
useradd -R /mnt -s /usr/bin/zsh -G wheel -m "$Login"

# Change password (user)
echo "$User" | passwd -R /mnt -s "$Login"

# Change password (root)
echo "$Root" | passwd -R /mnt -s

# Generate the locales
arch-chroot /mnt locale-gen

# Set the Hardware Clock from the System Clock
arch-chroot /mnt hwclock -w

# Enable timers
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable reflector.timer

# Enable services
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable lightdm.service
arch-chroot /mnt systemctl enable systemd-timesyncd.service

# Install GRUB to a device
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --removable

# Generate a GRUB configuration file
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
