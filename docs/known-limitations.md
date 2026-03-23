# Known Limitations (Without systemd)

These are inherent limitations of running Artix/OpenRC instead of SteamOS:

- **Steam Input remapping** (gyro, capacitive touchpads via Steam) may have limited
  functionality due to systemd-specific D-Bus interfaces that elogind doesn't fully replicate.
- **SteamOS updates are not available** — this is a manual package management system.
- **Decky Loader plugins** may not work or may be limited, as many assume systemd/SteamOS.
- **TDP slider** in Game Mode is visible but may not function without additional setup
  (`ryzenadj` from AUR).
- **No factory speaker calibration** — the `dsmparam.bin` file is missing, so SMART_AMP
  hardware protection is disabled. The LV2 filter chain provides software-level protection
  instead.
- **Half-rate shading** is not available in upstream Gamescope (Valve-custom feature).
- **Upstream Gamescope** does not have full QAM brightness support like Valve's fork. The
  `brightnessctl` workaround may not persist across all scenarios.
