# Phase 5: Audio Stack Configuration (PipeWire)

This is the **most complex** subsystem to configure. The OLED's audio runs through Valve's
SOF DSP pipeline with custom LV2 plugins for EQ, compression, and speaker protection.

## Steps

### 1. Remove Conflicting Packages

```bash
sudo pacman -Rdd pulseaudio pulseaudio-bluetooth pulseaudio-zeroconf jack2
```

### 2. Install PipeWire Stack

```bash
sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    lilv lv2 alsa-utils alsa-firmware sof-firmware rtkit brightnessctl \
    --overwrite &#x27;/usr/share/pipewire/*&#x27; \
    --overwrite &#x27;/usr/share/alsa/alsa.conf.d/*&#x27;
```

The `--overwrite` flags resolve file conflicts from earlier SteamOS firmware copies.

### 3. Activate Galileo (OLED) PipeWire Filter Chain

```bash
sudo mkdir -p /usr/share/pipewire/pipewire.conf.d
sudo ln -sf /usr/share/pipewire/hardware-profiles/valve-galileo/pipewire.conf.d/filter-chain-sink.conf \
    /usr/share/pipewire/pipewire.conf.d/filter-chain-sink.conf
```

> ⚠️ **Do NOT symlink `filter-chain.conf`** (the mic filter) unless you have
> `librnnoise_ladspa.so` installed. The module is marked mandatory and PipeWire will
> **crash on every start** without it.

### 4. Activate Galileo WirePlumber Configs

```bash
sudo mkdir -p /usr/share/wireplumber/wireplumber.conf.d
for f in /usr/share/wireplumber/hardware-profiles/valve-galileo/wireplumber.conf.d/*.conf; do
    sudo ln -sf &quot;$f&quot; /usr/share/wireplumber/wireplumber.conf.d/$(basename &quot;$f&quot;)
done
```

### 5. Fix UCM Profile (Remove dsmparam.bin Dependency)

The UCM profile references `/etc/dsmparam.bin` (factory calibration) which doesn't exist:

```bash
sudo sed -i &#x27;/dsmparam/s/^/# /&#x27; /usr/share/alsa/ucm2/conf.d/sof-nau8821-max/HiFi.conf
```

### 6. Set Up PipeWire Autostart for KDE (OpenRC)

Since there are no systemd user services, PipeWire starts via XDG autostart desktop files.
Copy the files from `configs/autostart/` to `~/.config/autostart/`:

```bash
mkdir -p ~/.config/autostart
cp configs/autostart/pipewire.desktop ~/.config/autostart/
cp configs/autostart/wireplumber.desktop ~/.config/autostart/
cp configs/autostart/pipewire-pulse.desktop ~/.config/autostart/
```

### 7. Set Default Audio Sink

After PipeWire is running, the default sink may be HDMI instead of speakers:

```bash
# List sinks to find the Filter Chain Sink ID
wpctl status

# Set the Filter Chain Sink as default (ID may vary)
wpctl set-default &lt;FILTER_CHAIN_SINK_ID&gt;
```

## Key Warnings

- Speaker output is on **`hw:1,1`** (I2SHS), NOT `hw:1,0` (headphones).
- Always use the **Filter Chain Sink** as default output — it routes through Valve's
  `valve_deck_speakers` LV2 plugin for EQ, compression, and speaker protection.
- PipeWire startup order matters: `pipewire` → `wireplumber` (1s delay) → `pipewire-pulse` (2s delay).
- CS35L41 will NOT appear in `dmesg` even when working correctly on the OLED.
