#!/usr/bin/bash

################################################
##### Time
################################################

# References:
# https://wiki.archlinux.org/title/System_time#Time_zone
# https://wiki.archlinux.org/title/Systemd-timesyncd

# Enable systemd-timesyncd
systemctl enable systemd-timesyncd.service

# Set timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc --utc

################################################
##### Locale and keymap
################################################

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=\"en_US.UTF-8\"" > /etc/locale.conf
locale-gen

# Set keymap
echo "KEYMAP=us" > /etc/vconsole.conf

################################################
##### Hostname
################################################

# Set hostname
echo ${NEW_HOSTNAME} > /etc/hostname

# Set /etc/hosts
tee /etc/hosts << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${NEW_HOSTNAME}.localdomain ${NEW_HOSTNAME}
EOF

################################################
##### Pacman
################################################

# References:
# https://wiki.archlinux.org/title/Pacman/Package_signing#Initializing_the_keyring

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

################################################
##### ZSH and common applications
################################################

# Install ZSH and plugins
pacman -S --noconfirm zsh zsh-completions grml-zsh-config zsh-autosuggestions zsh-syntax-highlighting

# Install common applications
pacman -S --noconfirm \
    coreutils \
    htop \
    git \
    p7zip \
    ripgrep \
    unzip \
    unrar \
    lm_sensors \
    upower \
    nano \
    wget \
    openssh \
    fwupd \
    zstd \
    lzop \
    man-db \
    man-pages \
    e2fsprogs \
    util-linux \
    wireguard-tools \
    rsync

################################################
##### Swap
################################################

# References:
# https://wiki.archlinux.org/title/Btrfs#Swap_file
# https://wiki.archlinux.org/title/swap#Swappiness
# https://wiki.archlinux.org/title/Improving_performance#zram_or_zswap
# https://wiki.gentoo.org/wiki/Zram
# https://www.dwarmstrong.org/zram-swap/
# https://www.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/

# Create swap file
btrfs filesystem mkswapfile --size 8g /swap/swapfile

# Activate swap file
swapon /swap/swapfile

# Add swapfile to fstab configuration
tee -a /etc/fstab << EOF

# swap file
/swap/swapfile                              none        swap    defaults                                                                                                0 0
EOF

# Set swappiness
echo 'vm.swappiness=30' > /etc/sysctl.d/99-swappiness.conf

# Set vfs cache pressure
echo 'vm.vfs_cache_pressure=50' > /etc/sysctl.d/99-vfs-cache-pressure.conf

################################################
##### Tweaks
################################################

# References:
# https://github.com/CryoByte33/steam-deck-utilities/blob/main/docs/tweak-explanation.md
# https://wiki.cachyos.org/en/home/General_System_Tweaks

# Split Lock Mitigate - default: 1
echo 'kernel.split_lock_mitigate=0' > /etc/sysctl.d/99-splitlock.conf

# Compaction Proactiveness - default: 20
echo 'vm.compaction_proactiveness=0' > /etc/sysctl.d/99-compaction_proactiveness.conf

# Page Lock Unfairness - default: 5
echo 'vm.page_lock_unfairness=1' > /etc/sysctl.d/99-page_lock_unfairness.conf

# Hugepage Defragmentation - default: 1
# Transparent Hugepages - default: always
# Shared Memory in Transparent Hugepages - default: never
tee /etc/systemd/system/kernel-tweaks.service << 'EOF'
[Unit]
Description=Set kernel tweaks
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/usr/bin/bash -c 'echo always > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/usr/bin/bash -c 'echo advise > /sys/kernel/mm/transparent_hugepage/shmem_enabled'
ExecStart=/usr/bin/bash -c 'echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kernel-tweaks.service

# Disable watchdog timer drivers
# sudo dmesg | grep -e sp5100 -e iTCO -e wdt -e tco
tee /etc/modprobe.d/disable-watchdog-drivers.conf << 'EOF'
blacklist sp5100_tco
blacklist iTCO_wdt
blacklist iTCO_vendor_support
EOF

################################################
##### Users
################################################

# References:
# https://wiki.archlinux.org/title/XDG_Base_Directory

# Set root password and shell
echo "root:${NEW_USER_PASSWORD}" | chpasswd
chsh -s /usr/bin/zsh

# Setup user
useradd -m -G wheel -s /usr/bin/zsh ${NEW_USER}
echo "${NEW_USER}:${NEW_USER_PASSWORD}" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Create XDG user directories
pacman -S --noconfirm xdg-user-dirs
sudo -u ${NEW_USER} xdg-user-dirs-update

# Configure ZSH
tee /home/${NEW_USER}/.zshrc.local << EOF
# ZSH configs
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF

