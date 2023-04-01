#!/usr/bin/bash

################################################
##### Set variables
################################################

read -sp "LUKS password: " LUKS_PASSWORD
export LUKS_PASSWORD

read -p "Username: " NEW_USER
export NEW_USER

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

sudo -u view paru -S --noconfirm mangohud
sudo -u view paru -S --noconfirm goverlay

# undo the CAUR again for now
sudo sed -i '/\[chaotic-aur\]/,+1d' /etc/pacman.conf

# update packagelists
sudo pacman -Syy
sudo paru -Syy
