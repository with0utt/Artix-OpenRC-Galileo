# Contributing

Thanks for your interest in improving this guide! Here's how you can help.

## Reporting Issues

Open a GitHub issue with:

- **What you tried** — which phase and step
- **What happened** — error messages, unexpected behavior
- **Your setup** — Steam Deck model, Artix base version, kernel version
- **What you already tried** — check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first

## Submitting Changes

1. Fork the repo and create a branch from `main`
2. Make your changes (see conventions below)
3. Test on hardware if possible — if not, say so in the PR description
4. Open a pull request with a clear summary of what changed and why

### What's easy to contribute

- Documentation improvements (typos, clarity, better explanations)
- New troubleshooting entries
- Proposed fixes in `docs/experimental.md` (clearly marked as untested)

### What needs care

- Script changes — these run as root and affect real systems
- Configuration file changes — subtle breakage is hard to debug
- Anything that changes the phase structure or ordering

## Conventions

### Commits

```text
type(scope): description

# Examples:
docs: clarify kernel build prerequisites in phase 01
scripts: improve error messages in phase 03-core-services
configs: add PipeWire config for spatial audio
```

### Scripts

- Always use `set -euo pipefail`
- Use `[N/M]` step counters for progress
- Use `sudo pacman -S --needed --noconfirm` for packages
- Use OpenRC commands (`rc-update add`), never systemd (`systemctl enable`)
- Keep operations idempotent (safe to run twice)

### Documentation

- Untested fixes go in `docs/experimental.md`, not in the main phase guides
- Update `TROUBLESHOOTING.md` if your change addresses or creates known issues
- Keep one logical change per commit

## Hardware Testing

End-to-end testing requires a Steam Deck OLED. If you can't test on hardware,
that's fine — just be upfront about it in your PR. The community can help
verify.
