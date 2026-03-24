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

**Proposed fix**: Install `ryzenadj` from AUR. Gamescope/Steam is expected to detect it
automatically and use it for APU power limit control.

```bash
paru -S ryzenadj
# or: yay -S ryzenadj
```

**Unknown**: Whether Steam actually invokes `ryzenadj` correctly in this OpenRC setup, or
whether additional configuration (e.g. sudoers rules for `ryzenadj`) is required.

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
