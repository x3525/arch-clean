#!/bin/bash

if [ "$(id -u)" -eq 0 ]
then
    echo "You are root!"
    exit 1
fi

# Verify the master keys
#....................... sudo pacman-key --init
#....................... sudo pacman-key --populate

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Download Oh My Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# Download Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Copy files !!!
cp -r home/. ~
#....................... sudo cp -r \\/. / --no-preserve=ownership

# Build font information cache files
fc-cache -fv

# Enable the corresponding devices
rfkill unblock wlan

# Disable the corresponding devices
rfkill block bluetooth

# Enable and start the network synchronization service
#....................... sudo timedatectl set-ntp true

# Enable timers
systemctl --user enable battery-notification.timer
