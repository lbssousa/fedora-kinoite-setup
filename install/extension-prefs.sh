#!/usr/bin/env bash
# extension-prefs.sh — Apply dconf settings for installed GNOME extensions
#
# NOTE: These keys should be verified/updated by running on a live configured
# system:  dconf dump /org/gnome/shell/extensions/
#
# After manually configuring extensions to your liking, run:
#   dconf dump /org/gnome/shell/extensions/ > extension-settings.dconf
# then replace the individual dconf writes below with:
#   dconf load /org/gnome/shell/extensions/ < extension-settings.dconf

echo "Applying extension preferences..."

# ---------------------------------------------------------------------------
# Just Perfection
# ---------------------------------------------------------------------------
# Speed up / disable animations (0=off, 1=minimal, higher=more)
dconf write /org/gnome/shell/extensions/just-perfection/animation 1

# Hide elements you don't want in the shell
dconf write /org/gnome/shell/extensions/just-perfection/activities-button false
dconf write /org/gnome/shell/extensions/just-perfection/app-menu false
dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position 1
dconf write /org/gnome/shell/extensions/just-perfection/workspace-switcher-size 15

# ---------------------------------------------------------------------------
# Vitals
# ---------------------------------------------------------------------------
# TODO: Fill in preferred sensors after a live install + dconf dump.
# Example stubs (keys may differ by version):
# dconf write /org/gnome/shell/extensions/vitals/show-temperature true
# dconf write /org/gnome/shell/extensions/vitals/show-voltage false
# dconf write /org/gnome/shell/extensions/vitals/show-fan true
# dconf write /org/gnome/shell/extensions/vitals/show-memory true
# dconf write /org/gnome/shell/extensions/vitals/show-processor true
# dconf write /org/gnome/shell/extensions/vitals/show-system false
# dconf write /org/gnome/shell/extensions/vitals/show-network true
# dconf write /org/gnome/shell/extensions/vitals/show-storage false

# ---------------------------------------------------------------------------
# Space Bar
# ---------------------------------------------------------------------------
# TODO: Fill in after live configuration.
# dconf write /org/gnome/shell/extensions/space-bar/behavior/show-empty-workspaces false
# dconf write /org/gnome/shell/extensions/space-bar/appearance/workspace-margin 4

# ---------------------------------------------------------------------------
# Caffeine
# ---------------------------------------------------------------------------
# dconf write /org/gnome/shell/extensions/caffeine/indicator-position 'right'

# ---------------------------------------------------------------------------
# Tiling Assistant (if installed)
# ---------------------------------------------------------------------------
# dconf write /org/gnome/shell/extensions/tiling-assistant/enable-tiling-popup false
# dconf write /org/gnome/shell/extensions/tiling-assistant/single-screen-gap 4
# dconf write /org/gnome/shell/extensions/tiling-assistant/inner-gap 4

echo "Extension preferences applied."
echo "NOTE: Some keys above are stubs — run 'dconf dump /org/gnome/shell/extensions/'"
echo "      after manual setup to capture your actual settings."
