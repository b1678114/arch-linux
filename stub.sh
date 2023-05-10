#!/usr/bin/bash

################################################
##### Set variables
################################################

read -sp "LUKS password: " LUKS_PASSWORD
export LUKS_PASSWORD

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

read -p "Plymouth boot animations (yes / no): " PLYMOUTH
export PLYMOUTH

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


################################################
##### Get & run system configuraton scripts
################################################

mkdir -p /mnt/install-arch/extra
curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/sda-grub/extra/firefox.js -O
cp ./firefox.js /mnt/install-arch/firefox.js
chmod 0755 /mnt/install-arch/firefox.js
curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/sda-grub/gnome.sh -O
cp ./gnome.sh /mnt/install-arch/gnome.sh
chmod 0755 /mnt/install-arch/gnome.sh
curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/sda-grub/gaming.sh -O
cp ./gaming.sh /mnt/install-arch/gaming.sh
chmod 0755 /mnt/install-arch/gaming.sh
curl  --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/sda-grub/setup.sh -O
cp ./setup.sh /mnt/install-arch/setup.sh
chmod 0755 /mnt/install-arch/setup.sh
curl  --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/sda-grub/plasma.sh -O
cp ./setup.sh /mnt/install-arch/plasma.sh
chmod 0755 /mnt/install-arch/plasma.sh
arch-chroot /mnt/ /bin/bash /install-arch/setup.sh
