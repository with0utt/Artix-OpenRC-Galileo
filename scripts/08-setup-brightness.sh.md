#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 9: Brightness Control Setup
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Brightness Control Setup ==="

sudo pacman -S --needed --noconfirm brightnessctl

echo "Installing udev rule for KDE brightness slider..."
sudo cp "$SCRIPT_DIR/configs/90-backlight.rules" /etc/udev/rules.d/90-backlight.rules

# Apply immediately
sudo chgrp video /sys/class/backlight/amdgpu_bl0/brightness
sudo chmod g+w /sys/class/backlight/amdgpu_bl0/brightness
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight

echo "=== Brightness control configured! ==="
