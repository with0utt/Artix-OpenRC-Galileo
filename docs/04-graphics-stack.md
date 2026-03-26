# Phase 4: Graphics Stack

Install the full AMD GPU driver stack with Vulkan support.

## Steps

```bash
sudo pacman -S \
    mesa lib32-mesa \
    vulkan-radeon lib32-vulkan-radeon \
    xf86-video-amdgpu \
    mesa-vdpau lib32-mesa-vdpau \
    libva-mesa-driver lib32-libva-mesa-driver \
    vulkan-icd-loader lib32-vulkan-icd-loader
```

## Post-Boot Verification

**Reboot now** into the Neptune kernel, then verify:

```bash
# Check GPU
vulkaninfo | head -20

# Check Wi-Fi
ip link show wlan0

# Check kernel
uname -r
# Should show: 6.15.8-valve1-2-neptune-615
```

- **Wi-Fi (QCA2066/ath11k)**: Should work immediately with firmware loaded.
- **GPU (AMD RDNA 2 / amdgpu)**: Vulkan should be confirmed via `vulkaninfo`.
- **Audio**: CS35L41 speakers will NOT appear in `dmesg` — this is expected. On the OLED,
  they're driven through the SOF DSP pipeline.
- **NAU8821 headphone codec**: Should be detected and working via SOF topology.
