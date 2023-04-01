#!/usr/bin/bash

####################################
#### install mangohud and goverlay
####################################

sudo -u view paru -S --noconfirm mangohud
sudo -u view paru -S --noconfirm goverlay

# undo the CAUR again for now
sudo sed -i '/\[chaotic-aur\]/,+1d' /etc/pacman.conf

# update packagelists
sudo pacman -Syy
sudo paru -Syy
