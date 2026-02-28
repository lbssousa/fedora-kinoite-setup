#!/usr/bin/env bash
# gnome.sh — GNOME desktop preferences via gsettings

echo "Applying GNOME settings..."

# Dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Clock: 12-hour time only, no date
gsettings set org.gnome.desktop.interface clock-format '12h'
gsettings set org.gnome.desktop.interface clock-show-date false
gsettings set org.gnome.desktop.interface clock-show-weekday false

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
# Custom keybindings
# ---------------------------------------------------------------------------
# Ctrl+Alt+T → Ghostty
# GNOME custom keybindings require setting the list and each entry separately.
KBPATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['${KBPATH}']"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KBPATH}" \
  name 'Terminal'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KBPATH}" \
  command 'ghostty'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KBPATH}" \
  binding '<Control><Alt>t'

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
