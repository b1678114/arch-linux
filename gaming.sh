#!/usr/bin/bash

################################################
##### MangoHud
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/22.08

# Configure MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
engine_version
vulkan_driver
EOF

# Allow Flatpaks to access MangoHud configs
flatpak override --filesystem=xdg-config/MangoHud:ro

################################################
##### Platforms
################################################

# Steam
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

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


