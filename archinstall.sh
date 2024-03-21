#!/bin/bash

sudo pacman -Syu --noconfirm

#sudo pacman -S --noconfirm reflector rsync

if grep -q "Artix Linux" /etc/os-release; then
    # Commands to run if the system is Arch Linux
    echo "This is Artix Linux."
    git clone https://github.com/smileofthesun/artixrepo ~/artixrepo
    cd ~/artixrepo
    sudo ./artix-archlinux-support
else
    # Commands to run if the system is not Arch Linux
    echo "This is not Artix Linux."
fi

echo "!!!!! SKIP ON ARTIX !!!!!
Enter your desired country for the mirrorlist (leave empty to skip):"
read country

if [ -n "$country" ]; then
    sudo reflector --country "$country" --sort rate --save /etc/pacman.d/mirrorlist
else
    echo "Skipping mirrorlist configuration..."
fi

cd ~/archinstall

awk '!/^#/ {print $1}' ~/archinstall/packagelist | sudo pacman -S --noconfirm --needed -

mkdir -p ~/documents/git 

git clone https://github.com/aqua28/dwm.git ~/documents/git/dwm
git clone https://github.com/aqua28/st.git ~/documents/git/st
git clone https://github.com/aqua28/dmenu.git ~/documents/git/dmenu
git clone https://github.com/aqua28//slock.git ~/documents/git/slock
git clone https://github.com/aqua28/slstatus.git  ~/documents/git/slstatus
git clone https://github.com/aqua28/nsxiv.git ~/documents/git/nsxiv

sudo make -C ~/.local/src/dwm install
sudo make -C ~/.local/src/st install
sudo make -C ~/.local/src/dmenu install
sudo make -C ~/.local/src/slock install
sudo make -C ~/.local/src/slstatus install
sudo make -C ~/.local/src/nsxiv install

git clone https://github.com/smileofthesun/dotfiles.git ~/dotfiles
rsync -av --exclude='.git' ~/dotfiles/ ~/
rm -rf ~/dotfiles
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.config/shell/fast-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.config/shell/zsh-autosuggestions

sudo chsh -s $(which zsh) $USER

sudo bash -c 'cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<- EOM
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "se"
        Option "XkbModel" "pc105
EndSection
EOM'

sudo bash -c 'cat > /etc/X11/xorg.conf.d/20-intel.conf <<- EOM
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
EndSection
EOM'

sudo bash -c 'cat >> /etc/pam.d/login <<- EOM

# Gnome Keyring
session    optional     pam_gnome_keyring.so auto_start
auth       optional     pam_gnome_keyring.so
EOM'

sudo bash -c 'cat >> /etc/NetworkManager/dispatcher.d/wlan_auto_toggle.sh <<- EOM
#!/bin/sh
if [ "$1" = "eth0" ]; then
    case "$2" in
        up)
            nmcli radio wifi off
            ;;
        down)
            nmcli radio wifi on
            ;;
    esac
elif [ "$(nmcli -g GENERAL.STATE device show eth0)" = "20 (unavailable)" ]; then
    nmcli radio wifi on
fi
EOM'

sudo chmod +x /etc/NetworkManager/dispatcher.d/wlan_auto_toggle.sh

git clone https://aur.archlinux.org/yay.git ~/yay
cd ~/yay
makepkg -fsri

awk '!/#/ { print }' ~/archinstall/aurlist | yay -S --noconfirm --needed -


rm -rf ~/yay ~/artixrepo

if grep -q "Artix Linux" /etc/os-release; then
    # Commands to run if the system is Arch Linux
    echo "This is Artix Linux. Installing cron"
    sudo pacman -S --noconfirm --needed cronie-dinit
    sudo dinitctl enable cronie
    (crontab -l 2>/dev/null; echo "0 14 * * * /.local/bin/daily_update") | crontab -    
else
    # Commands to run if the system is not Arch Linux
    echo "This is not Artix Linux."
fi