# Create common directories and configure them
mkdir -p \
  /home/${NEW_USER}/.local/share/applications \
  /home/${NEW_USER}/.local/share/themes \
  /home/${NEW_USER}/.local/share/fonts \
  /home/${NEW_USER}/.local/bin \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.config/environment.d \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.ssh \
  /home/${NEW_USER}/.icons \
  /home/${NEW_USER}/src

chown 700 /home/${NEW_USER}/.ssh

tee -a /home/${NEW_USER}/.zshenv << 'EOF'

# Add $HOME/.local/bin/ to the PATH
PATH="${HOME}/.local/bin/:${PATH}"
EOF

# Updater helper
tee -a /home/${NEW_USER}/.zshrc.local << EOF
# Updater helper
update-all() {
    # Update keyring
    sudo pacman -Sy --noconfirm archlinux-keyring

    # Update system
    sudo pacman -Syu

    # Update AUR packages
    paru -Syu

    # Update firmware
    sudo fwupdmgr refresh
    sudo fwupdmgr update
    
    # Update Flatpak apps
    flatpak update -y
}
EOF

################################################
##### Networking
################################################

# References:
# https://wiki.archlinux.org/title/NetworkManager#Using_iwd_as_the_Wi-Fi_backend
# https://wiki.archlinux.org/title/Firewalld
# https://wiki.archlinux.org/title/nftables

# Install and configure firewalld
pacman -S --noconfirm firewalld
systemctl enable firewalld.service
firewall-offline-cmd --set-default-zone=block

# Install and enable NetworkManager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service

# Install bind tools
pacman -S --noconfirm bind

# Install nftables
pacman -S --noconfirm iptables-nft --ask 4

################################################
##### initramfs
################################################

# Configure mkinitcpio
sed -i "s|MODULES=()|MODULES=(btrfs${MKINITCPIO_MODULES})|" /etc/mkinitcpio.conf
sed -i "s|^HOOKS.*|HOOKS=(systemd plymouth encrypt autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION=\"zstd\"|COMPRESSION=\"zstd\"|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION_OPTIONS=()|COMPRESSION_OPTIONS=(-2)|" /etc/mkinitcpio.conf

# Re-create initramfs image
mkinitcpio -P

################################################
##### GRUB
################################################

# References:
# https://wiki.archlinux.org/title/GRUB
# https://wiki.archlinux.org/title/Kernel_parameters#GRUB
# https://wiki.archlinux.org/title/GRUB/Tips_and_tricks#Password_protection_of_GRUB_menu
# https://www.gnu.org/software/grub/manual/grub/grub.html
# https://archlinux.org/news/grub-bootloader-upgrade-and-configuration-incompatibilities/
# https://wiki.archlinux.org/title/silent_boot

# Install GRUB packages
pacman -S --noconfirm grub efibootmgr

# Configure GRUB
sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"2\"|g" /etc/default/grub
sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|g" /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"\"|g" /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rd.luks.name=$(blkid -s UUID -o value /dev/sda2)=system nmi_watchdog=0 rw quiet splash\"|g" /etc/default/grub
sed -i "s|^GRUB_PRELOAD_MODULES=.*|GRUB_PRELOAD_MODULES=\"part_msdos luks2\"|g" /etc/default/grub
sed -i "s|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=hidden|g" /etc/default/grub
sed -i "s|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|g" /etc/default/grub
sed -i "s|^#GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|g" /etc/default/grub

# Install GRUB
grub-install --target=i386-pc /dev/sda

# Password protect GRUB editing, but make menu unrestricted
GRUB_PASSWORD_HASH=$(echo -e "${LUKS_PASSWORD}\n${LUKS_PASSWORD}" | LC_ALL=C /usr/bin/grub-mkpasswd-pbkdf2 | awk '/hash of / {print $NF}')

chmod o-r /etc/grub.d/40_custom

tee -a /etc/grub.d/40_custom << EOF

# Password protect GRUB menu
set superusers="${NEW_USER}"
password_pbkdf2 ${NEW_USER} ${GRUB_PASSWORD_HASH}
EOF

sed -i "s|CLASS=\"--class gnu-linux --class gnu --class os.*\"|CLASS=\"--class gnu-linux --class gnu --class os --unrestricted\"|g" /etc/grub.d/10_linux

# Do not display 'Loading ...' messages
sed -i '/Loading initial ramdisk/d' /etc/grub.d/10_linux
sed -i '/Loading Linux/d' /etc/grub.d/10_linux

# Reduce boot verbosity (silent boot)
sed -i "s|quiet|& loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0|" /etc/default/grub

# Generate GRUB's configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# GRUB upgrade hooks
mkdir -p /etc/pacman.d/hooks

tee /etc/pacman.d/hooks/90-grub-unrestricted.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Adding --unrestricted to GRUB...
When = PostTransaction
Exec = /usr/bin/sed -i "s|CLASS=\"--class gnu-linux --class gnu --class os.*\"|CLASS=\"--class gnu-linux --class gnu --class os --unrestricted\"|g" /etc/grub.d/10_linux
EOF

