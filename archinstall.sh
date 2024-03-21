#!/bin/bash

sudo pacman -Syu --noconfirm

sudo pacman -S --noconfirm reflector rsync
clear
echo "!!!!! SKIP ON ARTIX !!!!!
Enter your desired country for the mirrorlist (leave empty to skip):"
read country

if [ -n "$country" ]; then
    sudo reflector --country "$country" --lastest 5 --sort rate --save /etc/pacman.d/mirrorlist
else
    echo "Skipping mirrorlist configuration..."
fi

cd ~/script
mv ~/script/wg.jpg ~
awk '!/^#/ {print $1}' ~/script/packagelist | sudo pacman -S --noconfirm --needed -

mkdir -p ~/documents/git
mkdir ~/documents/wallpapers
mkdir ~/documents/keepassxc

git clone https://github.com/aqua28/dwm.git ~/documents/git/dwm
git clone https://github.com/aqua28/st.git ~/documents/git/st
git clone https://github.com/aqua28/dmenu.git ~/documents/git/dmenu
git clone https://github.com/aqua28/slock ~/documents/git/slock
git clone https://github.com/aqua28/nsxiv.git ~/documents/git/nsxiv

echo "Enter the username you want to add:"
read userslock

echo "Enter the group name you want to add:"
read groupslock

sed -i "s/{{USERNAME}}/$userslock/g" ~/documents/git/slock/config.def.h
sed -i "s/{{GROUPNAME}}/$groupslock/g" ~/documents/git/slock/config.def.h


sudo make -C ~/documents/git/dwm install
sudo make -C ~/documents/git/st install
sudo make -C ~/documents/git/dmenu install
sudo make -C ~/documents/git/slock install
sudo make -C ~/documents/git/nsxiv install

git clone https://github.com/aqua28/dotfiles.git ~/dotfiles
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
mkdir ~/.config/shell
touch ~/.config/shell/histfile

git clone https://aur.archlinux.org/yay.git ~/yay
cd ~/yay
makepkg -fsri

awk '!/#/ { print }' ~/script/aurlist | yay -S --noconfirm --needed -


if grep -q "Artix Linux" /etc/os-release; then
    # Commands to run if the system is Arch Linux
    echo "This is Artix Linux. Installing cron"
    sudo pacman -S --noconfirm --needed cronie-dinit
    sudo dinitctl enable cronie
    (crontab -l 2>/dev/null; echo "0 14 * * * /.local/bin/daily_update") | crontab -    
else
    # Commands to run if the system is not Arch Linux
    echo "This is not Artix Linux."
    (crontab -l 2>/dev/null; echo "0 14 * * * /.local/bin/daily_update") | crontab -    
fi

setbg ~/wg.jpg
