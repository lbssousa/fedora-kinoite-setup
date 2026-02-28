#!/usr/bin/env bash
# extension-prefs.sh — Apply dconf settings for installed GNOME extensions

echo "Applying extension preferences..."

# ---------------------------------------------------------------------------
# Just Perfection
# ---------------------------------------------------------------------------
# Animation speed: 0=off, 1=default, 2=almost none (0.01x), 3=fastest, etc.
dconf write /org/gnome/shell/extensions/just-perfection/animation 2

# Keep Activities button visible (Hot Edge provides bottom-screen trigger)
dconf write /org/gnome/shell/extensions/just-perfection/activities-button true

# ---------------------------------------------------------------------------
# Rectangle (tiling)
# ---------------------------------------------------------------------------
dconf write /org/gnome/shell/extensions/rectangle/animate-movement true
dconf write /org/gnome/shell/extensions/rectangle/animation-duration 10
dconf write /org/gnome/shell/extensions/rectangle/margin-bottom 6
dconf write /org/gnome/shell/extensions/rectangle/margin-left 5
dconf write /org/gnome/shell/extensions/rectangle/margin-right 6
dconf write /org/gnome/shell/extensions/rectangle/margin-top 6
dconf write /org/gnome/shell/extensions/rectangle/padding-inner 6
dconf write /org/gnome/shell/extensions/rectangle/padding-outer 6

# ---------------------------------------------------------------------------
# Hot Edge
# ---------------------------------------------------------------------------
dconf write /org/gnome/shell/extensions/hotedge/show-animation false
dconf write /org/gnome/shell/extensions/hotedge/suppress-activation-when-button-held true

echo "Extension preferences applied."
