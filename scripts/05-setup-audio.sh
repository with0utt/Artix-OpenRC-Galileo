#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 5: Audio (PipeWire) Setup
# =============================================================================

echo "=== Phase 5: Audio Setup ==="

# Remove PulseAudio
echo "[1/6] Removing PulseAudio and jack2..."
sudo pacman -Rdd --noconfirm pulseaudio pulseaudio-bluetooth pulseaudio-zeroconf jack2 2>/dev/null || true

# Install PipeWire stack
echo "[2/6] Installing PipeWire stack..."
sudo pacman -S --needed --noconfirm \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    lilv lv2 alsa-utils alsa-firmware sof-firmware rtkit brightnessctl \
    --overwrite '/usr/share/pipewire/*' \
    --overwrite '/usr/share/alsa/alsa.conf.d/*'

# Activate Galileo (OLED) PipeWire filter chain
echo "[3/6] Activating Galileo PipeWire filter chain..."
sudo mkdir -p /usr/share/pipewire/pipewire.conf.d
sudo ln -sf /usr/share/pipewire/hardware-profiles/valve-galileo/pipewire.conf.d/filter-chain-sink.conf \
    /usr/share/pipewire/pipewire.conf.d/filter-chain-sink.conf

# NOTE: Do NOT symlink filter-chain.conf (mic filter) until librnnoise_ladspa.so is installed
echo "  ⚠️  NOT linking mic filter chain (requires librnnoise_ladspa.so)"

# Activate Galileo WirePlumber configs
echo "[4/6] Activating Galileo WirePlumber configs..."
sudo mkdir -p /usr/share/wireplumber/wireplumber.conf.d
for f in /usr/share/wireplumber/hardware-profiles/valve-galileo/wireplumber.conf.d/*.conf; do
    sudo ln -sf "$f" "/usr/share/wireplumber/wireplumber.conf.d/$(basename "$f")"
done

# Fix UCM profile
echo "[5/6] Patching UCM profile (removing dsmparam.bin dependency)..."
sudo sed -i '/dsmparam/s/^/# /' /usr/share/alsa/ucm2/conf.d/sof-nau8821-max/HiFi.conf

# Set up XDG autostart for KDE
echo "[6/6] Setting up PipeWire autostart for KDE..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.config/autostart"
cp "$SCRIPT_DIR/configs/autostart/pipewire.desktop" "$HOME/.config/autostart/"
cp "$SCRIPT_DIR/configs/autostart/wireplumber.desktop" "$HOME/.config/autostart/"
cp "$SCRIPT_DIR/configs/autostart/pipewire-pulse.desktop" "$HOME/.config/autostart/"

echo "=== Audio setup complete! ==="
echo "After starting PipeWire, set the default sink with:"
echo "  wpctl status"
echo "  wpctl set-default <FILTER_CHAIN_SINK_ID>"
