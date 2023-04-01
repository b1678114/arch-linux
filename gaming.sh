#!/usr/bin/bash

################################################
##### Variable Check
################################################

read -p "Username: " NEW_USER
export NEW_USER

################################################
##### Enable multilib repository
################################################
# References: 
# none yet, need multi lib because we are not going with flatpak steam

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
##### Other game launchers
################################################

# Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Lutris
flatpak install -y flathub net.lutris.Lutris

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
##### Enable Chaotic AUR repository
################################################
# References: 
# vulkan dependies seem broken for my build at install, suddenly, it worked many times before, Could't debug fully, CAUR Works..

# Get CAUR Key
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Enable CAUR by addition
echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf

# update packagelists
sudo pacman -Syy
sudo paru -Syy

################################################
##### Get mangohud and goverlay
################################################

# install mangohud and goverlay
sudo -u view paru -S --noconfirm mangohud
sudo -u view paru -S --noconfirm goverlay

# undo the CAUR again for now
sudo sed -i '/\[chaotic-aur\]/,+1d' /etc/pacman.conf

# update packagelists
sudo pacman -Syy
sudo paru -Syy
