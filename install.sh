#!/bin/bash

#
# A pre-configured Arch Linux installer.
#

exec 3> /tmp/xtrace.log
BASH_XTRACEFD=3
set -o xtrace -o errexit -o pipefail

atexit () {
    set +o xtrace
    unset BASH_XTRACEFD
    exec 3>&-
}

trap atexit EXIT

export SYSTEMD_PAGER=

linger () {
    for unit
    do
        echo "Waiting for $unit to complete..."

        case $unit in
            *.timer)
                while [ -z "$(systemctl -P ActiveEnterTimestamp show "$unit")" ]
                do
                    sleep 1
                done
                ;;
            *.service)
                while true
                do
                    case $(systemctl -P SubState show "$unit") in
                        dead)
                            break
                            ;;
                        exited)
                            break
                            ;;
                        failed)
                            echo "$unit failed"
                            exit 1
                            ;;
                        *)
                            sleep 1
                            ;;
                    esac
                done
                ;;
        esac
    done
}

if [ ! -d /sys/firmware/efi ]
then
    echo "System is not booted in UEFI mode"
    exit 1
fi

if [ ! -f arch-chroot.rc ]
then
    echo "arch-chroot.rc file not found"
    exit 1
fi

if [ ! -f packages ]
then
    echo "packages file not found"
    exit 1
else
    mapfile -t packages < packages
fi

if [ $# -ne 1 ]
then
    echo "Usage: $0 USERNAME"
    exit 1
fi

LC_CTYPE=C

if [[ ! $1 =~ ^[a-z][a-z0-9][a-z0-9]{0,30}$ ]]
then
    echo "Login entry is invalid"
    exit 1
else
    username=$1
fi

root=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (root)")
user=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (user)")

if [ -z "$root" ] || [ -z "$user" ]
then
    echo "Empty passwords are not allowed"
    exit 1
fi

select device in $(lsblk -dnp -o NAME -Q 'RO == 0 && TYPE == "disk"')
do
    if [ ! -b "$device" ]
    then
        continue
    fi
    break
done

# EOF
if [ ! -b "$device" ]
then
    exit 1
fi

echo "Starting sanity checks..."

while [ "$(timedatectl -P NTPSynchronized show)" != "yes" ]
do
    sleep 1
done

linger reflector.service archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

# Zap the GPT and MBR data structures
sgdisk -Z "$device"

# Manipulate disk partition table
sfdisk -w always -W always "$device" << EOF
label: gpt
unit: sectors

type=U,start=,size=1GiB
type=S,start=,size=8GiB
type=L,start=,size=
EOF

# Inform the operating system kernel of partition table changes
partprobe "$device"

# Wait for pending udev events
udevadm settle

# Dump the partitions of a device in JSON format
partitions=$(sfdisk -J "$device")

U=$(jq -r '.partitiontable.partitions[] | select(.type == "C12A7328-F81F-11D2-BA4B-00A0C93EC93B") | .node' <<< "$partitions")
S=$(jq -r '.partitiontable.partitions[] | select(.type == "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F") | .node' <<< "$partitions")
L=$(jq -r '.partitiontable.partitions[] | select(.type == "0FC63DAF-8483-4772-8E79-3D69D8477DE4") | .node' <<< "$partitions")

mkfs.ext4 "$L" -F
mkfs.vfat "$U" -F 32

mount -m -t ext4 "$L" /mnt
mount -m -t vfat "$U" /mnt/efi

mkswap "$S"
swapon "$S"

case $(lspci -d ::03xx) in
    *[aA][mM][dD]*)
        packages+=(mesa)
        packages+=(vulkan-radeon)
        packages+=(xf86-video-amdgpu)
        ;;&
    *[iI][nN][tT][eE][lL]*)
        packages+=(mesa)
        packages+=(vulkan-intel)
        packages+=(intel-media-driver)
        ;;&
    *[nN][vV][iI][dD][iI][aA]*)
        packages+=(dkms)
        packages+=(nvidia-open-dkms)
        packages+=(libva-nvidia-driver)
        ;;
esac

if systemd-detect-virt
then
    packages+=(mesa)
fi

case $(grep vendor_id /proc/cpuinfo) in
    *[aA][mM][dD]*)
        packages+=(amd-ucode)
        ;;
    *[iI][nN][tT][eE][lL]*)
        packages+=(intel-ucode)
        ;;
esac

if grep snd_sof /proc/modules
then
    packages+=(sof-firmware)
fi

while ! pacstrap -K /mnt base base-devel linux linux-firmware linux-headers "${packages[@]}"
do
    read -r -p "Alas, Pacman failed. Try agai[n]? "

    case $REPLY in
        n|N)
            exit 1
            ;;
        *)
            echo
            ;;
    esac
done

# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab

cp -r -- */ /mnt

mount -m -o bind ./.dotfiles /mnt/etc/skel

chmod -v +x \
    /mnt/etc/skel/.config/rofi/scripts/* \
    /mnt/usr/local/bin/*

# Create a new user
useradd -R /mnt -m -G wheel "$username"

# Change user password (root)
echo "$root" | passwd -R /mnt -s

# Change user password (user)
echo "$user" | passwd -R /mnt -s "$username"

# Mask units
systemctl --root=/mnt mask ctrl-alt-del.target debug-shell.service

# Enable units
systemctl --root=/mnt enable apparmor.service fstrim.timer NetworkManager.service reflector.timer systemd-timesyncd.service ufw.service

# Directly interact with the new system's environment, tools, and configurations
arch-chroot -S /mnt /usr/bin/bash < 'EOF'
# Set the Hardware Clock from the System Clock
hwclock -w
# Generate localization files from templates
locale-gen
# Generate initramfs images based on all existing presets
mkinitcpio -P
# Install GRUB to a device
grub-install --target=x86_64-efi --efi-directory=/efi
# Generate the main configuration file for GRUB
grub-mkconfig -o /boot/grub/grub.cfg
# ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable
# gcc
gcc -lX11 -o /usr/local/bin/XkbLayout /usr/local/src/XkbLayout.c
EOF
