#!/bin/bash -xe

function online() {
    ping ping.archlinux.org -c 1 -w 1 > /dev/null
}

function linger() {
    for unit
    do
        echo "Currently waiting for $unit to complete..."

        case $unit in
            *.timer)
                while [ -z "$(systemctl show -P ActiveEnterTimestamp "$unit")" ]
                do
                    online
                    sleep 1
                done
                ;;
            *.service)
                while [ "$(systemctl is-active "$unit")" != "inactive" ]
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
    mapfile -t packages < PACKAGES
fi

if [ $# -ne 1 ]
then
    printf "Usage: %s $(tput smul)%s$(tput sgr0)\n" "$0" "NAME"
    exit 1
fi

LC_CTYPE=C

if [[ ! $1 =~ ^[a-z][a-z0-9_][a-z0-9_]{,30}$ ]]
then
    echo "Login entry is invalid!"
    exit 1
else
    name=$1
fi

user=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (user)")
root=$(systemd-ask-password --timeout=0 --echo=yes --emoji=no "Enter a password (root)")

if [ -z "$user" ] || [ -z "$root" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

select disk in $(lsblk -dnp -o NAME)
do
    if [ ! -b "$disk" ]
    then
        continue
    fi
    break
done

echo "Starting sanity checks..."

while [ "$(timedatectl show -P NTPSynchronized)" != "yes" ]
do
    online
    sleep 1
done

linger reflector.service archlinux-keyring-wkd-sync.timer archlinux-keyring-wkd-sync.service

# Zap (destroy) the GPT and MBR data structures
sgdisk "$disk" -Z

# Manipulate disk partition table
sfdisk "$disk" -w always -W always << EOF
label: gpt
unit: sectors

type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,start=,size=1GiB
type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F,start=,size=8GiB
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4,start=,size=
EOF

# Inform the operating system kernel of partition table changes
partprobe "$disk"

# Wait for pending udev events
udevadm settle

read -r U S L < <(awk '
BEGIN {IGNORECASE=1}
/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/ {print $1}
/0657FD6D-A4AB-43C4-84E5-0933C84B4F4F/ {print $1}
/0FC63DAF-8483-4772-8E79-3D69D8477DE4/ {print $1}
' <<< "$(sfdisk "$disk" -d)" | paste -s)

mkfs.vfat "$U" -F 32
mkfs.ext4 "$L" -F

mount -m "$L" /mnt
mount -m "$U" /mnt/efi

mkswap "$S"
swapon "$S"

case "$(lspci -d ::03xx)" in
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
        packages+=(dkms)
        packages+=(nvidia-open-dkms)
        packages+=(libva-nvidia-driver)
        ;;
esac

if systemd-detect-virt -q
then
    packages+=(mesa)
fi

case "$(grep vendor_id /proc/cpuinfo)" in
    *[aA][mM][dD]*)
        packages+=(amd-ucode)
        ;;
    *[iI][nN][tT][eE][lL]*)
        packages+=(intel-ucode)
        ;;
esac

if grep -q snd_sof /proc/modules
then
    packages+=(sof-firmware)
fi

while ! pacstrap -K /mnt base linux linux-firmware linux-headers "${packages[@]}"
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

# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab

# Create a new user
useradd -R /mnt -s /usr/bin/zsh -m -G wheel "$name"

# Change user password (user)
echo "$user" | passwd -s -R /mnt "$name"

# Change user password (root)
echo "$root" | passwd -s -R /mnt

# Generate localization files from templates
arch-chroot /mnt locale-gen

# Set the Hardware Clock from the System Clock
arch-chroot /mnt hwclock -w

# Enable timers
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable reflector.timer

# Enable services
arch-chroot /mnt systemctl enable getty@tty1.service
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable systemd-timesyncd.service

# Install GRUB to a device
arch-chroot /mnt grub-install --efi-directory=/efi --target=x86_64-efi

# Generate a GRUB configuration file
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Recursively unmount each specified directory
umount -R /mnt
