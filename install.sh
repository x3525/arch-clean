#!/bin/bash

if [ "$(cat /sys/firmware/efi/fw_platform_size)" != "64" ]
then
    echo "System is not booted in 64-bit UEFI mode!"
    exit 1
fi

if [ $# -ne 3 ]
then
    echo "Usage: $0 BLOCK MOUNT LOGIN"
    exit 1
fi

BLOCK=$1
MOUNT=$2
LOGIN=$3

if [ ! -b "$BLOCK" ]
then
    echo "Device is not a block special!"
    exit 1
fi

if [ ! -d "$MOUNT" ] && ! mkdir -p "$MOUNT" 2> /dev/null
then
    echo "Cannot create the mount directory!"
    exit 1
fi

if ! grep -qP '^[a-z][a-z0-9]{,15}$' <<< "$LOGIN"
then
    echo "Login name is invalid!"
    exit 1
fi

printf "Enter password:"; set +a; read -r -s PASS_USER < /dev/tty; set -a; echo
printf "Enter password:"; set +a; read -r -s USER_PASS < /dev/tty; set -a; echo

if [ "$PASS_USER" != "$USER_PASS" ]
then
    echo "Passwords do not match!"
    exit 1
fi

printf "Enter password (root):"; set +a; read -r -s PASS_ROOT < /dev/tty; set -a; echo
printf "Enter password (root):"; set +a; read -r -s ROOT_PASS < /dev/tty; set -a; echo

if [ "$PASS_ROOT" != "$ROOT_PASS" ]
then
    echo "Passwords do not match!"
    exit 1
fi

if [ -z "$PASS_ROOT" ] || [ -z "$PASS_USER" ]
then
    echo "Empty passwords are not allowed!"
    exit 1
fi

if ! ping -q -c 1 -w 2 "$(ip route | grep default | cut -d ' ' -f 3)" &> /dev/null
then
    echo "Network is unreachable!"
    exit 1
fi

unmount()
{
    {
        swapoff -a
        umount -q -R "$MOUNT"
    } &> /dev/null
}

trap unmount EXIT

unmount

# Erase all available signatures
wipefs -f -a "$1"*

# Disk partiton
sfdisk "$1" <<- EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$1" | grep start | cut -d ':' -f 1 | tr -d ' ')
do
    partitions+=("$partition")
done

mkfs.ext4 "${partitions[2]}" -F
mkfs.fat  "${partitions[0]}" -F 32
mkswap    "${partitions[1]}"

# Mount the file systems
mount     "${partitions[2]}" /mnt
mount     "${partitions[0]}" /mnt/boot/efi -m
swapon    "${partitions[1]}"

echo "Waiting for time synchronization to complete..."

while [ "$(timedatectl show --property=NTPSynchronized --value)" != "yes" ]
do
    sleep 1
done

echo "Waiting for automatic mirror selection to complete..."

while [ "$(systemctl is-active reflector.service)" != "inactive" ]
do
    sleep 1
done

echo "Waiting for Arch Linux keyring synchronization to complete..."

while [ "$(systemctl is-active archlinux-keyring-wkd-sync.service)" != "inactive" ]
do
    sleep 1
done

# Determine additional packages to install
#PACKAGES=()
PACKAGES=(7zip adwaita-cursors alacritty arandr ascii autorandr bind brightnessctl cifs-utils cmake cronie cups curl debugedit dex dmenu dos2unix dosfstools dunst efibootmgr exfat-utils fakeroot feh ffmpeg firefox flameshot flatpak freerdp2 fuse2 gcc gdb git github-cli glab go grub gst-plugin-pipewire gtk3 gtk4 gvfs hashcat hashcat-utils hcxtools hsetroot hydra i3-wm i3lock i3status inetutils iwd john jq kcolorchooser kolourpaint lib32-gcc-libs lib32-glibc libinput libnotify libpulse libreoffice-still libwebp lightdm lightdm-gtk-greeter linux-headers lxsession-gtk3 make man-db man-pages mariadb mate-calc medusa metasploit net-snmp net-tools networkmanager nfs-utils nmap noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ntfs-3g openbsd-netcat openldap openssh openvpn pacman-contrib pacutils pamixer papirus-icon-theme pavucontrol perl-file-mimeinfo php picom pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl plocate pocl polkit postgresql proxychains-ng python python-pip qt6-multimedia qt6-multimedia-ffmpeg rdesktop redis reflector rofi ruby samba scrot shellcheck smartmontools smbclient socat speech-dispatcher sqlmap sshpass sshuttle sudo tcpdump thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman tidy tk traceroute trash-cli tree ttf-jetbrains-mono ttf-meslo-nerd udisks2 unzip upx usbutils vim vlc wget which whois wireless_tools wireplumber wireshark-qt wpa_supplicant xarchiver xdg-utils xdotool xorg-server xorg-xev xorg-xinit xorg-xinput xorg-xrandr xsel xss-lock xterm zip zsh)

if grep -q snd_sof /proc/modules
then
    PACKAGES+=(sof-firmware)
fi

if [ "$(systemd-detect-virt)" != "none" ]
then
    PACKAGES+=(mesa)
    PACKAGES+=(xf86-video-vmware)
else
    case "$(lspci -d ::03xx)" in
        *[aA][mM][dD]*)
            PACKAGES+=(mesa)
            PACKAGES+=(rocm-opencl-runtime)
            PACKAGES+=(vulkan-radeon)
            PACKAGES+=(xf86-video-amdgpu)
            PACKAGES+=(xf86-video-ati)
            ;;&
        *[iI][nN][tT][eE][lL]*)
            PACKAGES+=(intel-compute-runtime)
            PACKAGES+=(intel-media-driver)
            PACKAGES+=(libva-intel-driver)
            PACKAGES+=(mesa)
            PACKAGES+=(vulkan-intel)
            ;;&
        *[nN][vV][iI][dD][iI][aA]*)
            PACKAGES+=(mesa)
            PACKAGES+=(opencl-nvidia)
            PACKAGES+=(xf86-video-nouveau)
            ;;&
    esac
fi

# Install packages
while ! pacstrap -K /mnt base linux linux-firmware "${PACKAGES[@]}"
do
    echo -n "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r < /dev/tty
    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done

# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Istanbul /mnt/etc/localtime

# Set the Hardware Clock from the System Clock
hwclock --systohc --adjfile=/mnt/etc/adjtime

# User management
if ! id "$2" &> /dev/null
then
    useradd -R /mnt -m -G wheel -s "$(which zsh)" "$2"
fi

printf '%s' "$PASS_ROOT" | passwd -R /mnt --stdin
printf '%s' "$PASS_USER" | passwd -R /mnt --stdin "$2"

# Prepare the chroot jail
mount -t proc  /proc /mnt/proc
mount -t sysfs /sys  /mnt/sys
mount -o bind  /dev  /mnt/dev
mount -o bind  /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars

# Generate the locales
chroot /mnt locale-gen

# Enable timers
chroot /mnt systemctl enable fstrim.timer
chroot /mnt systemctl enable reflector.timer

# Enable services
chroot /mnt systemctl enable lightdm.service
chroot /mnt systemctl enable NetworkManager.service
chroot /mnt systemctl enable systemd-timesyncd.service

# Disable services
chroot /mnt systemctl disable autorandr-lid-listener.service
chroot /mnt systemctl disable autorandr.service

# GRUB installation
case "$(lsblk "$1" -o HOTPLUG -d -n)" in
    0)
        chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
        ;;&
    1)
        chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
        ;;&
    *)
        chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
        ;;
esac
