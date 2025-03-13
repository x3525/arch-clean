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

if [ "$(cat /sys/firmware/efi/fw_platform_size)" -ne 64 ]
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

# Disk partition
sfdisk "$BLOCK" <<- EOF
label: gpt
unit: sectors

start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=     2099200, size=    33554432, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
start=    35653632,                    type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

# Format the partitions
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

# Wait for time synchronization to complete...
while [ "$(timedatectl show --property=NTPSynchronized --value)" != "yes" ]
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

packages+=(7zip)
packages+=(adwaita-cursors)
packages+=(alacritty)
packages+=(arandr)
packages+=(ascii)
packages+=(autorandr)
packages+=(bind)
packages+=(brightnessctl)
packages+=(cifs-utils)
packages+=(cmake)
packages+=(cronie)
packages+=(cups)
packages+=(curl)
packages+=(debugedit)
packages+=(dex)
packages+=(dmenu)
packages+=(dos2unix)
packages+=(dosfstools)
packages+=(dunst)
packages+=(efibootmgr)
packages+=(exfat-utils)
packages+=(fakeroot)
packages+=(feh)
packages+=(ffmpeg)
packages+=(firefox)
packages+=(flameshot)
packages+=(flatpak)
packages+=(freerdp2)
packages+=(fuse2)
packages+=(gcc)
packages+=(gdb)
packages+=(git)
packages+=(github-cli)
packages+=(glab)
packages+=(go)
packages+=(grub)
packages+=(gst-plugin-pipewire)
packages+=(gtk3)
packages+=(gtk4)
packages+=(gvfs)
packages+=(hashcat)
packages+=(hashcat-utils)
packages+=(hcxtools)
packages+=(hsetroot)
packages+=(hydra)
packages+=(i3-wm)
packages+=(i3lock)
packages+=(i3status)
packages+=(inetutils)
packages+=(iwd)
packages+=(john)
packages+=(jq)
packages+=(kcolorchooser)
packages+=(kolourpaint)
packages+=(lib32-gcc-libs)
packages+=(lib32-glibc)
packages+=(libinput)
packages+=(libnotify)
packages+=(libpulse)
packages+=(libreoffice-still)
packages+=(libwebp)
packages+=(lightdm)
packages+=(lightdm-gtk-greeter)
packages+=(linux-headers)
packages+=(lxsession-gtk3)
packages+=(make)
packages+=(man-db)
packages+=(man-pages)
packages+=(mariadb)
packages+=(mate-calc)
packages+=(medusa)
packages+=(metasploit)
packages+=(net-snmp)
packages+=(net-tools)
packages+=(networkmanager)
packages+=(nfs-utils)
packages+=(nmap)
packages+=(noto-fonts)
packages+=(noto-fonts-cjk)
packages+=(noto-fonts-emoji)
packages+=(noto-fonts-extra)
packages+=(ntfs-3g)
packages+=(openbsd-netcat)
packages+=(openldap)
packages+=(openssh)
packages+=(openvpn)
packages+=(pacman-contrib)
packages+=(pacutils)
packages+=(pamixer)
packages+=(papirus-icon-theme)
packages+=(pavucontrol)
packages+=(perl-file-mimeinfo)
packages+=(php)
packages+=(picom)
packages+=(pipewire)
packages+=(pipewire-alsa)
packages+=(pipewire-jack)
packages+=(pipewire-pulse)
packages+=(playerctl)
packages+=(plocate)
packages+=(pocl)
packages+=(polkit)
packages+=(postgresql)
packages+=(proxychains-ng)
packages+=(python)
packages+=(python-pip)
packages+=(qt6-multimedia)
packages+=(qt6-multimedia-ffmpeg)
packages+=(rdesktop)
packages+=(redis)
packages+=(reflector)
packages+=(rofi)
packages+=(ruby)
packages+=(samba)
packages+=(scrot)
packages+=(shellcheck)
packages+=(smartmontools)
packages+=(smbclient)
packages+=(socat)
packages+=(speech-dispatcher)
packages+=(sqlmap)
packages+=(sshpass)
packages+=(sshuttle)
packages+=(sudo)
packages+=(tcpdump)
packages+=(thunar)
packages+=(thunar-archive-plugin)
packages+=(thunar-media-tags-plugin)
packages+=(thunar-volman)
packages+=(tidy)
packages+=(tk)
packages+=(traceroute)
packages+=(trash-cli)
packages+=(tree)
packages+=(ttf-jetbrains-mono)
packages+=(ttf-meslo-nerd)
packages+=(udisks2)
packages+=(unzip)
packages+=(upx)
packages+=(usbutils)
packages+=(vim)
packages+=(vlc)
packages+=(wget)
packages+=(which)
packages+=(whois)
packages+=(wireless_tools)
packages+=(wireplumber)
packages+=(wireshark-qt)
packages+=(wpa_supplicant)
packages+=(xarchiver)
packages+=(xdg-utils)
packages+=(xdotool)
packages+=(xorg-server)
packages+=(xorg-xev)
packages+=(xorg-xinit)
packages+=(xorg-xinput)
packages+=(xorg-xrandr)
packages+=(xsel)
packages+=(xss-lock)
packages+=(xterm)
packages+=(zip)
packages+=(zsh)

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
while ! pacstrap -K "$MOUNT" base linux linux-firmware "${packages[@]}"
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

