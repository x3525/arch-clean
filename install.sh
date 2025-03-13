#!/bin/bash

e ()
{
    exit 1
}

unmount ()
{
    {
        swapoff -a
        umount -q -R "$MOUNT"
    } &> /dev/null

    return 0
}

if [ "$(cat /sys/firmware/efi/fw_platform_size)" != "64" ]
then
    echo "System is not booted in 64-bit UEFI mode!"
    e
fi

if [ $# -ne 3 ]
then
    echo "Usage: $0 BLOCK MOUNT LOGIN"
    e
fi

BLOCK=$1
MOUNT=$2
LOGIN=$3

if [ ! -b "$BLOCK" ]
then
    echo "Device is not a block special!"
    e
fi

if ! mkdir -p "$MOUNT" &> /dev/null
then
    echo "Cannot create the mount directory!"
    e
fi

if ! grep -qP '^[a-z][a-z0-9]{,15}$' <<< "$LOGIN"
then
    echo "Login name is invalid!"
    e
fi

set +a; read -s -r -p "Enter password:" PASSUSER < /dev/tty; set -a; echo
set +a; read -s -r -p "Enter password:" USERPASS < /dev/tty; set -a; echo

if [ -z "$PASSUSER" ] || [ "$PASSUSER" != "$USERPASS" ]
then
    echo "Passwords do not match!"
    e
fi

set +a; read -s -r -p "Enter password (root):" PASSROOT < /dev/tty; set -a; echo
set +a; read -s -r -p "Enter password (root):" ROOTPASS < /dev/tty; set -a; echo

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

# Erase all available signatures
wipefs -f -a "$BLOCK"*

# Disk partition
sfdisk "$BLOCK" <<- EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

# Format the partitions
partitions=()

for partition in $(sfdisk --dump "$BLOCK" | grep start | cut -d ':' -f 1 | tr -d ' ')
do
    partitions+=("$partition")
done

mkfs.ext4 "${partitions[2]}" -F
mkfs.fat  "${partitions[0]}" -F 32
mkswap    "${partitions[1]}"

# Mount the file systems
mount     "${partitions[2]}" "$MOUNT"
mount     "${partitions[0]}" "$MOUNT"/boot/efi -m
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
while ! pacstrap -K "$MOUNT" base linux linux-firmware "${PACKAGES[@]}"
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
hwclock --systohc --adjfile="$MOUNT"/etc/adjtime

# User management
if ! id "$LOGIN" &> /dev/null
then
    useradd -R "$MOUNT" -m -G wheel -s "$(which zsh)" "$LOGIN"
fi

printf '%s' "$PASSROOT" | passwd -R "$MOUNT" --stdin
printf '%s' "$PASSUSER" | passwd -R "$MOUNT" --stdin "$LOGIN"

# Prepare the chroot jail
mount -t proc  /proc "$MOUNT"/proc
mount -t sysfs /sys  "$MOUNT"/sys
mount -o bind  /dev  "$MOUNT"/dev
mount -o bind  /sys/firmware/efi/efivars "$MOUNT"/sys/firmware/efi/efivars

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
