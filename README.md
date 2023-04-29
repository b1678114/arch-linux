# Arch Linux install scripts
For non legacy boot partitioning or for graphics out of the box, see other branches.

## Requirements
- MBR
- SDA
- Single GPU (Intel or Radeon)

## Partitions layout
| Name                                                 | Type  | FS Type | Mountpoint |      Size     |
| ---------------------------------------------------- | :---: | :-----: | :--------: | :-----------: |
| sda                                                  | disk  |         |            |               |
| ├─sda1                                               | part  |  EXT2   |    /boot   |    512MiB     |
| ├─sda2                                               | part  |  LUKS2  |            |               |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├──system              | crypt |  BTRFS  |     /      |  Rest of disk |

## Installation guide
1. Disable fast boot
2. Boot into Arch Linux ISO
3. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
4. Init keyring: `pacman-key --init && pacman-key --populate`
5. Update repos and install git: `pacman -Sy git`
6. Clone with curl: `curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/youdontknowdemo/arch-linux/legacy-headless/install.sh -O`
7. Run script: `chmod 0755 install.sh && sudo ./install.sh`
8. Reboot and re-enable fast boot
9. Log into newly installed tty prompt
10. Install your window manager. `git clone https://gitlab.com/dwt1/dtos && ./dtos/dtos`

## Misc guides
### How to chroot
```bash
cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system
mount -t btrfs -o subvol=@,compress=zstd:3,noatime,space_cache=v2 LABEL=system /mnt
mount -t btrfs -o subvol=@home,compress=zstd:3,noatime,space_cache=v2 LABEL=system /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

### How to show reveal output durring plymouth boot
```bash
Press anything during boot
```

## How to revert to a previous Flatpak commit
```bash
# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=${HASH} org.godotengine.Godot

# Pin version
flatpak mask org.godotengine.Godot
```
