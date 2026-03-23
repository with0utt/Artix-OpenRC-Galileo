# Phase 2: Firmware Extraction from SteamOS OLED Recovery Image

The OLED requires firmware not included in the standard `linux-firmware` package. Firmware
must be extracted from the official SteamOS recovery image.

## Steps

### 1. Download the Correct Recovery Image

Download the **OLED** recovery image from:
`https://steamdeck-images.steamos.cloud/recovery/`

Look for: `steamdeck-repair-20250521.10-3.7.7` (or newer OLED-specific image).

> ⚠️ **Do NOT use the LCD recovery image.** The LCD image has kernel 5.13 which predates
> the OLED entirely.

### 2. Mount the Image

```bash
sudo losetup -Pf steamdeck-repair-*.img
LOOPDEV=$(losetup -l | grep steamdeck | awk &#x27;{print $1}&#x27;)
sudo mkdir -p /mnt/steamos
sudo mount ${LOOPDEV}p3 /mnt/steamos
```

### 3. Verify It's the OLED Image

```bash
ls /mnt/steamos/lib/modules/
# Should show 6.x kernel (e.g., 6.11.11-valve14-1-neptune-611), NOT 5.13
```

### 4. Copy Firmware Files

```bash
# Cirrus CS35L41 speaker firmware
sudo mkdir -p /lib/firmware/cirrus
sudo cp -r /mnt/steamos/usr/lib/firmware/cirrus/* /lib/firmware/cirrus/

# SOF DSP firmware
sudo mkdir -p /lib/firmware/amd/sof /lib/firmware/amd/sof-tplg
sudo cp /mnt/steamos/usr/lib/firmware/amd/sof/sof-vangogh-code.bin /lib/firmware/amd/sof/
sudo cp /mnt/steamos/usr/lib/firmware/amd/sof/sof-vangogh-data.bin /lib/firmware/amd/sof/
sudo cp /mnt/steamos/usr/lib/firmware/amd/sof/sof-vangogh.ldc /lib/firmware/amd/sof/
sudo cp /mnt/steamos/usr/lib/firmware/amd/sof-tplg/sof-vangogh-nau8821-max.tplg /lib/firmware/amd/sof-tplg/

# Valve&#x27;s LV2 DSP plugins
sudo mkdir -p /usr/lib/lv2
sudo cp -r /mnt/steamos/usr/lib/lv2/valve_deck_speakers.lv2 /usr/lib/lv2/
sudo cp -r /mnt/steamos/usr/lib/lv2/valve_deck_microphone.dsp /usr/lib/lv2/
sudo cp -r /mnt/steamos/usr/lib/lv2/valve_binaural.lv2 /usr/lib/lv2/

# UCM2 audio profiles
sudo cp -rf /mnt/steamos/usr/share/alsa/ucm2/* /usr/share/alsa/ucm2/

# PipeWire and WirePlumber hardware profiles
sudo cp -r /mnt/steamos/usr/share/pipewire/hardware-profiles /usr/share/pipewire/
sudo cp -r /mnt/steamos/usr/share/wireplumber/hardware-profiles /usr/share/wireplumber/

# Hardware support scripts
sudo mkdir -p /usr/lib/hwsupport
sudo cp -r /mnt/steamos/usr/lib/hwsupport/* /usr/lib/hwsupport/ 2&gt;/dev/null
```

### 5. Clean Up

```bash
sudo umount /mnt/steamos
sudo losetup -d $LOOPDEV
```

## Key Warnings

- Firmware paths differ between LCD and OLED images. The OLED uses `/usr/lib/firmware/`
  (note: `usr/lib`, not just `lib`).
- CS35L41 firmware files are **zstd-compressed** (`.zst` extension). Valve's Neptune kernel
  handles decompression natively — copy them as-is.
- The `dsmparam.bin` file does **not** exist in the `steamdeck-dsp` package. It's likely
  generated during factory calibration. You'll comment out the UCM reference to it in Phase 5.
- The `$LOOPDEV` variable can become stale between operations. Re-create it if needed with
  `sudo losetup -Pf <image>`.
