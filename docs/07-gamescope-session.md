# Phase 7: Gamescope Session (Game Mode)

Create a dedicated SDDM Wayland session that boots directly into Gamescope (Game Mode).

> ⚠️ Do NOT launch Gamescope nested inside KDE (via autostart). This results in title bars,
> taskbar visibility, and limited QAM functionality. You need a **dedicated SDDM session**.

## Steps

### 1. Create the Session Script

```bash
sudo mkdir -p /usr/share/gamescope-custom
sudo cp configs/gamescope-session.sh /usr/share/gamescope-custom/gamescope-session.sh
sudo chmod +x /usr/share/gamescope-custom/gamescope-session.sh
```

### 2. Create the SDDM Session Entry

```bash
sudo cp configs/gamescope-session.desktop /usr/share/wayland-sessions/gamescope-session.desktop
```

### 3. Configure SDDM Autologin

Edit `/etc/sddm.conf` directly (**not** `.conf.d` — the main config overrides `.conf.d` files):

```ini
[Autologin]
Relogin=true
Session=gamescope-session
User=deck

[General]
RememberLastSession=false
```

## Key Warnings

- `--force-orientation left` produces an **upside-down display** on the OLED. Use
  `--force-orientation right`.
- HDR requires DRM backend mode. The session script includes `unset DISPLAY` and
  `unset WAYLAND_DISPLAY` to prevent nesting.
- `-r 90` is needed for the OLED's native 90 Hz refresh rate (defaults to 60 Hz without it).
- `--mangoapp` requires `mangohud` to be installed.
- The session script starts `xdg-desktop-portal` before Gamescope. Without it, Proton games
  may hang on "Starting launch..." because pressure-vessel expects a portal on D-Bus.
- Half-rate shading is **not available** in upstream Gamescope (Valve-custom feature).
- `Relogin=true` means SDDM immediately relaunches the session when it exits. To escape
  Game Mode from a TTY: change Session to `plasma` in `sddm.conf` first, THEN kill gamescope.
- SDDM uses **VT2** — `Ctrl+Alt+F2` shows a black screen. Use `Ctrl+Alt+F3` or higher for TTYs.
