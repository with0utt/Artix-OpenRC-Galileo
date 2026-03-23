# Phase 8: Session Switching (Desktop ↔ Game Mode)

Enable seamless switching between Desktop Mode (KDE Plasma) and Game Mode (Gamescope)
via Steam's built-in UI buttons.

## Steps

### 1. Install the Session Helper Script

This root-level helper modifies `/etc/sddm.conf` to swap the active session:

```bash
sudo cp scripts/steamos-session-helper /usr/bin/steamos-session-helper
sudo chmod +x /usr/bin/steamos-session-helper
```

### 2. Configure Passwordless Sudo

```bash
sudo cp configs/steam-session.sudoers /etc/sudoers.d/steam-session
sudo chmod 440 /etc/sudoers.d/steam-session
```

### 3. Install the Session Selector Script

This is the script Steam calls when "Switch to Desktop" is clicked:

```bash
sudo cp scripts/steamos-session-select /usr/bin/steamos-session-select
sudo chmod +x /usr/bin/steamos-session-select
```

### 4. Create "Return to Game Mode" Menu Entry

```bash
mkdir -p ~/.local/share/applications
cp configs/return-to-gamemode.desktop ~/.local/share/applications/
```

## How It Works

- **Game Mode → Desktop**: Steam calls `steamos-session-select plasma`, which updates
  `sddm.conf` and shuts down Steam. SDDM relaunches into KDE.
- **Desktop → Game Mode**: User clicks "Return to Game Mode" in the application menu,
  which calls `steamos-session-select gamescope`. The script updates `sddm.conf` and
  logs out of KDE (with multiple fallback methods for Plasma 6 compatibility).

## Key Warnings

- KDE Plasma 6 uses `qdbus6`, not `qdbus`. The session select script includes fallbacks
  for both, plus `dbus-send`, `loginctl`, and SDDM restart.
- Steam expects `steamos-session-select` to exist at `/usr/bin/steamos-session-select`.
  Without it, "Switch to Desktop" hangs.
