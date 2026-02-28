#!/usr/bin/env bash
# extension-prefs.sh — Apply dconf settings for installed GNOME extensions

echo "Applying extension preferences..."

# ---------------------------------------------------------------------------
# Just Perfection
# ---------------------------------------------------------------------------
# Animation speed: 0=off, 1=default, 2=almost none (0.01x), 3=fastest, etc.
dconf write /org/gnome/shell/extensions/just-perfection/animation 2

# Hide elements you don't want in the shell
dconf write /org/gnome/shell/extensions/just-perfection/activities-button false
dconf write /org/gnome/shell/extensions/just-perfection/app-menu false
dconf write /org/gnome/shell/extensions/just-perfection/workspace-switcher-size 15

# Vitals and Space Bar use extension defaults.

echo "Extension preferences applied."
