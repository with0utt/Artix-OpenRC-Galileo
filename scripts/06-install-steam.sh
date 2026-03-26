#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 6: Steam & Gaming
# =============================================================================

echo "=== Phase 6: Steam & Gaming ==="

# Ensure lib32 is enabled
if ! grep -q "^\[lib32\]" /etc/pacman.conf; then
    echo "ERROR: [lib32] repository is not enabled in /etc/pacman.conf"
    echo "Uncomment the [lib32] section and run: sudo pacman -Sy"
    exit 1
fi

sudo pacman -Sy

echo "[1/4] Installing Steam and dependencies..."
sudo pacman -S --needed --noconfirm steam \
    lib32-vulkan-radeon lib32-mesa lib32-pipewire lib32-libpulse \
    vulkan-radeon gamemode lib32-gamemode

echo "[2/4] Installing Gamescope and MangoHud..."
sudo pacman -S --needed --noconfirm gamescope mangohud

echo "[3/4] Installing xdg-desktop-portal..."
sudo pacman -S --needed --noconfirm xdg-desktop-portal xdg-desktop-portal-gtk

echo "[4/4] Adding user to required groups..."
sudo usermod -aG input,video,audio,seat deck

echo "=== Steam & Gaming installed! ==="
