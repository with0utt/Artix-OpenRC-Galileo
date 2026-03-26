#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 7 & 8: Gamescope Session + Session Switching
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Phase 7 & 8: Session Setup ==="

# Gamescope session script
echo "[1/8] Installing Gamescope session script..."
sudo mkdir -p /usr/share/gamescope-custom
sudo cp "$SCRIPT_DIR/configs/gamescope-session.sh" /usr/share/gamescope-custom/gamescope-session.sh
sudo chmod +x /usr/share/gamescope-custom/gamescope-session.sh

# SDDM session entry
echo "[2/8] Installing SDDM session entry..."
sudo mkdir -p /usr/share/wayland-sessions
sudo cp "$SCRIPT_DIR/configs/gamescope-session.desktop" /usr/share/wayland-sessions/gamescope-session.desktop

# Session helper
echo "[3/8] Installing session helper..."
sudo cp "$SCRIPT_DIR/scripts/steamos-session-helper" /usr/bin/steamos-session-helper
sudo chmod +x /usr/bin/steamos-session-helper

# Session selector
echo "[4/8] Installing session selector..."
sudo cp "$SCRIPT_DIR/scripts/steamos-session-select" /usr/bin/steamos-session-select
sudo chmod +x /usr/bin/steamos-session-select

# Passwordless sudo
echo "[5/8] Configuring passwordless sudo for session helper..."
sudo cp "$SCRIPT_DIR/configs/steam-session.sudoers" /etc/sudoers.d/steam-session
sudo chmod 440 /etc/sudoers.d/steam-session

# SDDM autologin configuration
echo "[6/8] Configuring SDDM autologin..."
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$SCRIPT_DIR/configs/sddm.conf.autologin" /etc/sddm.conf

# Return to Game Mode desktop entry
echo "[7/8] Creating 'Return to Game Mode' menu entry..."
mkdir -p "$HOME/.local/share/applications"
cp "$SCRIPT_DIR/configs/return-to-gamemode.desktop" "$HOME/.local/share/applications/"

# Steam autostart for desktop mode
echo "[8/8] Installing Steam autostart for desktop mode..."
mkdir -p "$HOME/.config/autostart"
cp "$SCRIPT_DIR/configs/autostart/steam.desktop" "$HOME/.config/autostart/steam.desktop"

echo ""
echo "=== Session setup complete! ==="
