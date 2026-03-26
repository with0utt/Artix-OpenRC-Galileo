# Artix Linux OpenRC on Steam Deck OLED — Complete Install Guide

A comprehensive, battle-tested guide for installing **Artix Linux with OpenRC** on the
**Steam Deck OLED**, with full hardware support including Wi-Fi, audio (speakers + headphones),
GPU acceleration, HDR Game Mode, and seamless Desktop ↔ Game Mode session switching.

This repository was derived from a complete post-install analysis documenting every step,
failure, and fix encountered during the process.

## What Works

- ✅ **Wi-Fi** (QCA2066 / ath11k)
- ✅ **GPU** (AMD RDNA 2 / amdgpu + Vulkan)
- ✅ **Speakers** (CS35L41 via SOF DSP + Valve LV2 filter chain)
- ✅ **Headphones** (NAU8821 via SOF topology)
- ✅ **Game Mode** (Gamescope session with HDR, 90 Hz, adaptive sync)
- ✅ **Desktop Mode** (KDE Plasma via SDDM)
- ✅ **Session Switching** (Desktop ↔ Game Mode via Steam UI)
- ✅ **Brightness Control** (QAM slider + KDE slider)
- ✅ **Bluetooth**
- ✅ **Performance Overlay** (MangoHud)

## Prerequisites

### Hardware

- Steam Deck **OLED** (Galileo — this guide does NOT apply to the LCD model)

### Software (on the Deck or a build machine)

- A working **Artix Linux OpenRC** base installation (with `base-devel` installed)
- Internet connectivity (Ethernet adapter or USB tethering recommended for initial setup)
- ~20 GB free disk space for kernel compilation

### Required Packages (installed during the guide)

- `base-devel bc cpio xmlto python pahole` (kernel build)
- `networkmanager elogind dbus sddm` (with OpenRC counterparts)
- `mesa vulkan-radeon` (graphics)
- `pipewire wireplumber` (audio)
- `steam gamescope mangohud brightnessctl` (gaming)

### Downloads Needed

1. **Valve Neptune kernel source**: `linux-neptune-615-6.15.8.valve1-2.src.tar.gz` from
   `https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-staging/`
2. **SteamOS OLED recovery image**: `steamdeck-repair-20250521.10-3.7.7` from
   `https://steamdeck-images.steamos.cloud/recovery/`

> ⚠️ **Do NOT use the LCD recovery image.** Verify the image contains a 6.x kernel
> (not 5.13) by checking `/lib/modules/` after mounting.

## Quick Start

```bash
# Clone this repository
git clone https://github.com/with0utt/artix-openrc-galileo.git
cd artix-openrc-galileo

# Follow the phases in order:
# Phase 1: Build and install Valve's Neptune kernel
#   See docs/01-kernel-build.md or run:
#   bash scripts/01-build-kernel.sh

# Phase 2: Extract firmware from SteamOS OLED recovery image
#   See docs/02-firmware-extraction.md or run:
#   bash scripts/02-extract-firmware.sh /path/to/steamdeck-repair-*.img

# Phase 3–9: Follow the remaining docs in order
#   See docs/ folder for step-by-step guides

# Or run the setup scripts sequentially:
bash scripts/03-setup-services.sh
bash scripts/04-install-graphics.sh
bash scripts/05-setup-audio.sh
bash scripts/06-install-steam.sh
bash scripts/07-setup-sessions.sh
bash scripts/08-setup-brightness.sh
```

> 📖 **Read the full docs before running scripts.** The scripts are provided as a
> convenience but the process has many decision points that benefit from understanding.

## Repository Layout

| Path | Description |
|------|-------------|
| `docs/` | Step-by-step guides broken into 9 logical phases |
| `scripts/` | Reusable shell scripts for each phase |
| `configs/` | All configuration files referenced in the guide |
| `TROUBLESHOOTING.md` | 30 known problems with causes and solutions |
| `docs/experimental.md` | Untested fixes for broken features (TDP, volume keys, suspend, fan, Decky) |

## Phase Overview

| Phase | Guide | Description |
|-------|-------|-------------|
| 1 | [Kernel Build](docs/01-kernel-build.md) | Build Valve's Neptune kernel from source |
| 2 | [Firmware Extraction](docs/02-firmware-extraction.md) | Extract OLED firmware from SteamOS recovery image |
| 3 | [Core Services](docs/03-core-services.md) | Set up OpenRC services (elogind, NetworkManager, SDDM, etc.) |
| 4 | [Graphics Stack](docs/04-graphics-stack.md) | Install Mesa, Vulkan, and AMD GPU drivers |
| 5 | [Audio / PipeWire](docs/05-audio-pipewire.md) | Configure the full audio stack with Valve's DSP plugins |
| 6 | [Steam & Gaming](docs/06-steam-and-gaming.md) | Install Steam, Gamescope, and MangoHud |
| 7 | [Gamescope Session](docs/07-gamescope-session.md) | Create a dedicated Game Mode SDDM session |
| 8 | [Session Switching](docs/08-session-switching.md) | Enable Desktop ↔ Game Mode switching |
| 9 | [Final Polish](docs/09-final-polish.md) | Brightness control, Bluetooth, performance overlay |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting issues and submitting changes.

## License

MIT — see [LICENSE](LICENSE) for details. Valve's firmware, DSP plugins,
and kernel patches are subject to Valve's licensing terms.
