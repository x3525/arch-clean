#!/bin/bash

if [ "$(id -u)" -eq 0 ]
then
    echo "You are root."
    exit 1
fi

# Verify the master keys
sudo pacman-key --init
sudo pacman-key --populate

# Install the Sublime Text GPG key
curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo pacman-key --add -
sudo pacman-key --lsign-key 8A8F901A

# Add Sublime Text repo to Pacman config
! grep -q 'sublime-text' /etc/pacman.conf && cat << EOF | sudo tee -a /etc/pacman.conf
[sublime-text]
Server = https://download.sublimetext.com/arch/stable/x86_64
EOF

# Install packages
while ! cut -d':' -f2 < PACKAGES | sudo pacman -Syu --noconfirm --needed -
do
    echo "Alas, Pacman failed. Tr[y] agai[n]?"
    read -r x
    case $x in
        [nN]|[nN][oO])
            exit 1
            ;;
    esac
done

# Install Fusuma
sudo gem install --conservative --no-user-install fusuma

# Install vim-plug plugin manager
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install VIM plugins
vim +PlugInstall +qa

# Install OMZ
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Download OMZ plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# Download Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Add user to the necessary groups
sudo usermod -a -G video,input,wheel "$USER"

# Change default shell
sudo chsh "$USER" --shell "$(which zsh)"

# Unblock wireless devices
rfkill unblock all

# Copy files
cp -R my/. ~
sudo cp -R system/. / --no-preserve=ownership

# Generate the locales
sudo locale-gen

# Build font information cache files
fc-cache -fv /usr/share/fonts

# Enable timers
sudo systemctl enable fstrim.timer
sudo systemctl enable reflector.timer

# Enable services
sudo systemctl enable autorandr.service
sudo systemctl enable bluetooth.service
sudo systemctl enable cronie.service
sudo systemctl enable dhcpcd.service
sudo systemctl enable iwd.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable systemd-timesyncd.service
