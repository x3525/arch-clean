#!/bin/bash

if [ "$(id -u)" -eq 0 ]
then
    echo "You are root."
    exit 1
fi

# Verify the master keys
sudo pacman-key --init
sudo pacman-key --populate

# Install packages
while ! cat -- PACKAGES | sudo pacman -Syu --noconfirm --needed -
do
    echo "Alas, Pacman failed. Tr[Y] agai[n]?"
    read -r
    case $REPLY in
        [nN]*)
            exit 1
            ;;
    esac
done

# Install yay AUR helper
git clone https://aur.archlinux.org/yay.git
makepkg -D yay -si --noconfirm --needed
rm -rf yay

# Install OMZ
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Download OMZ plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# Download Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Copy files <--
cp -r my/. ~
sudo cp -r system/. / --no-preserve=ownership

# Download vim-plug plugin manager
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install Vim plugins
vim +PlugInstall +qa

# Change default shell
sudo chsh "$USER" --shell "$(which zsh)"

# Update GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Generate the locales
sudo locale-gen

# Build font information cache files
fc-cache -fv

# Block bluetooth
rfkill block bluetooth

# Enable timers
systemctl --user enable battery-notification-reset.timer
systemctl --user enable battery-notification.timer
sudo systemctl enable fstrim.timer
sudo systemctl enable reflector.timer

# Enable services
sudo systemctl enable cronie.service
sudo systemctl enable lightdm.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable systemd-timesyncd.service

# Disable services
sudo systemctl disable autorandr-lid-listener.service
sudo systemctl disable autorandr.service
