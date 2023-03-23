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

mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4
mount -m /dev/sda3 /mnt/archinstall
mount -m /dev/sda1 /mnt/archinstall/boot
mount -m /dev/sda4 /mnt/archinstall/home

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
pacstrap /mnt/archinstall base base-devel linux linux-lts linux-firmware ${CPU_MICROCODE}

# Generate filesystem tab
genfstab -U /mnt >> /mnt/archinstall/etc/fstab

mkdir -p /mnt/archinstall/install-arch
curl https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/extra/firefox.js -O
cp ./extra/firefox.js /mnt/archinstall/install-arch/firefox.js
curl https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/gnome.sh -O
cp ./gnome.sh /mnt/archinstall/install-arch/gnome.sh
curl https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/gaming.sh -O
cp ./gaming.sh /mnt/archinstall/install-arch/gaming.sh
curl https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/setup.sh -O
cp ./setup.sh /mnt/archinstall/install-arch/setup.sh

arch-chroot /mnt/archinstall/ /bin/bash /install-arch/setup.sh
rm -rf /mnt/archinstall/install-arch
umount -R /mnt/archinstall
