#!/bin/bash
# =============================================================================
# Gamescope Session Script — Boots directly into Game Mode
# Install to: /usr/share/gamescope-custom/gamescope-session.sh
# =============================================================================

# Ensure we're not inheriting a display session
unset DISPLAY
unset WAYLAND_DISPLAY

# Ensure PipeWire is running
pipewire &
sleep 1
wireplumber &
sleep 1
pipewire-pulse &
sleep 2

export STEAM_MULTIPLE_XWAYLANDS=1
export XDG_CURRENT_DESKTOP=gamescope

# Start xdg-desktop-portal — required by pressure-vessel (Proton's container
# runtime).  Without a running portal, games launched via Proton may hang
# indefinitely on "Starting launch..." while waiting for a D-Bus response.
/usr/libexec/xdg-desktop-portal &
sleep 1

gamescope -e \
    --xwayland-count 2 \
    -w 1280 -h 800 \
    -W 1280 -H 800 \
    -r 90 \
    --force-orientation right \
    --max-scale 2 \
    --adaptive-sync \
    --mangoapp \
    --hdr-enabled \
    --hdr-itm-enable \
    -- steam -gamepadui -steamos3 -steampal -steamdeck
