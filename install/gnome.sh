#!/usr/bin/env bash
# gnome.sh — GNOME desktop preferences via gsettings

echo "Applying GNOME settings..."

# Dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Wallpaper — GNOME's "Drool" (dark variant for dark mode)
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/drool-l.svg'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/gnome/drool-d.svg'

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
KB0="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
KB1="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['${KB0}', '${KB1}']"

# Ctrl+Alt+T → Ghostty
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KB0}" \
  name 'Terminal'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KB0}" \
  command 'ghostty'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KB0}" \
  binding '<Control><Alt>t'

# Ctrl+Alt+W → Whis dictation toggle
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KB1}" \
  name 'Whis Dictation'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KB1}" \
  command 'flatpak run ink.whis.Whis --toggle'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KB1}" \
  binding '<Control><Alt>w'

# ---------------------------------------------------------------------------
# Workspace keybindings
# ---------------------------------------------------------------------------
# Super+N — switch to workspace N
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"

# Super+Shift+N — move window to workspace N
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Super><Shift>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Super><Shift>6']"

# Super+Alt+N — switch to pinned app N in the dock
gsettings set org.gnome.shell.keybindings switch-to-application-1 "['<Super><Alt>1']"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "['<Super><Alt>2']"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "['<Super><Alt>3']"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "['<Super><Alt>4']"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "['<Super><Alt>5']"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "['<Super><Alt>6']"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "['<Super><Alt>7']"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "['<Super><Alt>8']"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "['<Super><Alt>9']"

# Super+Ctrl+Shift+N — open new window of pinned app N
gsettings set org.gnome.shell.keybindings open-new-window-application-1 "['<Super><Control><Shift>1']"
gsettings set org.gnome.shell.keybindings open-new-window-application-2 "['<Super><Control><Shift>2']"
gsettings set org.gnome.shell.keybindings open-new-window-application-3 "['<Super><Control><Shift>3']"
gsettings set org.gnome.shell.keybindings open-new-window-application-4 "['<Super><Control><Shift>4']"
gsettings set org.gnome.shell.keybindings open-new-window-application-5 "['<Super><Control><Shift>5']"
gsettings set org.gnome.shell.keybindings open-new-window-application-6 "['<Super><Control><Shift>6']"
gsettings set org.gnome.shell.keybindings open-new-window-application-7 "['<Super><Control><Shift>7']"
gsettings set org.gnome.shell.keybindings open-new-window-application-8 "['<Super><Control><Shift>8']"
gsettings set org.gnome.shell.keybindings open-new-window-application-9 "['<Super><Control><Shift>9']"

# Insert key → screenshot UI (in addition to Print Screen)
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['Print', 'Insert']"

# ---------------------------------------------------------------------------
# Experimental features (VRR, scaling, etc.)
# ---------------------------------------------------------------------------
gsettings set org.gnome.mutter experimental-features \
  "['scale-monitor-framebuffer', 'xwayland-native-scaling', 'variable-refresh-rate', 'kms-modifiers']"

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
