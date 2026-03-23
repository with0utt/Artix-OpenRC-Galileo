# Phase 3: Core OpenRC Services

Set up the essential system services for session management, networking, Bluetooth, display,
audio, and time synchronization.

## Steps

### 1. Session Management

```bash
sudo pacman -S elogind elogind-openrc lib32-elogind dbus dbus-openrc
sudo rc-update add elogind default
sudo rc-update add dbus default
```

### 2. Networking

```bash
sudo pacman -S networkmanager networkmanager-openrc
sudo rc-update add NetworkManager default
```

### 3. Bluetooth

```bash
sudo pacman -S bluez bluez-utils bluez-openrc
sudo rc-update add bluetoothd default
sudo groupadd bluetooth
sudo usermod -aG bluetooth,input,video,audio,seat deck
```

> ⚠️ The `bluetooth` group must be created manually. Unlike systemd distros,
> Artix/OpenRC doesn't auto-create it.

### 4. Display Manager

```bash
sudo pacman -S sddm sddm-openrc
sudo rc-update add sddm default
```

### 5. Audio Base

```bash
sudo rc-update add alsasound default
```

### 6. Time Sync

```bash
sudo pacman -S chrony chrony-openrc
sudo rc-update add chronyd default
```
