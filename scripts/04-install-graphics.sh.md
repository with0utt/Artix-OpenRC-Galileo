#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 4: Graphics Stack
# =============================================================================

echo "=== Phase 4: Graphics Stack ==="

sudo pacman -S --needed --noconfirm \
    mesa lib32-mesa \
    vulkan-radeon lib32-vulkan-radeon \
    xf86-video-amdgpu \
    mesa-vdpau lib32-mesa-vdpau \
    libva-mesa-driver lib32-libva-mesa-driver \
    vulkan-icd-loader lib32-vulkan-icd-loader

echo "=== Graphics stack installed! ==="
echo "Reboot into the Neptune kernel and verify with: vulkaninfo | head -20"
