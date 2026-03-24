# Known Limitations (Without systemd)

These are inherent limitations of running Artix/OpenRC instead of SteamOS:

- **Steam Input remapping** (gyro, capacitive touchpads via Steam) may have limited
  functionality due to systemd-specific D-Bus interfaces that elogind doesn't fully replicate.
- **SteamOS updates are not available** — this is a manual package management system.
- **Decky Loader** does not auto-start without systemd. The installer creates a
  `plugin_loader.service` systemd unit which won't run on OpenRC. Plugins that call systemd
  D-Bus APIs will fail regardless of how Decky is launched. Untested workarounds exist —
  see [`docs/experimental.md`](experimental.md).
- **TDP slider** in Game Mode is visible but has no effect. Installing `ryzenadj` from AUR
  alone does not fix it (hardware-confirmed). A sudoers rule is also required, and it is
  still unknown whether that alone is sufficient — see [`docs/experimental.md`](experimental.md).
- **Fan control** is not available. Valve's `jupiter-fan-control` daemon is closed-source
  and SteamOS-specific. The fan runs at BIOS defaults, which is safe but not optimized for
  noise or thermals. An experimental partial workaround exists — see
  [`docs/experimental.md`](experimental.md).
- **Power button** triggers an immediate shutdown instead of suspending. A proposed
  `elogind` config fix exists but has not been tested — see
  [`docs/experimental.md`](experimental.md).
- **Hardware volume buttons** show the on-screen volume overlay but do not adjust the actual
  volume level. The QAM volume slider works correctly. Proposed diagnosis steps (untested)
  in [`docs/experimental.md`](experimental.md).
- **No factory speaker calibration** — the `dsmparam.bin` file is missing, so SMART_AMP
  hardware protection is disabled. The LV2 filter chain provides software-level protection
  instead.
- **Half-rate shading** is not available in upstream Gamescope (Valve-custom feature).
- **Upstream Gamescope** does not have full QAM brightness support like Valve's fork. The
  `brightnessctl` workaround may not persist across all scenarios.
