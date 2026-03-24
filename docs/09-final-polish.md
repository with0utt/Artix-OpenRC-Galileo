# Phase 9: Final Polish

## Brightness Control

### QAM Brightness Slider (Game Mode)

Simply installing `brightnessctl` enables the QAM brightness slider:

```bash
sudo pacman -S brightnessctl
```

### KDE Brightness Slider (Desktop Mode)

Create a udev rule granting the `video` group write access to the backlight:

```bash
sudo cp configs/90-backlight.rules /etc/udev/rules.d/90-backlight.rules

# Apply immediately
sudo chgrp video /sys/class/backlight/amdgpu_bl0/brightness
sudo chmod g+w /sys/class/backlight/amdgpu_bl0/brightness
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight
```

## Performance Overlay

```bash
sudo pacman -S mangohud
```

The `--mangoapp` flag in the Gamescope session script enables the overlay in Game Mode.

## Bluetooth

```bash
sudo groupadd bluetooth  # if not already created
sudo usermod -aG bluetooth deck
```

BlueZ service should already be running from Phase 3.

## Steam Input (uinput)

Steam needs write access to `/dev/uinput` to create virtual input devices for the
virtual keyboard and controller input remapping. Without it, a KDE authorization popup
may appear when Steam launches in desktop mode.

Install the udev rule (the `deck` user must already be in the `input` group, which
Phase 3 handles):

```bash
sudo cp configs/99-input.rules /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=misc
```

`scripts/08-setup-brightness.sh` does this automatically.

If a KDE "Control input devices" popup still appears after this, see
[`docs/experimental.md`](experimental.md) for a proposed polkit rule.

## Optional: WirePlumber Audio Routing

Copy the audio routing config to prioritize the Filter Chain Sink:

```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp configs/50-audio-routing.conf ~/.config/wireplumber/wireplumber.conf.d/
```
