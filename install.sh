#!/bin/bash

e ()
{
    exit 1
}

unmount ()
{
    umount -q -R "$MOUNT"  &> /dev/null

    return 0
}

partition ()
{
    sfdisk "$BLOCK" << EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF
}

format ()
{
    mkfs.ext4 "${partitions[1]}" -F
    mkfs.fat  "${partitions[0]}" -F 32
}

if [ "$(cat /sys/firmware/efi/fw_platform_size)" -ne 64 ]
then
    echo "System is not booted in 64-bit UEFI mode!"
    e
fi

if [ $# -ne 2 ]
then
    echo "Usage: $0 BLOCK MOUNT"
    e
fi

BLOCK=$1
MOUNT=$2/5967328296455939

if [ ! -b "$BLOCK" ]
then
    echo "Device is not a block special!"
    e
fi

read -r -p "Login:" LOGIN < /dev/tty

if ! grep -qP '^[a-z][a-z0-9][a-z0-9]{,30}$' <<< "$LOGIN"
then
    echo "Given login name is invalid!"
    e
fi

set +a; read -s -r -p "Password:" PASSUSER < /dev/tty; set -a; echo
set +a; read -s -r -p "Password:" USERPASS < /dev/tty; set -a; echo

if [ -z "$PASSUSER" ] || [ "$PASSUSER" != "$USERPASS" ]
then
    echo "Passwords do not match!"
    e
fi

set +a; read -s -r -p "Password (root):" PASSROOT < /dev/tty; set -a; echo
set +a; read -s -r -p "Password (root):" ROOTPASS < /dev/tty; set -a; echo

if [ -z "$PASSROOT" ] || [ "$PASSROOT" != "$ROOTPASS" ]
then
    echo "Passwords do not match!"
    e
fi

if ! ping -q -c 1 -w 2 "$(ip route | grep default | cut -d ' ' -f 3)" &> /dev/null
then
    echo "Network is unreachable!"
    e
fi

trap unmount EXIT

unmount

trap e ERR

for part in $(sfdisk --dump "$BLOCK" | grep start | cut -d ':' -f 1 | tr -d ' ')
do
    partitions+=("$part")
done

[ -d "$MOUNT" ] || partition
[ -d "$MOUNT" ] || format

# Mount the file systems
mount "${partitions[1]}" -m "$MOUNT"
mount "${partitions[0]}" -m "$MOUNT"/boot/efi

# Wait for time synchronization to complete...
while [ "$(timedatectl show --property NTPSynchronized --value)" != "yes" ]
do
    echo -n .
    sleep 2
done

# Wait for automatic mirror selection to complete...
while [ "$(systemctl is-active reflector.service)" != "inactive" ]
do
    echo -n .
    sleep 2
done

# Wait for Arch Linux keyring synchronization to complete...
while [ "$(systemctl is-active archlinux-keyring-wkd-sync.service)" != "inactive" ]
do
    echo -n .
    sleep 2
done

echo

# Determine additional packages to install
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
            packages+=(mesa)
            packages+=(rocm-opencl-runtime)
            packages+=(vulkan-radeon)
            packages+=(xf86-video-amdgpu)
            packages+=(xf86-video-ati)
            ;;&
        *[iI][nN][tT][eE][lL]*)
            packages+=(intel-compute-runtime)
            packages+=(intel-media-driver)
            packages+=(libva-intel-driver)
            packages+=(mesa)
            packages+=(vulkan-intel)
            ;;&
        *[nN][vV][iI][dD][iI][aA]*)
            packages+=(mesa)
            packages+=(opencl-nvidia)
            packages+=(xf86-video-nouveau)
            ;;&
    esac
fi

# Install packages
while ! pacstrap -K "$MOUNT" base linux linux-firmware "${packages[@]}" - < PACKAGES
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r < /dev/tty

    case $REPLY in
        [nN]*)
            e
            ;;
    esac
done

# Generate an fstab file
genfstab -U "$MOUNT" > "$MOUNT"/etc/fstab

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Istanbul "$MOUNT"/etc/localtime

# Set the Hardware Clock from the System Clock
hwclock --systohc --adjfile "$MOUNT"/etc/adjtime

# Add login
if ! id "$LOGIN" &> /dev/null
then
    useradd -R "$MOUNT" -m -G wheel -s "$(which zsh)" "$LOGIN"
fi

# Change user passwords
echo -n "$PASSROOT" | passwd -R "$MOUNT" --stdin
echo -n "$PASSUSER" | passwd -R "$MOUNT" --stdin "$LOGIN"

# Prepare the chroot jail
mount -t proc  /proc "$MOUNT"/proc
mount -t sysfs /sys  "$MOUNT"/sys
mount --bind   /dev  "$MOUNT"/dev
mount --bind   /sys/firmware/efi/efivars "$MOUNT"/sys/firmware/efi/efivars

# Verify the master keys
chroot "$MOUNT" pacman-key --init
chroot "$MOUNT" pacman-key --populate

# Generate the locales
chroot "$MOUNT" locale-gen

# Enable timers
chroot "$MOUNT" systemctl enable fstrim.timer
chroot "$MOUNT" systemctl enable reflector.timer

# Enable services
chroot "$MOUNT" systemctl enable lightdm.service
chroot "$MOUNT" systemctl enable NetworkManager.service
chroot "$MOUNT" systemctl enable systemd-timesyncd.service

# Disable services
chroot "$MOUNT" systemctl disable autorandr-lid-listener.service
chroot "$MOUNT" systemctl disable autorandr.service

# GRUB installation
case "$(lsblk "$BLOCK" -o HOTPLUG -d -n)" in
    0)
        chroot "$MOUNT" grub-install --target=x86_64-efi --efi-directory=/boot/efi
        ;;&
    1)
        chroot "$MOUNT" grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
        ;;&
    *)
        chroot "$MOUNT" grub-mkconfig -o /boot/grub/grub.cfg
        ;;
esac
