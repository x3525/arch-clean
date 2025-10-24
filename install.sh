#!/bin/bash

online() {
    ping 1.1.1.1 -c 1 -w 1 > /dev/null 2>&1 || echo "No internet connection!"
}

w4it() {
    for u
    do
        echo "Currently waiting for $u to complete..."

        case $u in
            *.timer)
                while [ -z "$(systemctl show -P ActiveEnterTimestamp "$u")" ]
                do
                    online
                    sleep 1
                done
                ;;
            *.service)
                while [ "$(systemctl is-active "$u")" != "inactive" ]
                do
                    online
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

if [ ! -f PACKAGES ]
then
    echo "PACKAGES file not found!"
    exit 1
else
    mapfile -t pckgs < PACKAGES
fi

if [ $# -ne 2 ]
then
    printf "Usage: %s \e[4m%s\e[0m \e[4m%s\e[0m\n" "$0" "BLOCK" "LOGIN"
    exit 1
fi

bl0ck=$1
l0gin=$2

if [ ! -b "$bl0ck" ]
then
    echo "Device is not a block special!"
    exit 1
fi

LC_CTYPE=C

if [[ ! $l0gin =~ ^[a-z][a-z0-9_][a-z0-9_]{,30}$ ]]
then
    echo "Login entry is invalid!"
    exit 1
fi

us3r=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (user)")
r00t=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (root)")

if [ -z "$us3r" ] || [ -z "$r00t" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

case "$(lspci -d ::03xx)" in
    *[aA][mM][dD]*)
        pckgs+=(mesa)
        pckgs+=(vulkan-radeon)
        pckgs+=(xf86-video-ati)
        pckgs+=(xf86-video-amdgpu)
        ;;&
    *[iI][nN][tT][eE][lL]*)
        pckgs+=(mesa)
        pckgs+=(vulkan-intel)
        pckgs+=(intel-media-driver)
        pckgs+=(libva-intel-driver)
        ;;&
    *[nN][vV][iI][dD][iI][aA]*)
        echo "[1] NVIDIA kernel modules - module sources (nvidia-dkms ...)"
        echo "[2] NVIDIA open kernel modules - module sources (nvidia-open-dkms ...)"
        echo "[3] Open Source 3D acceleration driver for nVidia cards (xf86-video-nouveau ...)"
        echo "[Q]"

        while true
        do
            echo -n "What is your choice? "

            read -r

            case $REPLY in
                1)
                    pckgs+=(dkms)
                    pckgs+=(nvidia-dkms)
                    pckgs+=(libva-nvidia-driver)
                    break
                    ;;
                2)
                    pckgs+=(dkms)
                    pckgs+=(nvidia-open-dkms)
                    pckgs+=(libva-nvidia-driver)
                    break
                    ;;
                3)
                    pckgs+=(mesa)
                    pckgs+=(vulkan-nouveau)
                    pckgs+=(xf86-video-nouveau)
                    break
                    ;;
                q|Q)
                    exit 1
                    ;;
                *)
                    exit 1
                    ;;
            esac
        done
        ;;
esac

case "$(grep vendor_id /proc/cpuinfo)" in
    *[aA][mM][dD]*)
        pckgs+=(amd-ucode)
        ;;
    *[iI][nN][tT][eE][lL]*)
        pckgs+=(intel-ucode)
        ;;
esac

if grep -q snd_sof /proc/modules
then
    pckgs+=(sof-firmware)
fi

echo "Starting sanity checks..."

while [ "$(timedatectl show -P NTPSynchronized)" != "yes" ]
do
    online
    sleep 1
done

w4it reflector.service archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

set -o xtrace
set -o errexit
set -o pipefail

sfdisk -w always -W always "$bl0ck" << EOF
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
' <<< "$(sfdisk "$bl0ck" -d)" | paste -s)

mkfs.vfat "$U" -F 32
mkfs.ext4 "$L" -F

mount -m "$L" /mnt
mount -m "$U" /mnt/efi

mkswap "$S"
swapon "$S"

while ! pacstrap -K /mnt base base-devel linux linux-firmware linux-headers "${pckgs[@]}"
do
    echo -n "Alas, Pacman failed. Try agai[n]? "

    read -r

    case $REPLY in
        n|N)
            exit 1
            ;;
    esac
done

cp -r -- */ /mnt

# Generate fstab file
genfstab -U /mnt > /mnt/etc/fstab

# Create a new user
useradd -R /mnt -s /usr/bin/zsh -G wheel -m "$l0gin"

# Change password (user)
echo "$us3r" | passwd -R /mnt -s "$l0gin"

# Change password (root)
echo "$r00t" | passwd -R /mnt -s

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
