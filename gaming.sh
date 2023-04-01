#!/usr/bin/bash

################################################
##### Enable multilib repository
################################################
# References: 
# none yet, need multi lib because we are not going with flatpak steam and we need them for our nvidia driver

# enable multilib by addition
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# update packagelists
sudo pacman -Syy
sudo paru -Syy

################################################
##### Get headers for Nvidia to use DKMS
################################################

sudo pacman -S --noconfirm linux-headers linux-lts-headers

################################################
##### Nvidia Installer
################################################
# References:
# None yet

git clone https://github.com/Frogging-Family/nvidia-all
chown -R ${NEW_USER}:${NEW_USER} nvidia-all
cd nvidia-all
sudo -u ${NEW_USER} makepkg -si
cd ..
rm -rf nvidia-all

################################################
##### Steam
################################################
# References:
# None yet

pacman -S --noconfirm steam

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

################################################
##### Other game launchers and Compatibity Tools
################################################

# Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Lutris
flatpak install -y flathub net.lutris.Lutris

# ProtonUp-Qt
flatpak install -y flathub net.davidotek.pupgui2

################################################
##### Roblox launcher
################################################

git clone --depth=1 https://aur.archlinux.org/grapejuice-git.git ./grapejuice-git
chown -R ${NEW_USER}:${NEW_USER} ./grapejuice-git
cd ./grapejuice-git
sudo -u ${NEW_USER} makepkg -si --noconfirm
cd ..
rm -rf ./grapejuice-git

################################################
##### prime-run
################################################

# Install prime-run command via nvidia-prime
pacman -S --noconfirm nvidia-prime

################################################
##### Get mangohud and goverlay
################################################

# Issue #1 the overlay script only seems to work after system is rebooted into GUI or something, 
ehco "please reboot, log in and run cd && ./overlay.sh
curl  --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/overlay.sh -O
cp ./overlay.sh /home/{NEW_USER}/overlay.sh
chmod 0755 /home/{NEW_USER}/overlay.sh
