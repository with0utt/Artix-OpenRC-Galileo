# Phase 1: Kernel Build (Most Critical Step)

The stock Artix kernel lacks support for the Steam Deck OLED's **Wi-Fi chip (QCA2066)**,
**audio codecs (CS35L41 speakers, NAU8821 headphones)**, and **OLED panel**. Valve's
Neptune kernel is required.

## Why a Custom Kernel?

Valve maintains a forked Linux kernel (`linux-neptune`) with hardware-specific drivers and
patches for the Steam Deck. Without it, Wi-Fi, audio, and display will not function on the
OLED model.

## Steps

### 1. Download the Kernel Source

Valve's binary package repos return 404, but the source path still works:

```bash
wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-staging/linux-neptune-615-6.15.8.valve1-2.src.tar.gz
tar xf linux-neptune-615-6.15.8.valve1-2.src.tar.gz
cd linux-neptune-615
```

> ⚠️ Do NOT use the Valve GitLab mirror — it is stale and lacks Galileo/OLED support.

### 2. Install Build Dependencies

```bash
sudo pacman -S base-devel bc cpio xmlto python pahole
```

### 3. Fix GCC 15.2 Build Error

Valve's kernel source predates GCC 15's stricter `const` qualifier checks. You **must**
strip `-Werror` from the tool Makefiles:

```bash
cd src/archlinux-linux-neptune
find tools/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +
```

### 4. Fix Version String Issues

Modifying tracked git files causes a `-dirty` suffix and version mismatches. The cleanest
fix is to remove `.git` entirely:

```bash
rm -rf .git
rm -f include/config/kernel.release
make -s kernelrelease > version
```

### 5. Build the Kernel

Use `-e` to skip re-extraction (which would wipe your fixes):

```bash
cd ~/linux-neptune-615
makepkg -s -e --skippgpcheck
```

> ⏱️ Building on the Deck itself takes **1–2+ hours**. Consider cross-compiling on a
> faster x86_64 machine.

### 6. Install the Kernel

```bash
sudo pacman -U linux-neptune-615-6.15.8.valve1-2-x86_64.pkg.tar.zst \
               linux-neptune-615-headers-6.15.8.valve1-2-x86_64.pkg.tar.zst
```

### 7. Generate Initramfs and Update Bootloader

```bash
sudo mkinitcpio -k 6.15.8-valve1-2-neptune-615 -g /boot/initramfs-neptune.img
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Key Warnings

- **GCC version matters.** GCC 15+ is stricter. You MUST strip `-Werror` before building.
- **Never modify tracked files after `prepare()` runs** without committing or removing `.git`.
- **`makepkg -e` is essential** when you've already modified the source tree.
- The `depmod` error (`/doesnt/exist`) during packaging is **intentional and harmless** — Arch
  PKGBUILDs set `DEPMOD=/doesnt/exist` to skip depmod during packaging.