tee /etc/pacman.d/hooks/91-grub-hide-messages.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Hiding GRUB boot messages...
When = PostTransaction
Exec = /usr/bin/sh -c "sed -i '/Loading initial ramdisk/d' /etc/grub.d/10_linux; sed -i '/Loading Linux/d' /etc/grub.d/10_linux"
EOF

tee /etc/pacman.d/hooks/92-grub-upgrade.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Upgrading GRUB...
When = PostTransaction
Exec = /usr/bin/sh -c "grub-install --target=i386-pc /dev/sda; grub-mkconfig -o /boot/grub/grub.cfg"
EOF

################################################
##### PipeWire
################################################

# References:
# https://wiki.archlinux.org/title/PipeWire

# Install PipeWire and WirePlumber
pacman -S --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-jack \
    pipewire-pulse \
    libpulse \
    wireplumber --ask 4

# Enable PipeWire's user service
sudo -u ${NEW_USER} systemctl --user enable pipewire-pulse.service

################################################
##### Flatpak
################################################

# References
# https://wiki.archlinux.org/title/Flatpak

# Install Flatpak and applications
pacman -S --noconfirm flatpak xdg-desktop-portal-gtk
sudo -u ${NEW_USER} systemctl --user enable xdg-desktop-portal.service

# Add Flathub repositories
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update

# Global override to deny all applications the permission to access certain directories
flatpak override --nofilesystem='home'

# Allow read-only access to GTK configs
flatpak override --filesystem=xdg-config/gtk-3.0:ro
flatpak override --filesystem=xdg-config/gtk-4.0:ro

# Allow access to Downloads directory
flatpak override --filesystem=xdg-download

################################################
##### Flatpak runtimes
################################################

# Install runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GL32.default/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GL.default/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL.mesa-git/x86_64/22.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL32.mesa-git/x86_64/22.08
flatpak install -y flathub org.gnome.Platform.Compat.i386/x86_64/43

################################################
##### Flatpak applications
################################################

# Install Spotify
flatpak install -y flathub com.spotify.Client

# Install Discord
flatpak install -y flathub com.discordapp.Discord

# Insomnia
flatpak install -y flathub rest.insomnia.Insomnia

# LibreOffice
flatpak install -y flathub org.libreoffice.LibreOffice

# Blender
flatpak install -y flathub org.blender.Blender

################################################
##### Syncthing
################################################

# References:
# https://wiki.archlinux.org/title/syncthing

# Install Syncthing
pacman -S --noconfirm syncthing

# Enable Syncthing's user service
sudo -u ${NEW_USER} systemctl --user enable syncthing.service

################################################
##### Podman
################################################

# References:
# https://wiki.archlinux.org/title/Podman
# https://wiki.archlinux.org/title/Buildah
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md

# Install Podman, Buildah and dependencies
pacman -S --noconfirm podman fuse-overlayfs slirp4netns netavark aardvark-dns buildah

# Enable kernel.unprivileged_userns_clone
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/99-rootless-podman.conf

# Set subuid and subgid
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${NEW_USER}

# Enable unprivileged ping
echo 'net.ipv4.ping_group_range=0 165535' > /etc/sysctl.d/99-unprivileged-ping.conf

# Create docker/podman alias
tee -a /home/${NEW_USER}/.zshrc.local << EOF
# Podman
alias docker=podman
EOF

# Re-enable unqualified search registries
tee -a /etc/containers/registries.conf << EOF
# Enable docker.io as unqualified search registry
unqualified-search-registries = ["docker.io"]
EOF

################################################
##### Paru
################################################

# (Temporary - reverted at cleanup) Allow $NEW_USER to run pacman without password
echo "${NEW_USER} ALL=NOPASSWD:/usr/bin/pacman" >> /etc/sudoers

# Install paru
git clone https://aur.archlinux.org/paru-bin.git
chown -R ${NEW_USER}:${NEW_USER} paru-bin
cd paru-bin
sudo -u ${NEW_USER} makepkg -si --noconfirm
cd ..
rm -rf paru-bin

################################################
##### thermald
################################################

# Install and enable thermald if CPU is Intel
if [[ $(cat /proc/cpuinfo | grep vendor | uniq) =~ "GenuineIntel" ]]; then
    pacman -S --noconfirm thermald
    systemctl enable thermald.service
fi

################################################
##### Plymouth boot splash
################################################
sudo -u ${NEW_USER} paru -S --noconfirm plymouth-theme-arch-charge-gdm-spinner

################################################
##### Cleanup
################################################

# Make sure that all /home/$NEW_USER actually belongs to $NEW_USER 
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}

# Revert sudoers change
sed -i "/${NEW_USER} ALL=NOPASSWD:\/usr\/bin\/pacman/d" /etc/sudoers
