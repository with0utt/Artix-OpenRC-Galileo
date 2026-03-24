#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 9: Brightness Control Setup
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Phase 9: Final Polish ==="

echo "[1/3] Installing brightnessctl..."
sudo pacman -S --needed --noconfirm brightnessctl

echo "[2/3] Installing udev rule for KDE brightness slider..."
sudo cp "$SCRIPT_DIR/configs/90-backlight.rules" /etc/udev/rules.d/90-backlight.rules

# Apply immediately
sudo chgrp video /sys/class/backlight/amdgpu_bl0/brightness
sudo chmod g+w /sys/class/backlight/amdgpu_bl0/brightness
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight

echo "[3/3] Installing uinput udev rule for Steam virtual keyboard..."
sudo cp "$SCRIPT_DIR/configs/99-input.rules" /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=misc

echo "=== Phase 9 complete! ==="
