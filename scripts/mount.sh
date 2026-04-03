#!/bin/bash

set -euo pipefail

DISK="/dev/sda"
BTRFS_PART="${DISK}1"
EFI_PART="${DISK}2"

MNT="/mnt"

echo "== Mounting final layout =="

mount -t btrfs -o subvol=@nixos-root,compress=zstd:3,noatime "$BTRFS_PART" "$MNT"

mount -t vfat "$EFI_PART" $MNT/boot

mount -t btrfs -o subvol=@home,compress=zstd:3,noatime "$BTRFS_PART" $MNT/home
#mount -t btrfs -o subvol=@data,compress=zstd:3,noatime "$BTRFS_PART" $MNT/cypher-whisperer/DATA
mount -t btrfs -o subvol=@nix-store,compress=zstd:3,noatime "$BTRFS_PART" $MNT/nix
mount -t btrfs -o subvol=@swap,noatime "$BTRFS_PART" $MNT/swap

echo "== Activating swap =="
swapon $MNT/swap/swapfile

echo "== Done =="
