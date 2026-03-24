# CLAUDE.md: Codebase Guide for AI Assistants

This guide explains the structure, conventions, and workflows of the Artix-OpenRC-Galileo project to help AI assistants understand and contribute effectively.

---

## 1. Project Overview

**What is this project?**

Artix-OpenRC-Galileo is a comprehensive installation guide for running **Artix Linux with OpenRC** on a **Steam Deck OLED** (Galileo hardware). Unlike SteamOS (Valve's proprietary system), this guide enables users to install a fully open, lightweight Linux distribution while maintaining full hardware support.

**Why does it exist?**

- SteamOS is closed-source and tightly integrated with Valve's infrastructure
- Some users prefer open alternatives or need customization options
- This guide provides step-by-step instructions to build a working OpenRC system on Steam Deck OLED
- It's derived from real-world testing and debugging on actual hardware

**What works?**

✓ Wi-Fi and networking
✓ GPU acceleration (AMD graphics)
✓ Audio (PipeWire with Valve's DSP plugins)
✓ Game Mode session switching
✓ Bluetooth
✓ Battery management

**What doesn't work?**

See `docs/known-limitations.md` for detailed limitations (e.g., some power management features, certain hardware integrations).

**Who is this for?**

- Technical Linux users with advanced knowledge
- NOT a beginner-friendly project
- Requires understanding of kernel compilation, system services, and Linux architecture

---

## 2. Repository Structure

```text
Artix-OpenRC-Galileo/
├── README.md                 # Quick start and project overview
├── TROUBLESHOOTING.md        # 29 documented issues with solutions
├── CLAUDE.md                 # This file - guide for AI assistants
│
├── docs/                     # Phase-by-phase installation guides
│   ├── 01-kernel-build.md
│   ├── 02-firmware-extraction.md
│   ├── 03-core-services.md
│   ├── 04-graphics-stack.md
│   ├── 05-audio-pipewire.md
│   ├── 06-steam-and-gaming.md
│   ├── 07-gamescope-session.md
│   ├── 08-session-switching.md
│   ├── 09-final-polish.md
│   └── known-limitations.md
│
├── scripts/                  # Automated installation scripts (one per phase)
│   ├── 01-build-kernel.sh
│   ├── 02-extract-firmware.sh
│   ├── 03-setup-services.sh
│   ├── 04-install-graphics.sh
│   ├── 05-setup-audio.sh
│   ├── 06-install-steam.sh
│   ├── 07-setup-sessions.sh
│   ├── 08-setup-brightness.sh
│   ├── steamos-session-helper          # Session management utility
│   └── steamos-session-select          # Session switcher
│
└── configs/                  # Configuration file templates
    ├── 50-audio-routing.conf
    ├── 90-backlight.rules    (udev rule for brightness)
    ├── gamescope-session.desktop
    ├── gamescope-session.sh
    ├── return-to-gamemode.desktop
    ├── sddm.conf.autologin
    ├── steam-session.sudoers
    └── autostart/            (XDG autostart .desktop files)
        ├── pipewire.desktop
        ├── pipewire-pulse.desktop
        └── wireplumber.desktop
```

**Key directories explained:**

- **docs/** - Human-readable phase guides with detailed explanations, troubleshooting steps, and context
- **scripts/** - Automated shell scripts that implement each phase; correspond 1:1 with docs
- **configs/** - Configuration file templates deployed by scripts; never manually edited by users

---

## 3. The 9-Phase Installation Architecture

The installation is organized into **9 sequential phases**, each building on the previous one.

**Why 9 phases?**

1. **Dependency ordering** - Later phases depend on earlier ones (e.g., kernel must exist before graphics)
2. **Troubleshooting isolation** - Each phase can be debugged independently
3. **Parallel documentation** - Team can improve docs and scripts in parallel
4. **User transparency** - Users understand where they are in a 3+ hour process

**Phase overview:**

| Phase | Topic | Duration | Key Output |
|-------|-------|----------|-----------|
| 1 | Build Valve Neptune kernel | ~45 min | Compiled kernel image |
| 2 | Extract OLED firmware | ~15 min | Firmware files for hardware support |
| 3 | Setup OpenRC services | ~10 min | elogind, NetworkManager, SDDM, Bluetooth |
| 4 | Install graphics drivers | ~20 min | Mesa, Vulkan, AMD drivers |
| 5 | Configure PipeWire audio | ~15 min | Audio pipeline with Valve DSP plugins |
| 6 | Install Steam & gaming tools | ~30 min | Steam, Gamescope, MangoHud |
| 7 | Create Game Mode session | ~10 min | Custom SDDM session for gaming |
| 8 | Session switching | ~5 min | Desktop ↔ Game Mode hotkey switching |
| 9 | Final polish | ~10 min | Brightness control, tweaks, optimizations |

**Critical dependency:** Phase 1 must complete successfully before proceeding. All subsequent phases assume you're running the Neptune kernel.

**Correspondence:** Each `docs/NN-*.md` has a matching `scripts/NN-*.sh` that automates its steps.

---

## 4. Code Conventions & Style Guide

### Bash Script Conventions

**Header and error handling (required):**

```bash
#!/bin/bash
set -euo pipefail

# =============================================================================
# Phase N: Description
# =============================================================================
# Additional context about this phase
```

- `set -euo pipefail` enforces strict error handling
  - `-e` = exit on first error
  - `-u` = fail on undefined variables
  - `-o pipefail` = fail if any command in a pipe fails
- See `scripts/01-build-kernel.sh` and `scripts/03-setup-services.sh` for reference

**Progress indication (step counter):**

```bash
echo "[1/8] Installing graphics drivers..."
sudo pacman -S --needed --noconfirm mesa vulkan-radeon
echo "[2/8] Setting up X11 configuration..."
```

✓ **Good:** `echo "[3/8] Installing OpenRC services..."` - Users see progress
✗ **Bad:** `echo "Installing OpenRC services..."` - Users lose sense of progress

**Package installation:**

```bash
sudo pacman -S --needed --noconfirm package1 package2 package3
```

- `--needed` = skip packages already installed
- `--noconfirm` = non-interactive (required for scripts)
- See `scripts/04-install-graphics.sh` for real examples

**Idempotent operations (safe to run multiple times):**

```bash
# ✓ Good - won't fail if group exists
sudo groupadd bluetooth 2>/dev/null || true

# ✗ Bad - fails if group already exists
sudo groupadd bluetooth
```

See `scripts/03-setup-services.sh` for actual usage.

**Service management (OpenRC syntax - NOT systemd):**

```bash
# OpenRC (correct for this project)
sudo rc-update add service default

# ✗ WRONG - systemd, not used here
sudo systemctl enable service
```

Reference: `scripts/03-setup-services.sh`

**Configuration file deployment:**

```bash
# Copy from configs/ directory to system location
sudo cp "$SCRIPT_DIR/configs/sddm.conf.autologin" /etc/sddm.conf.d/kde_settings.conf

# Verify copy was successful
[ -f /etc/sddm.conf.d/kde_settings.conf ] || exit 1
```

See `scripts/07-setup-sessions.sh` for reference.

**Script structure pattern:**

```bash
#!/bin/bash
set -euo pipefail

# Get script directory for config file references
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Phase N: Description ==="

echo "[1/6] First step..."
[commands]

echo "[2/6] Second step..."
[commands]

echo "=== Phase complete! ==="
```

### Configuration File Conventions

- **Location:** Store in `configs/` directory with descriptive names
- **Naming:** Use standard extensions: `.conf`, `.rules`, `.desktop`
- **Comments:** Include purpose and context in header comments
- **Paths:** Always use absolute system paths (e.g., `/etc/sddm.conf.d/`)

### Documentation Conventions

Phase guides should include:

- Overview and purpose
- Prerequisites
- Step-by-step instructions (link to scripts)
- Troubleshooting section
- Links to relevant TROUBLESHOOTING.md entries

### Naming Conventions

- **Scripts:** `NN-descriptive-name.sh` (NN = phase number, 01-08)
- **Docs:** `NN-descriptive-name.md` (matches script number)
- **Configs:** `descriptive-name.conf|.rules|.desktop`
- **Variables:** `UPPER_CASE` for important constants

---

## 5. Key Files & Critical Paths

### ⚠️ Critical/Sensitive Files

**NEVER modify without full understanding:**

| File | Why | Impact if broken |
|------|-----|-----------------|
| `scripts/01-build-kernel.sh` | Kernel compilation is the foundation | Everything fails; system won't boot |
| `scripts/03-setup-services.sh` | OpenRC service initialization | System becomes unusable |
| `scripts/05-setup-audio.sh` | Complex PipeWire configuration | No audio output |
| `scripts/07-setup-sessions.sh` | Game Mode session setup | Session switching breaks |
| All files in `configs/` | Deployed by scripts; subtle dependencies | Features stop working mysteriously |

### Safe-to-Modify Files

**Low risk changes:**

- `docs/` - Improve clarity, fix typos, add examples (no system impact)
- `TROUBLESHOOTING.md` - Add new entries, improve solutions
- `README.md` - Update overview and project information

---

## 6. Development Workflows

### Task: Update Documentation (Low Risk ✓)

1. Find the relevant phase guide in `docs/`
2. Update markdown with clearer instructions or better formatting
3. Verify instructions are accurate (read and re-read)
4. Check links and references
5. Commit: `git commit -m "docs: improve [phase name] documentation"`

Example: `git commit -m "docs: clarify audio configuration in phase 05-audio-pipewire"`

### Task: Add Troubleshooting Entry (Low Risk ✓)

1. Review existing entries in `TROUBLESHOOTING.md` for format
2. Add new entry in appropriate section (or create section)
3. Include: **Problem** (what user sees) → **Root Cause** (why) → **Solution** (steps to fix)
4. Reference the relevant phase guide if applicable
5. Commit: `git commit -m "docs: add troubleshooting for [issue]"`

### Task: Modify Installation Script (High Risk ⚠️)

1. **Read the full phase guide first** - Understand what problem you're solving
2. Make only necessary changes; don't refactor unrelated code
3. Maintain the same step structure and output format
4. **Test thoroughly** if possible on hardware or VM
   - If you can't test, clearly mark as untested in commit message
5. Update corresponding documentation (`docs/NN-*.md`)
6. If relevant, add troubleshooting entry to `TROUBLESHOOTING.md`
7. Commit: `git commit -m "scripts: [specific change in phase XX]"`

Example: `git commit -m "scripts: improve error messages in phase 03-core-services"`

### Task: Add New Configuration File (Medium Risk)

1. Create file in `configs/` with descriptive name
2. Add comments explaining purpose
3. Create or modify the script that deploys this config
4. Document in the relevant phase guide
5. Test end-to-end (run script, verify config deployed and working)
6. Commit: `git commit -m "configs: add [configuration name]"`

### Task: Refactor Script (High Risk ⚠️)

1. Only refactor if you fully understand the phase
2. **Maintain identical functionality** - no feature additions
3. Keep same step structure, output format, and variable names
4. Test thoroughly on hardware if possible
5. Don't bundle refactoring with feature additions
6. Commit: `git commit -m "scripts: refactor [phase XX] for [clarity/efficiency]"`

---

## 7. Dependencies & System Requirements

### Critical Core Dependencies

| Component | Role | Gotcha |
|-----------|------|--------|
| **Valve Neptune kernel** | Hardware support for Steam Deck OLED | Phase 1 must complete first; no exceptions |
| **OpenRC** | Init system (NOT systemd) | Entire project assumes OpenRC; use rc-update, not systemctl |
| **PipeWire** | Audio system | Replaces PulseAudio; complex interdependent config in Phase 5 |
| **Mesa + Vulkan** | GPU graphics acceleration | AMD drivers; won't work on other GPU types |
| **SDDM** | Display manager | Used for session switching (Phase 7) |

### Build-Time Dependencies

Only needed during Phase 1 (kernel build):

- `base-devel`, `bc`, `cpio`, `xmlto`, `python`, `pahole` (kernel build tools)
- `wget` (firmware downloads)
- `sed` (config file patching)

### Important Gotchas

⚠️ **Kernel must be compiled and booted first**

- Phase 1 output is a compiled kernel image
- All subsequent phases assume you're already running the Neptune kernel
- Cannot skip Phase 1

⚠️ **OpenRC, NOT systemd**

- Don't use `systemctl enable service` (wrong!)
- Use `rc-update add service default` (correct)
- System initialization is fundamentally different

⚠️ **Steam Deck OLED specific**

- Guide assumes Galileo hardware
- May fail on other Steam Deck models or completely different devices
- Firmware extraction (Phase 2) is specific to OLED

⚠️ **Hardware-specific assumptions**

- Assumes AMD GPU (Mesa, Vulkan work out of box)
- Assumes specific Wi-Fi and audio chips
- Won't work on systems with different hardware

⚠️ **PipeWire is complex and fragile**

- Phase 5 involves many interdependent components (PipeWire, Wireplumber, plugins, ALSA config)
- One misconfigured file = no audio
- Requires careful attention to order of operations

**Where to learn more:**

- Each phase guide (in `docs/`) explains dependencies as you encounter them
- `TROUBLESHOOTING.md` documents common issues

---

## 8. Common Tasks for Claude

### Research & Documentation Tasks

- Research compatibility of newer kernel versions with Steam Deck OLED
- Investigate which other Steam Deck models this guide might work on
- Research latest PipeWire/Wireplumber releases for improvements
- Document common user questions and add to `TROUBLESHOOTING.md`
- Clarify technical jargon in phase guides
- Add timeline estimates for each phase
- Expand explanations (help users understand WHY, not just follow steps)

### Script Improvement Tasks (if testable)

- Add better error messages that help users diagnose problems
- Improve step counter visibility
- Add pre-flight checks before risky operations
- Optimize package installation order
- Add optional components (e.g., additional audio effects)
- Review bash best practices and suggest improvements

### Documentation Improvement Tasks

- Rewrite unclear sections for clarity
- Add diagrams explaining phase dependencies
- Add visual progress indicators
- Link related phases together
- Verify references and update broken links
- Improve formatting and readability

### What Claude CANNOT Do

- **Test on actual hardware** - Requires Steam Deck OLED
- **Run full installation** - Would need hardware access
- **Verify complex interactions** - Audio, graphics, session switching need end-to-end testing

---

## 9. Testing & Validation

**No automated testing exists.** All validation is manual and documentation-driven.

### For Documentation Changes

- Read the updated guide carefully
- Verify instructions are accurate and complete
- Check links and references work
- Verify formatting is correct (code blocks, emphasis, etc.)

### For Script Changes

Requires access to **Steam Deck OLED hardware or compatible VM**:

1. Run the installation process start-to-finish
2. Verify the modified phase completes without errors
3. Verify subsequent phases still work (dependencies)
4. Check system logs for hidden errors
5. Document any issues found

### For Configuration File Changes

1. Run full installation to completion
2. Verify the feature controlled by the config works as expected
3. Test edge cases (e.g., switching Desktop → Game Mode → Desktop)
4. Check system logs for errors or warnings

### Testing Checklist for Any Change

Before committing, verify:

- [ ] Relevant phase guide still makes sense
- [ ] Cross-references updated if needed
- [ ] `TROUBLESHOOTING.md` updated if new issues might occur
- [ ] Commit message is clear and cites which phase
- [ ] No unrelated changes bundled in commit
- [ ] File has been reviewed for correctness

### If Script Changes Fail

- Don't create new error-handling sections in CLAUDE.md
- **Add to `TROUBLESHOOTING.md` instead:**
  - Problem statement (what user sees)
  - Root cause (why it happens)
  - Solution (steps to fix)
  - Reference the relevant phase guide
- Follow existing format in `TROUBLESHOOTING.md`

---

## 10. Contributing Guidelines

### Before Making Changes

1. Read the full phase guide or script you're modifying
2. Understand WHY it's structured the way it is
3. Consider impact on subsequent phases
4. Check `TROUBLESHOOTING.md` for related issues
5. Look for existing solutions before proposing new approaches

### Making Changes Safely

- Make **one logical change per commit** (don't mix fixes, refactoring, and docs)
- **Don't refactor while adding features** - separate commits
- **Don't change scripts without testing** (if you can't test, disclose this)
- Update documentation to match script changes
- Update `TROUBLESHOOTING.md` if your change creates new potential issues
- Keep changes focused and minimal

### Commit Message Format

Follow this format for clarity:

```text
type(scope): description

Type: docs | scripts | configs
Scope: phase number or area (e.g., "01-kernel", "audio", "sessions")
Description: Clear, specific action taken
```

**Examples:**

- `docs: clarify kernel build prerequisites in phase 01`
- `scripts: improve error messages in phase 03-core-services`
- `configs: add PipeWire config for spatial audio`
- `docs: add troubleshooting for SDDM login issues`

### What NOT to Do

- ❌ Don't change the phase structure without discussion (breaks user expectations)
- ❌ Don't remove steps without replacing them (users depend on exact progression)
- ❌ Don't add optional dependencies without documenting workarounds
- ❌ Don't change OpenRC service names (breaks existing installations)
- ❌ Don't rewrite scripts without understanding the original problem being solved
- ❌ Don't bundle multiple unrelated changes in one commit
- ❌ Don't assume users have hardware other than Steam Deck OLED

### Getting Help

- **Issues tab:** Discuss problems, improvements, or questions
- **Pull requests:** Propose specific changes
- **TROUBLESHOOTING.md:** Document known issues as you discover them
- **Phase guides:** Improve clarity and completeness

---

## Quick Reference

### File Modification Risk Matrix

| File/Directory | Risk | Can be modified safely? |
|----------------|------|----------------------|
| `docs/` | ✓ Low | Yes, improving clarity is encouraged |
| `TROUBLESHOOTING.md` | ✓ Low | Yes, add new entries freely |
| `README.md` | ✓ Low | Yes, update project info |
| `scripts/01-08.sh` | ⚠️ High | Only if you fully understand the phase |
| `configs/` | ⚠️ High | Only if you test end-to-end |
| Script helpers (`steamos-*`) | ⚠️ High | Critical for session switching |

### Common File Paths to Reference

- Phase guides: `docs/NN-descriptive-name.md`
- Installation scripts: `scripts/NN-descriptive-name.sh`
- Configs deployed: `configs/*.conf`, `configs/*.rules`, `configs/*.desktop`
- System paths: `/etc/sddm.conf.d/`, `/etc/pipewire/`, `/etc/openrc/`

### Key Git Branches

- `main` - Stable release documentation and scripts
- Feature branches - For work-in-progress improvements

---

## Questions?

If you're an AI assistant helping with this project and encounter something not covered in this guide:

1. Check the relevant phase guide in `docs/`
2. Search `TROUBLESHOOTING.md` for similar issues
3. Review actual script files for context
4. Ask for clarification from human contributors

This guide is maintained to help you contribute effectively without breaking the installation flow for users.
