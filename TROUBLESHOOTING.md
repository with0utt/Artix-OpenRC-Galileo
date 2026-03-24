# Troubleshooting Guide

A comprehensive list of every problem encountered during the Artix Linux OpenRC installation
on the Steam Deck OLED, with causes and solutions.

---

## Kernel Build Issues

### 1. Valve's binary package repos return 404

- **Cause**: `steamdeck-packages.steamos.cloud/archlinux-mirror/$repo/os/$arch` is down.
- **Solution**: Use the source path instead:
  `https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-staging/`

### 2. Valve GitLab mirror is stale

- **Cause**: Last commit was years ago, no Galileo/OLED support.
- **Solution**: Use Valve's source tarballs directly from the URL above.

### 3. GCC 15.2 build error (`-Werror=discarded-qualifiers`)

- **Cause**: Valve's kernel source was written for older GCC; `const char *` strictness
  changed in GCC 15.
- **Solution**:

  ```bash
  find tools/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +
  ```

### 4. `makepkg` wipes source modifications on rebuild

- **Cause**: The `-s` flag triggers re-extraction of sources from git.
- **Solution**: Use `makepkg -s -e --skippgpcheck` (`-e` skips extract/prepare).

### 5. `-dirty` suffix in kernel version string

- **Cause**: Uncommitted changes in git-tracked files.
- **Solution**: Commit changes with `git add -A && git commit`, or remove `.git` entirely.

### 6. Version string mismatch between `build()` and `package()`

- **Cause**: `prepare()` cached a version file with the old git hash; a new hash was
  generated after commit.
- **Solution**: Remove `.git` directory and `include/config/kernel.release`, then run
  `make -s kernelrelease > version`.

### 7. `.scmversion` file didn't suppress git suffix

- **Cause**: `echo ""` writes a newline (1 byte), not an empty file (0 bytes).
- **Solution**: Remove `.git` entirely instead of using `.scmversion`.

### 8. `depmod` error (`/doesnt/exist`)

- **Cause**: Intentional — Arch PKGBUILDs set `DEPMOD=/doesnt/exist` to skip depmod
  during packaging.
- **Solution**: This is a **harmless warning** — ignore it.

---

## Firmware Issues

### 9. Wrong SteamOS recovery image (LCD model)

- **Cause**: Downloaded the first available image; it had kernel 5.13 (LCD era).
- **Solution**: Download the OLED-specific image: `steamdeck-repair-20250521.10-3.7.7`.
  Verify by checking the kernel version in `/lib/modules/` (should be 6.x).

### 10. CS35L41 not appearing in `dmesg`

- **Cause**: On the OLED, CS35L41 is driven through the SOF DSP pipeline, not as a
  standalone ACPI device.
- **Solution**: This is **expected behavior**. Speakers are accessible at `hw:1,1` through SOF.

---

## Audio Issues

### 11. PipeWire crashes: `librnnoise_ladspa.so` not found

- **Cause**: Microphone filter chain references a missing LADSPA plugin; module is marked
  mandatory.
- **Solution**:

  ```bash
  sudo rm /usr/share/pipewire/pipewire.conf.d/filter-chain.conf
  ```

  Keep only the speaker filter chain (`filter-chain-sink.conf`).

### 12. UCM fails: "Failed to enable UCM device Speaker"

- **Cause**: UCM `HiFi.conf` references `/etc/dsmparam.bin` (factory calibration) which
  doesn't exist.
- **Solution**: Comment out the `cset-tlv` line referencing `dsmparam.bin`:

  ```bash
  sudo sed -i '/dsmparam/s/^/# /' /usr/share/alsa/ucm2/conf.d/sof-nau8821-max/HiFi.conf
  ```

### 13. `speaker-test` produces no sound through PipeWire

- **Cause**: Default sink is set to HDMI output, not speakers.
- **Solution**: `wpctl set-default <FILTER_CHAIN_SINK_ID>` (find the ID with `wpctl status`).

### 14. PulseAudio conflicts blocking PipeWire install

- **Cause**: `pulseaudio-bluetooth` and `pulseaudio-zeroconf` depend on `pulseaudio`.
- **Solution**:

  ```bash
  sudo pacman -Rdd pulseaudio pulseaudio-bluetooth pulseaudio-zeroconf jack2
  ```

### 15. File conflicts during PipeWire install

- **Cause**: Earlier SteamOS copies placed files in `/usr/share/pipewire/`.
- **Solution**: Use `--overwrite '/usr/share/pipewire/*'` flag with pacman.

---

## SDDM & Session Issues

### 16. SDDM autologin ignoring Gamescope session

- **Cause**: `/etc/sddm.conf` main config overrides `.conf.d` files; had `Session=plasma`
  and `RememberLastSession=true`.
- **Solution**: Edit `/etc/sddm.conf` directly. Set `RememberLastSession=false`.

### 17. Game Mode display upside-down

- **Cause**: `--force-orientation left` conflicted with Gamescope's built-in OLED Lua
  display scripts.
- **Solution**: Change to `--force-orientation right`.

### 18. Gamescope runs nested inside KDE (title bars visible)

- **Cause**: Launched Gamescope from KDE autostart (nested mode).
- **Solution**: Create a dedicated SDDM Wayland session (embedded/DRM mode).

### 19. "Switch to Desktop" hangs in Game Mode

- **Cause**: `steamos-session-select` script didn't exist.
- **Solution**: Create the script at `/usr/bin/steamos-session-select`.

### 20. "Return to Game Mode" shortcut fails

- **Cause**: KDE Plasma 6 uses `qdbus6` not `qdbus`; KDE treated `.desktop` file as text.
- **Solution**: Add `qdbus6` fallbacks; use application menu entry instead of desktop shortcut.

