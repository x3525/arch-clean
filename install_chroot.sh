#!/bin/bash

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Download Oh My Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# Download Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Copy files !!!
cp -r home/. ~
sudo cp -r \\/. / --no-preserve=ownership

# SUDOERS PERMISSIONS
sudo chmod 0750 /etc/sudoers.d
sudo chmod 0640 /etc/sudoers.d/*

# Change default shell
sudo chsh "$USER" --shell "$(which zsh)"

# Generate the locales
sudo locale-gen

# Build font information cache files
fc-cache -fv

# Enable the corresponding devices
rfkill block wlan

# Disable the corresponding devices
rfkill block bluetooth

# Enable and start the network synchronization service
sudo timedatectl set-ntp true

# Set the time zone
sudo ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

# Set the Hardware Clock from the System Clock
sudo hwclock --systohc

# Enable timers
systemctl --user enable battery-notification.timer
sudo systemctl enable fstrim.timer
sudo systemctl enable reflector.timer

# Enable services
sudo systemctl enable lightdm.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable systemd-timesyncd.service

# Disable services
sudo systemctl disable autorandr-lid-listener.service
sudo systemctl disable autorandr.service
