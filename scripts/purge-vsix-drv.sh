#!/usr/bin/env bash
# purge-vsix-drv.sh
#
# Purges all stale .vsix.drv files from the Nix store after a lib.fakeHash
# workflow. Run this BEFORE nixos-rebuild if you get hash mismatch errors
# on marketplace VSCode extensions.
#
# Must be run as root (sudo).
#
# WHAT THIS DOES:
#   1. Wipes both root and user Nix eval caches (prevents regeneration)
#   2. Nukes all old generations so GC roots are clean
#   3. Runs aggressive GC to collect what it can
#   4. Finds any remaining .vsix.drv files, walks their full referrer
#      closure, and force-deletes the entire chain top-down
#   5. Finds any other .drv files containing AAAA (fake hash marker)
#      and does the same

set -euo pipefail

USER_HOME="/home/cypher-whisperer"

echo "==> Clearing Nix eval caches..."
rm -rf /root/.cache/nix
rm -rf "${USER_HOME}/.cache/nix"

echo "==> Deleting old NixOS generations..."
nix-env --profile /nix/var/nix/profiles/system --delete-generations old

echo "==> Deleting old Home Manager generations..."
nix-env --profile "${USER_HOME}/.local/state/nix/profiles/home-manager" \
  --delete-generations old 2>/dev/null || true
nix-env --profile "${USER_HOME}/.nix-profile" \
  --delete-generations old 2>/dev/null || true

echo "==> Running aggressive GC..."
nix-collect-garbage -d

echo "==> Finding and purging .vsix.drv referrer closures..."
VSIX_DRVS=$(find /nix/store -maxdepth 1 -name '*.vsix.drv' 2>/dev/null)

if [ -n "$VSIX_DRVS" ]; then
  echo "$VSIX_DRVS" | while read -r drv; do
    nix-store --query --referrers-closure "$drv"
  done | sort -u | xargs nix-store --delete --ignore-liveness
  echo "==> .vsix.drv closures purged."
else
  echo "==> No .vsix.drv files found, skipping."
fi

echo "==> Scanning for any remaining fake-hash .drv files..."
FAKE_DRVS=$(find /nix/store -name '*.drv' \
  | xargs grep -l 'AAAAAAAAAA' 2>/dev/null || true)

if [ -n "$FAKE_DRVS" ]; then
  echo "$FAKE_DRVS" | while read -r drv; do
    nix-store --query --referrers-closure "$drv"
  done | sort -u | xargs nix-store --delete --ignore-liveness
  echo "==> Fake-hash .drv closures purged."
else
  echo "==> No fake-hash .drv files found."
fi

echo ""
echo "==> Store is clean. Run: sudo nixos-rebuild switch --flake .#nixos-gnome"
