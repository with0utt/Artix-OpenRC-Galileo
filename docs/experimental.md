# Experimental / Untested Fixes

> ⚠️ **Nothing in this document has been tested on actual hardware.**
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

**Tested (hardware-confirmed)**: Installing `ryzenadj` from AUR alone is **not sufficient**.
With `ryzenadj` installed and no other changes, the slider moves freely (3–15 W range is
visible) but has no effect on actual APU power — the performance overlay still shows the
GPU pinned at maximum wattage and thermals/frametimes are unchanged.

**Root cause (likely)**: `ryzenadj` requires root privileges to write APU power limits.
Steam cannot call it without a sudoers rule granting passwordless `sudo` access. On SteamOS,
`/etc/sudoers.d/` includes exactly such a rule; this setup has none.

**Proposed next step — add a sudoers rule**:

Create `/etc/sudoers.d/ryzenadj`:

```bash
sudo visudo -f /etc/sudoers.d/ryzenadj
```

Add this line (replacing `deck` with your username if different):

```text
deck ALL=(root) NOPASSWD: /usr/bin/ryzenadj
```

Set correct permissions (required by sudo):

```bash
sudo chmod 440 /etc/sudoers.d/ryzenadj
```

**Verify ryzenadj itself works** before blaming Steam. Run this manually and check if
actual power consumption changes:

```bash
# Set stapm/fast/slow limits to 10 W (values are in milliwatts)
sudo ryzenadj --stapm-limit=10000 --fast-limit=10000 --slow-limit=10000

# Confirm the change was applied
sudo ryzenadj --info | grep -i limit
```

If `ryzenadj --info` shows the new limits, the binary and kernel interfaces are working.
If not, there may be a kernel interface issue (check that the Neptune kernel exposes the
required MMIO/MSR registers).

**If the sudoers rule doesn't help**: Check Steam's output for TDP-related messages by
launching Steam from a terminal (`steam 2>&1 | grep -i tdp`) while adjusting the slider.
It's possible Steam uses a D-Bus call or helper script rather than calling `ryzenadj`
directly — in that case a wrapper script in a location Steam checks may be needed.

**Unknown**: Whether adding the sudoers rule is sufficient for Steam to invoke `ryzenadj`
automatically, or whether Steam also requires a helper script or specific environment to
detect and use it. Whether `ryzenadj` correctly addresses the OLED (Galileo) APU's power
registers via the Neptune kernel has not been confirmed. This entire proposed fix still
requires hardware testing.

---

## Hardware Volume Buttons Show Overlay But Don't Change Volume

The physical volume up/down buttons bring up the volume HUD but the level doesn't change.
The QAM volume slider works fine. This suggests the input event is received but the mixer
call fails.

**Proposed diagnosis**:

1. Confirm `deck` is in the `audio` group:

   ```bash
   groups deck   # should include "audio"
   sudo usermod -aG audio deck
   # Log out and back in for group change to take effect
   ```

2. Confirm `pipewire-pulse` is actually running when in Game Mode (Steam depends on it for
   volume key handling):

   ```bash
   pgrep -a pipewire-pulse
   ```

   If it's not running, check that `pipewire-pulse.desktop` exists in `~/.config/autostart/`
   (installed by Phase 5).

3. In Desktop Mode, KDE handles volume keys natively via the PipeWire-PA bridge. If they
   still don't work there, check **System Settings → Audio** and confirm the active output
   device is the Filter Chain Sink, not HDMI.

**Unknown**: Whether this is purely a group/autostart issue or whether there's a deeper
problem with how Steam's volume key handler interacts with PipeWire-pulse on OpenRC.

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
