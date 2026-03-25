# Experimental / Untested Fixes

> ⚠️ **Most items in this document have NOT been tested on actual hardware** unless
> explicitly marked as "hardware-confirmed".
>
> These are proposed fixes and workarounds based on how these components work on systemd
> distros or general Linux — not on this specific Artix OpenRC setup. They may work, may
> partially work, or may break things. **Do not attempt these until you have the core guide
> working and are comfortable recovering from a broken state.** Treat this as a starting
> point for investigation, not verified instructions.
>
> If you test any of these and can confirm they work (or don't), please open an issue or PR.

---

## TDP Slider Does Nothing in Game Mode

The QAM TDP slider is visible but has no effect.

### What has been tested (hardware-confirmed)

1. **`ryzenadj` does NOT work** — the Neptune kernel does not include the `ryzen_smu` module.
   `ryzenadj` falls back to `/dev/mem` with no way to verify writes actually land, and the
   APU is not fully recognised (`request_table_ver_and_size is not supported on this family`).
   `/sys/class/powercap/` does not exist on this hardware. **Do not use `ryzenadj`.**

2. **hwmon `power1_cap` DOES work** — the `amdgpu` driver exposes a writable `power1_cap`
   sysfs entry. Writing to it correctly caps APU power (confirmed via performance overlay):

   ```bash
   # Find the amdgpu hwmon device (number can change across reboots)
   HWMON=$(for d in /sys/class/hwmon/hwmon*/; do
       grep -q amdgpu "$d/name" 2>/dev/null && echo "$d" && break
   done)

   # Set 8 W cap (values are in microwatts: W × 1,000,000)
   echo 8000000 | sudo tee "${HWMON}power1_cap"
   ```

3. **The QAM slider still doesn't work** because Steam does not call `ryzenadj` or write to
   sysfs directly. Steam calls methods on a D-Bus service called
   `com.steampowered.SteamOSManager1` — Valve's privileged `steamos-manager` daemon, which
   does not exist on Artix.

### Root cause

Steam's TDP slider sends D-Bus calls to `com.steampowered.SteamOSManager1`. On SteamOS,
this service (`steamos-manager`) translates those calls into EC firmware writes. On Artix
OpenRC, the service is completely absent — Steam gets a D-Bus error and fails silently.
No polkit actions are registered either (`pkaction --verbose` shows nothing Steam/Jupiter
related). `dbus-monitor` shows zero bus activity when the slider is moved, confirming the
call never reaches the bus.

### Proposed fix — implement a minimal D-Bus stub service

A small D-Bus service that:

1. Registers as `com.steampowered.SteamOSManager1` on the system bus
2. Implements the TDP-related method(s) that Steam calls
3. Translates those calls into sysfs writes to `power1_cap` (confirmed working above)
4. Runs as an OpenRC service on boot

### What still needs hardware testing

Before building the stub, the exact D-Bus method signatures must be captured. Try these
on hardware while moving the TDP slider in Game Mode:

```bash
# Option 1: busctl monitor (may capture the failed call attempt)
sudo busctl monitor com.steampowered.SteamOSManager1

# Option 2: strace Steam to see the raw D-Bus message
strace -f -e trace=write -p $(pgrep -f "steam.sh" | head -1) 2>&1 | grep -i steamos
```

Alternatively, check Valve's open-source `steamos-manager` repository on their GitLab for
the D-Bus interface definition — that will document the exact method names, signatures, and
expected behavior without needing to reverse-engineer from Steam's calls.

**Unknown**: The exact D-Bus method name and signature Steam uses for TDP control. Whether
a stub service implementing only the TDP method is sufficient or whether Steam probes for
other methods at startup and refuses to show the slider if they're missing. Whether the
`power1_cap` sysfs interface provides fine enough granularity to match the QAM slider's
3–15 W range.

---

## Hardware Volume Buttons Show Overlay But Don't Change Volume

The physical volume up/down buttons bring up the volume HUD but the level doesn't change.
The QAM volume slider works fine. This suggests the input event is received but the mixer
call fails.

### What has been tested (hardware-confirmed)

1. **`deck` is in the `audio` group** — confirmed, not the issue.
2. **`pipewire-pulse` is running in Game Mode** — confirmed, not the issue.
3. **The volume overlay shows the correct sink** (Filter Chain Sink) — the input event
   reaches Steam and Steam knows the right output device.
4. **The QAM volume slider works** — PipeWire volume control itself is functional.

The basic diagnosis steps (group membership, autostart, sink selection) have all been
ruled out. The problem is specific to how Steam handles the hardware volume key events
vs. how it handles the QAM slider internally.

### Root cause hypothesis

Steam's volume key handler and QAM slider likely use different code paths. The QAM slider
probably calls PipeWire/PulseAudio APIs directly (via `libpulse`), while the hardware
volume keys may go through a different mechanism — possibly ALSA mixer, `XF86Audio*`
keysym handling, or a Gamescope-internal volume path that expects a specific mixer element
or D-Bus service.

### Next diagnostic steps (needs hardware testing)

1. **Check if CLI volume control works** — confirm PipeWire volume changes are possible
   from the session context Steam runs in:

   ```bash
   # From a TTY while in Game Mode:
   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
   wpctl get-volume @DEFAULT_AUDIO_SINK@
   ```

   If this works, the issue is in how Steam sends the volume change, not PipeWire itself.

2. **Watch for PipeWire/PulseAudio volume events** — run this while pressing the hardware
   volume buttons to see if any volume change attempt reaches PipeWire:

   ```bash
   # Option A: watch PulseAudio events (Steam uses libpulse)
   pactl subscribe 2>&1 | grep -i volume

   # Option B: watch PipeWire events
   pw-cli dump short 2>&1 | grep -i vol
   ```

   If nothing appears, Steam is not sending any volume command — the overlay is purely
   cosmetic and the key handler is broken.

3. **Check what key events Gamescope sees** — Gamescope intercepts input in embedded mode.
   It may be swallowing the volume key and showing the overlay without forwarding a volume
   change to PipeWire:

   ```bash
   # Check Gamescope's log output for volume key references
   journalctl --user -u gamescope* 2>/dev/null || dmesg | grep -i gamescope
   ```

4. **Check if volume keys work in Desktop Mode** — if they work under KDE but not Game
   Mode, the issue is Gamescope-specific. If they fail in both, it's a PipeWire/ALSA
   mixer mapping issue.

5. **Inspect ALSA mixer elements** — Steam may be trying to change an ALSA mixer control
   that doesn't exist or is named differently under the filter chain:

   ```bash
   amixer -c 0 scontrols
   amixer -c 1 scontrols
   ```

   Compare the available controls with what a stock SteamOS exposes.

**Unknown**: Which code path Steam uses for hardware volume keys in Game Mode — whether
it's Gamescope forwarding `XF86AudioRaiseVolume`/`XF86AudioLowerVolume` to a handler, a
direct ALSA mixer write, or a PulseAudio API call. Whether Gamescope itself is supposed
to handle volume changes in embedded mode on SteamOS (in which case the issue is a
missing Gamescope patch or config), or whether Steam handles it directly.

---

## Power Button Immediately Powers Off Instead of Suspending

Tapping the power button shuts the deck off immediately. On systemd distros, `logind` maps
the power key to suspend by default. On OpenRC, `elogind` defaults to `HandlePowerKey=poweroff`.

**Proposed fix**:

1. Edit `/etc/elogind/logind.conf` and set:

   ```ini
   HandlePowerKey=suspend
   ```

2. Restart elogind:

   ```bash
   sudo rc-service elogind restart
   ```

**Unknown**: Whether s2idle resume works reliably on this kernel/OpenRC combination —
specifically whether the deck wakes correctly from sleep and whether anything hangs on
resume (display, audio, Wi-Fi). The Neptune kernel is expected to handle s2idle on the OLED
but this has not been confirmed in this setup.

---

## Fan Control

Valve's `jupiter-fan-control` daemon manages the fan curve on SteamOS. It is closed-source
and not available on Artix. Without it, the fan runs at EC/BIOS defaults, which is safe but
not optimized for noise or thermals at low load.

**Partial workaround**: `nbfc-linux` is a generic fan controller that can drive hwmon
interfaces:

```bash
paru -S nbfc-linux
```

**Unknown**: No verified Steam Deck OLED fan profile exists for `nbfc-linux`. Manual config
tuning would be required and there's no guarantee it can address the EC registers the Steam
Deck uses. This is genuinely experimental — wrong values could theoretically cause the fan
to run slower than safe. Proceed carefully.

---

## Decky Loader Without systemd

Decky Loader's installer registers `plugin_loader.service` as a systemd unit. That unit
cannot run on OpenRC, so Decky does not start after installation. There is no official OpenRC
support and no community-maintained OpenRC service file exists upstream.

**Step 1 — Install Decky Loader normally**:

Run the official installer from a Desktop Mode terminal:

```bash
curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
```

This installs to `~/homebrew/` (i.e. `/home/deck/homebrew/`). The backend binary ends up at:

```text
/home/deck/homebrew/services/PluginLoader
```

The systemd service it registers (`plugin_loader.service`) will be silently ignored on OpenRC.

**Proposed workaround — manual launch**:

After Steam is running in Game Mode, open a terminal and start the backend manually:

```bash
/home/deck/homebrew/services/PluginLoader &
```

Decky's UI overlay should appear in Steam's QAM after a moment.

**Proposed workaround — persistent launch via session script**:

To start the backend automatically every Game Mode session, add it to
`configs/gamescope-session.sh` before the `exec steam ...` line:

```bash
/home/deck/homebrew/services/PluginLoader &
```

Then redeploy the session config by re-running `scripts/07-setup-sessions.sh`. The Decky
backend will start alongside Steam on every Game Mode launch.

**Hard limitation regardless of workaround**: Decky plugins that call systemd D-Bus APIs
will fail regardless of how the backend is started. This includes many power management and
system control plugins. There is no workaround for this short of implementing the missing
D-Bus interfaces in elogind (which is upstream work).

**Unknown**: Which specific plugins work and which don't in this OpenRC setup. Whether the
PluginLoader binary starts cleanly without the full SteamOS environment (correct user, cgroup
layout, etc.) is also unconfirmed. This has not been tested at all.

---

## Steam Virtual Keyboard Too Large in Desktop Mode

The Steam OSK cuts off at the right edge of the screen (around the P key). The OSK is
designed for 1280 px width; if KDE's global scale is above 1.0×, the rendered width
exceeds the physical screen resolution.

**Proposed fix — reduce KDE global scale**:

Open System Settings → Display & Monitor → Global Scale and set it to 100%.
Log out and back in for the change to take effect.

**Proposed fix — force Steam UI scaling via environment variable**:

Edit `~/.config/autostart/steam.desktop` and change the `Exec` line to:

```ini
Exec=env STEAM_FORCE_DESKTOPUI_SCALING=0.8 steam -silent
```

Adjust the value between 0.8 and 1.0 until the keyboard fits without being cut off.

**Unknown**: Which fix is needed depends on what KDE global scale is configured to on
your install. Both approaches are untested here. The environment variable approach is
preferable if you want to keep system scaling above 100% for readability.

---

## KDE "Control Input Devices" Popup When Steam Opens

Steam requests `kglobalaccel` and/or `uinput` access in desktop mode to register the
Steam+X shortcut and drive the virtual keyboard. KDE prompts for authorization while the
dialog is up, trackpad input is suspended until the button is physically tapped.

The udev rule deployed in Phase 9 (`configs/99-input.rules`) addresses raw `/dev/uinput`
access. If the popup persists after that, it is from KDE's kglobalaccel policy. A polkit
rule can pre-authorize it without requiring a tap each time.

**Proposed fix — polkit rule**:

Create `/etc/polkit-1/rules.d/50-steam-input.rules` with the following content:

```javascript
polkit.addRule(function(action, subject) {
    if (subject.user === "deck" &&
        action.id.indexOf("org.kde.kglobalaccel") === 0) {
        return polkit.Result.YES;
    }
});
```

**Unknown**: The exact polkit action ID has not been confirmed from system logs.
To find the real ID, run `sudo journalctl -f` while Steam starts in desktop mode and
search the output for lines containing `polkit`. Adjust the `action.id` prefix in the
rule to match. The `org.kde.kglobalaccel` prefix above is the most likely candidate
but has not been verified against actual log output.

---

## DeckSP Plugin (Audio DSP via Decky)

DeckSP is a Decky Loader plugin that adds a 7-category audio DSP chain to Game Mode: a
15-band EQ, limiting, compression/expansion, stereo widening, crossfeed, reverb, bass
enhancement, and analog harmonic modelling. It is a frontend for JamesDSP.

**Prerequisite**: The Decky Loader workaround above must be working first. DeckSP is a Decky
plugin and cannot run independently.

**How DeckSP manages JamesDSP**:

DeckSP automatically installs and manages the JamesDSP **Flatpak**
(`com.github.Audio4Linux.JDSP4Linux` from Flathub). It does not detect a native install.
For DeckSP's auto-install to work, Flatpak must be present and Flathub must be configured:

```bash
sudo pacman -S flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

After that, install DeckSP through Decky's plugin store in Game Mode. DeckSP will pull and
launch the JamesDSP Flatpak itself.

**Alternative — native JamesDSP from AUR (no Flatpak)**:

A PipeWire-native AUR package exists and runs directly on Artix/OpenRC without a Flatpak
sandbox:

```bash
paru -S jamesdsp
# or: paru -S jamesdsp-pipewire-bin  (pre-compiled binary)
```

JamesDSP exposes a D-Bus service on the session bus
(`me.timschneeberger.jdsp4linux.Service`) that does not require systemd activation, so it
may register correctly inside a gamescope session on OpenRC. However, DeckSP is hardcoded to
manage the Flatpak version; it will not detect a native AUR install without modifying the
plugin's Python backend.

**Unknown**: Whether DeckSP's Flatpak auto-install succeeds when Flatpak is present but
systemd session portals (`xdg-desktop-portal`) are not running. Whether the native
`jamesdsp` D-Bus service registers and remains discoverable within the gamescope session.
Whether DeckSP's plugin backend can be patched to talk to a native install instead of the
Flatpak. None of this has been tested on this OpenRC setup.
