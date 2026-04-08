#!/usr/bin/env bash
# plasma.sh — KDE Plasma desktop preferences via kwriteconfig6

# ---------------------------------------------------------------------------
# Detect kwriteconfig version
# ---------------------------------------------------------------------------
if command -v kwriteconfig6 &>/dev/null; then
  KWC=kwriteconfig6
elif command -v kwriteconfig5 &>/dev/null; then
  KWC=kwriteconfig5
else
  echo "ERROR: kwriteconfig not found — KDE Plasma settings cannot be applied."
  return 1
fi

echo "Applying KDE Plasma settings..."

# ---------------------------------------------------------------------------
# Look and feel — Breeze Dark
# ---------------------------------------------------------------------------
if command -v plasma-apply-lookandfeel &>/dev/null; then
  plasma-apply-lookandfeel --apply org.kde.breezedark.desktop
  echo "Breeze Dark look-and-feel applied."
fi

# ---------------------------------------------------------------------------
# Touchpad
# ---------------------------------------------------------------------------
$KWC --file touchpadrc --group "Touchpad" --key "TapToClick" "true"
$KWC --file touchpadrc --group "Touchpad" --key "NaturalScroll" "true"
$KWC --file touchpadrc --group "Touchpad" --key "TwoFingerScroll" "true"

# ---------------------------------------------------------------------------
# Mouse
# ---------------------------------------------------------------------------
$KWC --file kcminputrc --group "Mouse" --key "ReverseScrollPolarity" "true"

# ---------------------------------------------------------------------------
# KWin — window manager settings
# ---------------------------------------------------------------------------

# Window decoration buttons: minimize, maximize, close on the right
$KWC --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnLeft" ""
$KWC --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "MIAX"

# Compositor
$KWC --file kwinrc --group "Compositing" --key "Enabled" "true"
$KWC --file kwinrc --group "Compositing" --key "Backend" "OpenGL"

# Variable Refresh Rate (VRR) support
$KWC --file kwinrc --group "WaylandOutput" --key "AllowVRR" "true"

# ---------------------------------------------------------------------------
# Night Color
# ---------------------------------------------------------------------------
$KWC --file kwinrc --group "NightColor" --key "Active" "true"
# Mode 0 = Automatic (use system location)
$KWC --file kwinrc --group "NightColor" --key "Mode" "0"

# ---------------------------------------------------------------------------
# Virtual desktops — 6 desktops in a single row
# ---------------------------------------------------------------------------
$KWC --file kwinrc --group "Desktops" --key "Number" "6"
$KWC --file kwinrc --group "Desktops" --key "Rows" "1"

# ---------------------------------------------------------------------------
# Keyboard shortcuts
# ---------------------------------------------------------------------------

# Switch to virtual desktop N — Meta+1 through Meta+6
# (KDE Plasma default is Ctrl+F1–F12; remap to Meta+N to match GNOME convention)
for i in 1 2 3 4 5 6; do
  $KWC --file kglobalshortcutsrc --group "kwin" \
    --key "Switch to Desktop $i" "Meta+$i,Ctrl+F$i,Switch to Desktop $i"
  $KWC --file kglobalshortcutsrc --group "kwin" \
    --key "Window to Desktop $i" "Meta+Shift+$i,none,Window to Desktop $i"
done

# Ctrl+Alt+T → Ghostty terminal
# Requires ghostty.desktop to be registered in the application database.
# KDE Plasma picks this up from kglobalshortcutsrc after the next login.
$KWC --file kglobalshortcutsrc --group "com.mitchellh.ghostty.desktop" \
  --key "_launch" "Ctrl+Alt+T,none,Launch Ghostty"

# ---------------------------------------------------------------------------
# Monospace font — Meslo LGM DZ Nerd Font (installed by fonts.sh)
# ---------------------------------------------------------------------------
# Qt font descriptor format: Family,pointSize,pixelSize,styleHint,weight,style,underline,strikeout,fixedPitch,rawMode
# 11=11pt, -1=default pixelSize, 5=styleHint(Any), 50=weight(Normal), remaining fields=style flags
$KWC --file kdeglobals --group "General" --key "fixed" "MesloLGMDZ Nerd Font,11,-1,5,50,0,0,0,0,0"

# ---------------------------------------------------------------------------
# Apply changes — restart KWin compositor to pick up kwinrc changes
# (only safe if a display session is active; skip silently otherwise)
# ---------------------------------------------------------------------------
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
  if command -v qdbus6 &>/dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
  elif command -v qdbus &>/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
  fi
fi

echo "KDE Plasma settings applied."
echo "  NOTE: Some changes (shortcuts, look-and-feel) take full effect after re-login."
