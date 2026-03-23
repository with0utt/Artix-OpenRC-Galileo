#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase 1: Build Valve's Neptune Kernel for Steam Deck OLED
# =============================================================================
# This script downloads, patches, and builds the Neptune kernel.
# Run from your home directory or a build directory with ~20 GB free space.
# Estimated build time on the Deck: 1-2+ hours.
# =============================================================================

KERNEL_URL="https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-staging/linux-neptune-615-6.15.8.valve1-2.src.tar.gz"
KERNEL_TAR="linux-neptune-615-6.15.8.valve1-2.src.tar.gz"
KERNEL_DIR="linux-neptune-615"

echo "=== Phase 1: Kernel Build ==="

# Step 1: Install build dependencies
echo "[1/7] Installing build dependencies..."
sudo pacman -S --needed --noconfirm base-devel bc cpio xmlto python pahole

# Step 2: Download kernel source
if [ ! -f "$KERNEL_TAR" ]; then
    echo "[2/7] Downloading kernel source..."
    wget "$KERNEL_URL"
else
    echo "[2/7] Kernel source tarball already exists, skipping download."
fi

# Step 3: Extract
if [ ! -d "$KERNEL_DIR" ]; then
    echo "[3/7] Extracting kernel source..."
    tar xf "$KERNEL_TAR"
else
    echo "[3/7] Kernel directory already exists, skipping extraction."
fi

cd "$KERNEL_DIR"

# Step 4: Fix GCC 15.2 build error
echo "[4/7] Patching -Werror flags for GCC 15+ compatibility..."
if [ -d "src/archlinux-linux-neptune" ]; then
    cd src/archlinux-linux-neptune
    find tools/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

    # Step 5: Remove .git to prevent version string issues
    echo "[5/7] Removing .git directory for clean version string..."
    rm -rf .git
    rm -f include/config/kernel.release
    make -s kernelrelease > version

    cd ../..
fi

# Step 6: Build
echo "[6/7] Building kernel (this will take a while)..."
makepkg -s -e --skippgpcheck

# Step 7: Install
echo "[7/7] Installing kernel packages..."
echo ""
echo "Run the following commands to install:"
echo "  sudo pacman -U linux-neptune-615-6.15.8.valve1-2-x86_64.pkg.tar.zst \\"
echo "                 linux-neptune-615-headers-6.15.8.valve1-2-x86_64.pkg.tar.zst"
echo ""
echo "Then generate initramfs and update GRUB:"
echo "  sudo mkinitcpio -k 6.15.8-valve1-2-neptune-615 -g /boot/initramfs-neptune.img"
echo "  sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo ""
echo "=== Kernel build complete! ==="