# /etc
cat <<- EOF | tee "$MOUNT"/etc/hostname
archlinux
EOF
cat <<- EOF | tee "$MOUNT"/etc/hosts
127.0.0.1       localhost
::1             localhost
127.0.0.1       archlinux
EOF
cat <<- EOF | tee "$MOUNT"/etc/locale.conf
LANG=en_US.UTF-8
LC_TIME=tr_TR.UTF-8
EOF
cat <<- EOF | tee "$MOUNT"/etc/locale.gen
en_US.UTF-8 UTF-8
tr_TR.UTF-8 UTF-8
EOF
cat <<- EOF | tee "$MOUNT"/etc/vconsole.conf
KEYMAP=trq
EOF
cat <<- EOF | tee "$MOUNT"/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
    Identifier "Keyboard"
    MatchIsKeyboard "true"
    Option "XkbLayout" "tr"
EndSection
EOF
cat <<- EOF | tee "$MOUNT"/etc/X11/xorg.conf.d/10-monitor.conf
Section "Extensions"
    Option "DPMS" "false"
EndSection
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "DontVTSwitch" "false"
    Option "DontZap" "true"
    Option "OffTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
EndSection
EOF
cat <<- EOF | tee "$MOUNT"/etc/X11/xorg.conf.d/40-touchpad.conf
Section "InputClass"
    Identifier "Touchpad"
    Driver "libinput"
    MatchDevicePath "/dev/input/event*"
    MatchIsTouchpad "true"
    Option "AccelSpeed" "0.1"
    Option "DisableWhileTyping" "true"
    Option "HorizontalScrolling" "true"
    Option "NaturalScrolling" "true"
    Option "ScrollMethod" "twofinger"
    Option "Tapping" "true"
    Option "TappingDrag" "true"
EndSection
EOF
cat <<- EOF | tee "$MOUNT"/etc/bluetooth/input.conf
[General]
UserspaceHID=true
EOF
cat <<- EOF | tee "$MOUNT"/etc/gtk-3.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme = true
gtk-button-images = true
gtk-cursor-theme-name = Adwaita
gtk-cursor-theme-size = 16
gtk-enable-event-sounds = true
gtk-enable-input-feedback-sounds = true
gtk-font-name = Noto Sans 12
gtk-icon-theme-name = Papirus
gtk-menu-images = true
EOF
cat <<- EOF | tee "$MOUNT"/etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
active-monitor = #cursor
clock-format = %H:%M:%S
font-name = Noto Sans Mono 10
indicators = ~session;~separator;~layout;~spacer;~clock;~spacer;~power
screensaver-timeout = 0
EOF
cat <<- EOF | tee "$MOUNT"/etc/lightdm/lightdm.conf.d/00-manual.conf
[Seat:*]
allow-guest=false
greeter-allow-guest=false
greeter-hide-users=true
greeter-show-manual-login=true
EOF
cat <<- EOF | tee "$MOUNT"/etc/modprobe.d/blacklist-bluetooth.conf
blacklist bluetooth
blacklist btusb
blacklist hidp
EOF
cat <<- EOF | tee "$MOUNT"/etc/modules-load.d/uhid.conf
uhid
EOF
cat <<- EOF | tee "$MOUNT"/etc/polkit-1/rules.d/power.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-ignore-inhibit" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
        action.id == "org.freedesktop.login1.power-off" ||
        action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
        action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
        action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
        action.id == "org.freedesktop.login1.reboot-multiple-sessions"
    ) {
        return polkit.Result.YES;
    }
});
EOF
cat <<- EOF | tee "$MOUNT"/etc/security/faillock.conf
silent
deny = 5
fail_interval = 900
unlock_time = 300
EOF
cat <<- EOF | tee "$MOUNT"/etc/systemd/logind.conf
[Login]
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
HandlePowerKey=ignore
HandleRebootKey=ignore
HandleSuspendKey=ignore
IdleAction=ignore
EOF
cat <<- EOF | tee "$MOUNT"/etc/systemd/sleep.conf
[Sleep]
AllowHibernation=no
AllowHybridSleep=no
AllowSuspend=no
AllowSuspendThenHibernate=no
EOF
cat <<- EOF | tee "$MOUNT"/etc/systemd/system.conf
[Manager]
DefaultTimeoutStopSec=30s
EOF
cat <<- EOF | tee "$MOUNT"/etc/xdg/reflector/reflector.conf
--country Germany
--download-timeout 120
--latest 10
--protocol https
--save /etc/pacman.d/mirrorlist
--sort rate
EOF

# /usr
cat <<- EOF | tee "$MOUNT"/usr/share/icons/default/index.theme
[Icon Theme]
Inherits=Papirus
EOF

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
mount -o bind  /dev  "$MOUNT"/dev
mount -o bind  /sys/firmware/efi/efivars "$MOUNT"/sys/firmware/efi/efivars

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
