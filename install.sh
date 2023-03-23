#!/usr/bin/bash

################################################
##### Set variables
################################################

read -p "Username: " NEW_USER
export NEW_USER

read -sp "User password: " NEW_USER_PASSWORD
export NEW_USER_PASSWORD

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Timezone (timedatectl list-timezones): " TIMEZONE
export TIMEZONE

read -p "Desktop environment (plasma / gnome): " DESKTOP_ENVIRONMENT
export DESKTOP_ENVIRONMENT

read -p "Gaming (yes / no): " GAMING
export GAMING

# CPU vendor
if cat /proc/cpuinfo | grep "vendor" | grep "GenuineIntel" > /dev/null; then
    export CPU_MICROCODE="intel-ucode"
elif cat /proc/cpuinfo | grep "vendor" | grep "AuthenticAMD" > /dev/null; then
    export CPU_MICROCODE="amd-ucode"
fi

# GPU vendor
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    export GPU_PACKAGES="vulkan-intel intel-media-driver intel-gpu-tools"
    export MKINITCPIO_MODULES=" i915"
    export LIBVA_ENV_VAR="LIBVA_DRIVER_NAME=iHD"
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    export GPU_PACKAGES="vulkan-radeon libva-mesa-driver radeontop"
    export MKINITCPIO_MODULES=" amdgpu"
    export LIBVA_ENV_VAR="LIBVA_DRIVER_NAME=radeonsi"
fi

# Force pacman to refresh the package lists
pacman -Syy

# Initialize Pacman's keyring
pacman-key --init
pacman-key --populate

# Configure Pacman
sed -i "s|^#Color|Color|g" /etc/pacman.conf
sed -i "s|^#VerbosePkgLists|VerbosePkgLists|g" /etc/pacman.conf
sed -i "s|^#ParallelDownloads.*|ParallelDownloads = 5|g" /etc/pacman.conf
sed -i "/ParallelDownloads = 5/a ILoveCandy" /etc/pacman.conf

# Install system
pacstrap /mnt/archinstall base base-devel linux linux-lts linux-firmware btrfs-progs ${CPU_MICROCODE}

# Generate filesystem tab
genfstab -U /mnt >> /mnt/etc/fstab

mkdir -p /mnt/archinstall/install-arch
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/extra/firefox.js -O
cp ./extra/firefox.js /install-arch/firefox.js
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/gnome.sh -O
cp ./gnome.sh /install-arch/gnome.sh
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/gaming.sh -O
cp ./gaming.sh /install-arch/gaming.sh
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/setup.sh -O
cp ./setup.sh /install-arch/setup.sh

arch-chroot /mnt/archinstall /bin/bash /install-arch/setup.sh
rm -rf /mnt/install-arch
umount -R /mnt
