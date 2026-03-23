#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 3: Core OpenRC Services
# =============================================================================

echo "=== Phase 3: Core OpenRC Services ==="

# Session management
echo "[1/6] Installing session management..."
sudo pacman -S --needed --noconfirm elogind elogind-openrc lib32-elogind dbus dbus-openrc
sudo rc-update add elogind default
sudo rc-update add dbus default

# Networking
echo "[2/6] Installing NetworkManager..."
sudo pacman -S --needed --noconfirm networkmanager networkmanager-openrc
sudo rc-update add NetworkManager default

# Bluetooth
echo "[3/6] Installing Bluetooth..."
sudo pacman -S --needed --noconfirm bluez bluez-utils bluez-openrc
sudo rc-update add bluetoothd default
sudo groupadd bluetooth 2>/dev/null || echo "  bluetooth group already exists"
sudo usermod -aG bluetooth,input,video,audio,seat deck

# Display manager
echo "[4/6] Installing SDDM..."
sudo pacman -S --needed --noconfirm sddm sddm-openrc
sudo rc-update add sddm default

# Audio base
echo "[5/6] Enabling ALSA sound..."
sudo rc-update add alsasound default

# Time sync
echo "[6/6] Installing Chrony..."
sudo pacman -S --needed --noconfirm chrony chrony-openrc
sudo rc-update add chronyd default

echo "=== Core services setup complete! ==="
