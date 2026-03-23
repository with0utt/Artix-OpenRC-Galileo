# Phase 6: Steam & Gaming

## Steps

### 1. Enable the lib32 Repository

Edit `/etc/pacman.conf` and uncomment the `[lib32]` section, then sync:

```bash
sudo pacman -Sy
```

### 2. Install Steam and Dependencies

```bash
sudo pacman -S steam \
    lib32-vulkan-radeon lib32-mesa lib32-pipewire lib32-libpulse \
    vulkan-radeon gamemode lib32-gamemode
```

> `steam-native-runtime` is not available on Artix — it's not needed since Steam ships
> its own bundled runtime.

### 3. Install Gamescope and MangoHud

```bash
sudo pacman -S gamescope mangohud
```

> `lib32-mangohud` is not in Artix repos. It's not needed — the 64-bit `mangohud` package
> includes `mangoapp` for the Game Mode overlay.

### 4. Add User to Required Groups

```bash
sudo usermod -aG input,video,audio,seat deck
```
