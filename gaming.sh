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
# None yet

# enable multilib by addition
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# update packagelists
sudo pacman -Syy

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
##### Latest MangoHud binary & GOverlay binary
################################################
# References:
# None yet

# Download and install latest mangohud release
cd
mkdir mangohud-custom
cd mangohud-custom
tee ./PKGBUILD << EOF
pkgname=mangohud-custom
pkgver=1
pkgrel=1
pkgdesc="Custom package for MangoHud"
arch=('x86_64')
url="https://github.com/flightlessmango/MangoHud"
license=('MIT')
depends=()
provides=("mangohud=$pkgver")
conflicts=('mangohud')

build() {
  URL=$(curl -s https://api.github.com/repos/flightlessmango/MangoHud/releases/latest | awk -F\" '/browser_download_url.*.tar.gz/{print $(NF-1)}')
  curl --tlsv1.2 -fsSL ${URL} -o MangoHud.tar.gz
  tar -xf MangoHud.tar.gz -C ./
}

package() {
  cd "./MangoHud"
  sudo -u ${NEW_USER} sh mangohud-setup.sh install
}
EOF
sudo -u ${NEW_USER} makepkg -si --noconfirm
cd ..
rm -rf ./MangoHud

# Download and install goverlay
sudo -u ${NEW_USER} paru -S --noconfirm goverlay-bin

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

git clone --depth=1 https://aur.archlinux.org/grapejuice-git.git /grapejuice-git
chown -R ${NEW_USER}:${NEW_USER} grapejuice-git
cd grapejuice-git
sudo -u ${NEW_USER} makepkg -si --noconfirm
cd ..
rm -rf grapejuice-git

################################################
##### prime-run
################################################

# Install prime-run command via nvidia-prime
pacman -S --noconfirm nvidia-prime
