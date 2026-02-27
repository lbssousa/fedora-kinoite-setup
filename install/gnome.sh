#!/usr/bin/env bash
# gnome.sh — GNOME desktop preferences via gsettings

echo "Applying GNOME settings..."

# Dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Show battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Center new windows
gsettings set org.gnome.mutter center-new-windows true

# Window button layout: minimize, maximize, close on the right
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Natural scroll — touchpad
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true

# Natural scroll — mouse
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true

# ---------------------------------------------------------------------------
# Display resolution — hardware-specific, must be set manually.
# Uncomment and adjust for your monitor if needed:
#
#   gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
#
# For multi-monitor / fractional scaling use the Displays settings panel
# or: gnome-randr (if installed) / mutter experimental-features
# ---------------------------------------------------------------------------

echo "GNOME settings applied."
