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
##### Partitioning
################################################

# References:
# https://www.rodsbooks.com/gdisk/sgdisk-walkthrough.html
# https://www.dwarmstrong.org/archlinux-install/

# Delete old partition layout and re-read partition table
wipefs -af /dev/nvme0n1
sgdisk --zap-all --clear /dev/nvme0n1
partprobe /dev/nvme0n1

# Partition disk and re-read partition table
sgdisk -n 1:0:+512MiB -t 1:ef00 -c 1:EFI /dev/nvme0n1
sgdisk -n 2:0:0 -t 2:8309 -c 2:LUKS /dev/nvme0n1
partprobe /dev/nvme0n1

################################################
##### LUKS / BTRFS
################################################

# Encrypt and open LUKS partition
echo ${LUKS_PASSWORD} | cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/disk/by-partlabel/LUKS
echo ${LUKS_PASSWORD} | cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system

# Create BTRFS
mkfs.btrfs -L system /dev/mapper/system

# Mount root device
mount -t btrfs LABEL=system /mnt

# Create BTRFS subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
umount -R /mnt

# Mount BTRFS subvolumes
mount -t btrfs -o subvol=@,compress=zstd:3,noatime,discard,space_cache=v2,ssd LABEL=system /mnt

mkdir -p /mnt/home
mount -t btrfs -o subvol=@home,compress=zstd:3,noatime,discard,space_cache=v2,ssd LABEL=system /mnt/home

mkdir -p /mnt/swap
mount -t btrfs -o subvol=@swap LABEL=system /mnt/swap

################################################
##### EFI / Boot
################################################

# Format and mount EFI/boot partition
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
mount --mkdir /dev/nvme0n1p1 /mnt/boot

################################################
##### Install system
################################################

# Import mirrorlist
cp ./extra/mirrorlist /etc/pacman.d/mirrorlist

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
pacstrap /mnt base base-devel linux linux-lts linux-firmware btrfs-progs ${CPU_MICROCODE}

# Generate filesystem tab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system
mkdir -p /mnt/install-arch/extra
curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/extra/firefox.js -O
cp ./firefox.js /mnt/install-arch/firefox.js
chmod 0755 /mnt/install-arch/firefox.js
curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/gnome.sh -O
cp ./gnome.sh /mnt/install-arch/gnome.sh
chmod 0755 /mnt/install-arch/gnome.sh
curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/gaming.sh -O
cp ./gaming.sh /mnt/install-arch/gaming.sh
chmod 0755 /mnt/install-arch/gaming.sh
curl  --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/devel/setup.sh -O
cp ./setup.sh /mnt/install-arch/setup.sh
chmod 0755 /mnt/install-arch/setup.sh
arch-chroot /mnt/ /bin/bash /install-arch/setup.sh
rm -rf /mnt/install-arch
umount -R /mnt
swapoff -a
