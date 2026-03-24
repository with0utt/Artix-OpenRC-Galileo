# Known Limitations (Without systemd)

These are inherent limitations of running Artix/OpenRC instead of SteamOS:

- **Steam Input remapping** (gyro, capacitive touchpads via Steam) may have limited
  functionality due to systemd-specific D-Bus interfaces that elogind doesn't fully replicate.
- **SteamOS updates are not available** — this is a manual package management system.
- **Decky Loader** does not auto-start without systemd. The installer creates a
  `plugin_loader.service` systemd unit which won't run on OpenRC. Decky can be launched
  manually or wrapped in an OpenRC user service, but plugins that call systemd D-Bus APIs
  will still fail. See TROUBLESHOOTING #34.
- **TDP slider** in Game Mode is visible but has no effect unless `ryzenadj` is installed
  from AUR (`paru -S ryzenadj`). Once installed, no additional configuration is needed —
  Steam detects and uses it automatically. See TROUBLESHOOTING #30.
- **Fan control** is not available. Valve's `jupiter-fan-control` daemon is closed-source
  and SteamOS-specific. The fan runs at BIOS defaults, which is safe but not optimized for
  noise or thermals. `nbfc-linux` (AUR) may work as a partial replacement but no verified
  Steam Deck OLED profile exists. See TROUBLESHOOTING #33.
- **Power button suspend** does not work by default — tapping the power button triggers an
  immediate shutdown instead of sleep. This requires a one-line `elogind` config change.
  Resume reliability is good on the Neptune kernel's s2idle path. See TROUBLESHOOTING #32.
- **Hardware volume buttons** show the on-screen volume overlay but do not adjust the actual
  volume level. The QAM volume slider works correctly. The button issue is related to
  `pipewire-pulse` autostart timing or audio group membership. See TROUBLESHOOTING #31.
- **No factory speaker calibration** — the `dsmparam.bin` file is missing, so SMART_AMP
  hardware protection is disabled. The LV2 filter chain provides software-level protection
  instead.
- **Half-rate shading** is not available in upstream Gamescope (Valve-custom feature).
- **Upstream Gamescope** does not have full QAM brightness support like Valve's fork. The
  `brightnessctl` workaround may not persist across all scenarios.
