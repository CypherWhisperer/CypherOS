#!/usr/bin/env bash
set -euo pipefail

DISK="/dev/sda"
BTRFS_PART="${DISK}1"
EFI_PART="${DISK}2"

MNT="/mnt"

echo "== Mounting BTRFS root =="
mount -t btrfs -o subvolid=5 "$BTRFS_PART" "$MNT"

echo "== Creating subvolumes =="
btrfs subvolume create $MNT/@nixos-root
btrfs subvolume create $MNT/@home
btrfs subvolume create $MNT/@data
btrfs subvolume create $MNT/@nix-store
btrfs subvolume create $MNT/@swap

echo "== Preparing swap subvolume =="
chattr +C $MNT/@swap

echo "== Creating swapfile =="
fallocate -l 8G $MNT/@swap/swapfile
chmod 600 $MNT/@swap/swapfile
mkswap $MNT/@swap/swapfile

echo "== Unmounting base mount =="
umount $MNT

echo "== Mounting final layout =="

mount -t btrfs -o subvol=@nixos-root,compress=zstd:3,noatime "$BTRFS_PART" "$MNT"

mkdir -p $MNT/{boot,home,cypher-whisperer/DATA,nix,swap}

mount -t vfat "$EFI_PART" $MNT/boot

mount -t btrfs -o subvol=@home,compress=zstd:3,noatime "$BTRFS_PART" $MNT/home
mount -t btrfs -o subvol=@data,compress=zstd:3,noatime "$BTRFS_PART" $MNT/cypher-whisperer/DATA
mount -t btrfs -o subvol=@nix-store,compress=zstd:3,noatime "$BTRFS_PART" $MNT/nix
mount -t btrfs -o subvol=@swap,noatime "$BTRFS_PART" $MNT/swap

echo "== Activating swap =="
swapon $MNT/swap/swapfile

echo "== Done =="

# remember:
# cp -r /run/media/blend/BACKUP_DISK_001/HOME/FILES/TEMP_NIXOS_STUFF/cypher-whisperer/ /mnt/home/
# cp -r /run/media/blend/BACKUP_DISK_001/HOME/FILES/TEMP_NIXOS_STUFF/CypherOS /mnt/home/cypher-whisperer/

