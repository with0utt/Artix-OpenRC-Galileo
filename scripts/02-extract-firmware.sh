#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 2: Extract Firmware from SteamOS OLED Recovery Image
# =============================================================================
# Usage: bash 02-extract-firmware.sh /path/to/steamdeck-repair-*.img
# =============================================================================

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-steamdeck-recovery-image.img>"
    exit 1
fi

IMAGE="$1"
MOUNTPOINT="/mnt/steamos"

# Clean up loop device and mount on exit (success or failure)
cleanup() {
    sudo umount "$MOUNTPOINT" 2>/dev/null || true
    if [ -n "${LOOPDEV:-}" ]; then
        sudo losetup -d "$LOOPDEV" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "=== Phase 2: Firmware Extraction ==="

# Mount the image
echo "[1/8] Mounting recovery image..."
LOOPDEV=$(sudo losetup --show -Pf "$IMAGE")
sudo mkdir -p "$MOUNTPOINT"
sudo mount "${LOOPDEV}p3" "$MOUNTPOINT"

# Verify OLED image
echo "[2/8] Verifying OLED image..."
# shellcheck disable=SC2012
KERNEL_VER=$(ls "$MOUNTPOINT/lib/modules/" 2>/dev/null | head -1)
echo "  Found kernel: $KERNEL_VER"
if [[ "$KERNEL_VER" == 5.* ]]; then
    echo "ERROR: This appears to be the LCD recovery image (kernel 5.x)."
    echo "       Download the OLED image instead."
    sudo umount "$MOUNTPOINT"
    sudo losetup -d "$LOOPDEV"
    exit 1
fi
echo "  ✓ OLED image confirmed."

# Copy Cirrus CS35L41 speaker firmware
echo "[3/8] Copying Cirrus CS35L41 speaker firmware..."
sudo mkdir -p /lib/firmware/cirrus
sudo cp -r "$MOUNTPOINT/usr/lib/firmware/cirrus/"* /lib/firmware/cirrus/

# Copy SOF DSP firmware
echo "[4/8] Copying SOF DSP firmware..."
sudo mkdir -p /lib/firmware/amd/sof /lib/firmware/amd/sof-tplg
sudo cp "$MOUNTPOINT/usr/lib/firmware/amd/sof/sof-vangogh-code.bin" /lib/firmware/amd/sof/
sudo cp "$MOUNTPOINT/usr/lib/firmware/amd/sof/sof-vangogh-data.bin" /lib/firmware/amd/sof/
sudo cp "$MOUNTPOINT/usr/lib/firmware/amd/sof/sof-vangogh.ldc" /lib/firmware/amd/sof/
sudo cp "$MOUNTPOINT/usr/lib/firmware/amd/sof-tplg/sof-vangogh-nau8821-max.tplg" /lib/firmware/amd/sof-tplg/

# Copy Valve's LV2 DSP plugins
echo "[5/8] Copying Valve LV2 DSP plugins..."
sudo mkdir -p /usr/lib/lv2
sudo cp -r "$MOUNTPOINT/usr/lib/lv2/valve_deck_speakers.lv2" /usr/lib/lv2/
sudo cp -r "$MOUNTPOINT/usr/lib/lv2/valve_deck_microphone.dsp" /usr/lib/lv2/
sudo cp -r "$MOUNTPOINT/usr/lib/lv2/valve_binaural.lv2" /usr/lib/lv2/

# Copy UCM2 profiles
echo "[6/8] Copying ALSA UCM2 profiles..."
sudo cp -rf "$MOUNTPOINT/usr/share/alsa/ucm2/"* /usr/share/alsa/ucm2/

# Copy PipeWire and WirePlumber hardware profiles
echo "[7/8] Copying PipeWire/WirePlumber hardware profiles..."
sudo cp -r "$MOUNTPOINT/usr/share/pipewire/hardware-profiles" /usr/share/pipewire/
sudo cp -r "$MOUNTPOINT/usr/share/wireplumber/hardware-profiles" /usr/share/wireplumber/
sudo mkdir -p /usr/lib/hwsupport
sudo cp -r "$MOUNTPOINT/usr/lib/hwsupport/"* /usr/lib/hwsupport/ 2>/dev/null || true

# Clean up (trap handler will also run, but explicit cleanup is clearer)
echo "[8/8] Cleaning up..."
sudo umount "$MOUNTPOINT"
sudo losetup -d "$LOOPDEV"
LOOPDEV=""  # Prevent trap from double-detaching

echo "=== Firmware extraction complete! ==="
