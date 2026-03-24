#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 7 & 8: Gamescope Session + Session Switching
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Phase 7 & 8: Session Setup ==="

# Gamescope session script
echo "[1/6] Installing Gamescope session script..."
sudo mkdir -p /usr/share/gamescope-custom
sudo cp "$SCRIPT_DIR/configs/gamescope-session.sh" /usr/share/gamescope-custom/gamescope-session.sh
sudo chmod +x /usr/share/gamescope-custom/gamescope-session.sh

# SDDM session entry
echo "[2/6] Installing SDDM session entry..."
sudo cp "$SCRIPT_DIR/configs/gamescope-session.desktop" /usr/share/wayland-sessions/gamescope-session.desktop

# Session helper
echo "[3/6] Installing session helper..."
sudo cp "$SCRIPT_DIR/scripts/steamos-session-helper" /usr/bin/steamos-session-helper
sudo chmod +x /usr/bin/steamos-session-helper

# Session selector
echo "[4/6] Installing session selector..."
sudo cp "$SCRIPT_DIR/scripts/steamos-session-select" /usr/bin/steamos-session-select
sudo chmod +x /usr/bin/steamos-session-select

# Passwordless sudo
echo "[5/6] Configuring passwordless sudo for session helper..."
sudo cp "$SCRIPT_DIR/configs/steam-session.sudoers" /etc/sudoers.d/steam-session
sudo chmod 440 /etc/sudoers.d/steam-session

# Return to Game Mode desktop entry
echo "[6/7] Creating 'Return to Game Mode' menu entry..."
mkdir -p ~/.local/share/applications
cp "$SCRIPT_DIR/configs/return-to-gamemode.desktop" ~/.local/share/applications/

# Steam autostart for desktop mode
echo "[7/7] Installing Steam autostart for desktop mode..."
mkdir -p ~/.config/autostart
cp "$SCRIPT_DIR/configs/autostart/steam.desktop" ~/.config/autostart/steam.desktop

echo ""
echo "=== Session setup complete! ==="
echo ""
echo "IMPORTANT: Edit /etc/sddm.conf and set:"
echo "  [Autologin]"
echo "  Relogin=true"
echo "  Session=gamescope-session"
echo "  User=deck"
echo ""
echo "  [General]"
echo "  RememberLastSession=false"