### 21. Can't escape Game Mode via Ctrl+Alt+F2

- **Cause**: SDDM uses VT2 for its display server (black screen on F2).
- **Solution**: Use **Ctrl+Alt+F3** or higher for free TTYs.

### 22. `killall gamescope` → session restarts immediately

- **Cause**: `Relogin=true` in SDDM config relaunches the session.
- **Solution**: Edit `/etc/sddm.conf` to change `Session=plasma` before killing, then
  restart SDDM.

---

## General Artix/OpenRC Issues

### 23. `bluetooth` group doesn't exist

- **Cause**: Artix/OpenRC doesn't auto-create this group (unlike systemd distros).
- **Solution**: `sudo groupadd bluetooth`

### 24. KDE brightness slider doesn't work

- **Cause**: `/sys/class/backlight/amdgpu_bl0/brightness` not writable by user.
- **Solution**: Create a udev rule granting the `video` group write access:

  ```bash
  sudo cp configs/90-backlight.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules
  sudo udevadm trigger --subsystem-match=backlight
  ```

### 25. Refresh rate shows 60 Hz instead of 90 Hz

- **Cause**: Missing `-r 90` flag in Gamescope launch.
- **Solution**: Add `-r 90` to the session script.

### 26. Performance overlay does nothing

- **Cause**: MangoHud not installed.
- **Solution**: `sudo pacman -S mangohud`

### 27. `lib32-mangohud` not found

- **Cause**: Not available in Artix lib32 repo.
- **Solution**: Not needed — 64-bit `mangohud` includes `mangoapp` for Game Mode overlay.

### 28. `steam-native-runtime` not found

- **Cause**: Arch-specific package, not in Artix repos.
- **Solution**: Not needed — Steam uses its own bundled runtime.

### 29. Loop device variable lost between operations

- **Cause**: `$LOOPDEV` becomes stale after `losetup -d` or between sessions.
- **Solution**: Re-create with `sudo losetup -Pf <image>` and recapture the variable.

---

## Hardware Control Issues

### 30. TDP slider does nothing in Game Mode

- **Cause**: `ryzenadj` is not installed. The QAM TDP interface requires it to apply power
  limits to the APU.
- **Solution**: Install from AUR:

  ```bash
  paru -S ryzenadj
  # or: yay -S ryzenadj
  ```

  No additional configuration is needed — Steam detects and uses `ryzenadj` automatically
  once it is present on the system.

### 31. Hardware volume buttons show overlay but don't change volume

- **Cause**: In Game Mode, Steam handles volume key events through the PulseAudio
  compatibility layer (`pipewire-pulse`). If `pipewire-pulse` is not running at session
  start, or the `deck` user is not in the `audio` group, the mixer calls fail silently and
  the overlay appears but the volume does not change.
- **Solution**:
  1. Confirm `deck` is in the `audio` group:

     ```bash
     groups deck   # should include "audio"
     sudo usermod -aG audio deck
     # Log out and back in for group change to take effect
     ```

  2. Confirm `pipewire-pulse.desktop` is in `~/.config/autostart/` (installed by Phase 5)
     and that `pipewire-pulse` is actually running:

     ```bash
     pgrep -a pipewire-pulse
     ```

  3. In Desktop Mode, KDE handles volume keys natively via the PipeWire-PA bridge. If they
     still don't work there, open **System Settings → Audio** and confirm the active output
     device is the Filter Chain Sink, not HDMI.

### 32. Power button immediately powers off instead of suspending

- **Cause**: `elogind`'s default `HandlePowerKey=poweroff` triggers an immediate shutdown.
  On systemd distros, `logind` maps the power key to suspend by default; elogind does not.
- **Solution**:
  1. Edit `/etc/elogind/logind.conf` and set:

     ```ini
     HandlePowerKey=suspend
     ```

  2. Restart elogind:

     ```bash
     sudo rc-service elogind restart
     ```

  The Neptune kernel handles s2idle (suspend-to-idle) correctly on the OLED. If the deck
  does not resume after suspend, press the power button once — the first press wakes it and
  the display may take a moment to come back. A second press will trigger another suspend.

### 33. Fan runs at BIOS defaults / no fan curve control

- **Cause**: SteamOS uses a closed-source `jupiter-fan-control` daemon to manage the fan
  curve. That daemon is not available on Artix. The kernel exposes the fan via
  `/sys/class/hwmon/` but without a userspace controller it runs at EC/BIOS defaults.
- **Solution**: No complete solution exists. The BIOS fan curve is conservative and safe —
  the deck will not overheat. For custom control, `nbfc-linux` (AUR) is a generic fan
  controller that can drive the hwmon interface:

  ```bash
  paru -S nbfc-linux
  ```

  No verified Steam Deck OLED fan profile exists for `nbfc-linux`. Manual tuning via its
  config format is required and results may vary. This is experimental.

### 34. Decky Loader won't auto-start (no systemd)

- **Cause**: Decky Loader's installer registers `plugin_loader.service` as a systemd unit
  for automatic startup. That unit does not exist on OpenRC and Decky will not start.
- **Solution**: Decky can be started manually after launching Steam in Game Mode:

  ```bash
  ~/.local/share/Steam/steamapps/common/Decky\ Loader/backend/backend &
  ```

  To make it persistent, wrap it in an OpenRC user service or add it to the
  `gamescope-session.sh` startup script before the `exec steam ...` line. Note that Decky
  plugins which call systemd D-Bus APIs (e.g. some power management plugins) will still
  fail regardless — this is an upstream limitation and unsupported configuration.
