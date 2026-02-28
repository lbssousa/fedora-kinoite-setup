#!/usr/bin/env bash
# dump.sh — Capture all GNOME extension settings from a live machine
#
# Run this on the target Bazzite/Silverblue desktop, then paste the output
# into Claude with the prompt in README.md to fill in extension-prefs.sh.
#
# Usage:
#   bash dump.sh
#   bash dump.sh > my-extension-settings.txt   # save to file (recommended)

set -euo pipefail

SEP="================================================================"
EXTSEP="----------------------------------------------------------------"

# Extensions this setup installs — dump each one individually so Claude can
# map settings back to the right UUID.
UUIDS=(
  "gsconnect@andyholmes.github.io"
  "just-perfection-desktop@just-perfection"
  "caffeine@patapon.info"
  "space-bar@luchrioh"
  "Vitals@CoreCoding.com"
  "rectangle@acristoffers.me"
  "display-brightness-ddcutil@themightydeity.github.com"
  "hotedge@jonathan.jdoda.ca"
)

# dconf path prefixes that map to each UUID (some extensions use a different
# dconf dir name than their UUID slug)
declare -A DCONF_PATHS=(
  ["gsconnect@andyholmes.github.io"]="/org/gnome/shell/extensions/gsconnect/"
  ["just-perfection-desktop@just-perfection"]="/org/gnome/shell/extensions/just-perfection/"
  ["caffeine@patapon.info"]="/org/gnome/shell/extensions/caffeine/"
  ["space-bar@luchrioh"]="/org/gnome/shell/extensions/space-bar/"
  ["Vitals@CoreCoding.com"]="/org/gnome/shell/extensions/vitals/"
  ["rectangle@acristoffers.me"]="/org/gnome/shell/extensions/rectangle/"
  ["display-brightness-ddcutil@themightydeity.github.com"]="/org/gnome/shell/extensions/display-brightness-ddcutil/"
  ["hotedge@jonathan.jdoda.ca"]="/org/gnome/shell/extensions/hotedge/"
)

echo "$SEP"
echo "GNOME EXTENSION SETTINGS DUMP"
echo "Generated: $(date)"
echo "Host:      $(hostname)"
echo "GNOME:     $(gnome-shell --version 2>/dev/null || echo 'unknown')"
echo "$SEP"
echo ""

# ---------------------------------------------------------------------------
# 1. Which extensions are installed and enabled
# ---------------------------------------------------------------------------
echo "## INSTALLED EXTENSIONS"
echo "$EXTSEP"
if command -v gnome-extensions &>/dev/null; then
  gnome-extensions list --details 2>/dev/null || echo "(gnome-extensions list failed)"
else
  echo "(gnome-extensions command not found)"
fi
echo ""

echo "## ENABLED EXTENSIONS"
echo "$EXTSEP"
if command -v gnome-extensions &>/dev/null; then
  gnome-extensions list --enabled 2>/dev/null || echo "(none or error)"
else
  echo "(gnome-extensions command not found)"
fi
echo ""

echo "## DISABLED EXTENSIONS"
echo "$EXTSEP"
if command -v gnome-extensions &>/dev/null; then
  gnome-extensions list --disabled 2>/dev/null || echo "(none or error)"
else
  echo "(gnome-extensions command not found)"
fi
echo ""

# ---------------------------------------------------------------------------
# 2. Full dump of /org/gnome/shell/extensions/ (everything at once)
# ---------------------------------------------------------------------------
echo "## FULL DCONF DUMP — /org/gnome/shell/extensions/"
echo "$EXTSEP"
dconf dump /org/gnome/shell/extensions/ 2>/dev/null || echo "(dconf dump failed)"
echo ""

# ---------------------------------------------------------------------------
# 3. Per-extension dconf dump (easier to read individually)
# ---------------------------------------------------------------------------
echo "## PER-EXTENSION DCONF DUMPS"
echo "$EXTSEP"

for uuid in "${UUIDS[@]}"; do
  path="${DCONF_PATHS[$uuid]:-}"
  echo ""
  echo "### $uuid"
  if [[ -z "$path" ]]; then
    echo "(no known dconf path for this UUID)"
    continue
  fi
  result=$(dconf dump "$path" 2>/dev/null)
  if [[ -z "$result" ]]; then
    echo "(no dconf keys set — using extension defaults)"
  else
    echo "$result"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 4. gsettings output per extension (schema-aware, shows types and ranges)
# ---------------------------------------------------------------------------
echo "## GSETTINGS LIST — per extension"
echo "$EXTSEP"
echo "(Shows key names, current values, and defaults for schema-aware comparison)"
echo ""

for uuid in "${UUIDS[@]}"; do
  echo "### $uuid"

  # Derive the likely schema ID from the dconf path
  # e.g. /org/gnome/shell/extensions/caffeine/ → org.gnome.shell.extensions.caffeine
  path="${DCONF_PATHS[$uuid]:-}"
  if [[ -z "$path" ]]; then
    echo "(no known dconf path)"
    echo ""
    continue
  fi

  # Strip leading/trailing slashes, replace / with .
  schema_id=$(echo "$path" | sed 's|^/||; s|/$||; s|/|.|g')

  # Try gsettings list-recursively; if schema doesn't exist, fall back silently
  output=$(gsettings list-recursively "$schema_id" 2>/dev/null)
  if [[ -z "$output" ]]; then
    echo "(schema '$schema_id' not found or no keys — extension may not be installed)"
  else
    echo "$output"
  fi
  echo ""
done

# ---------------------------------------------------------------------------
# 5. Hot Edge — extra: check if it has any non-standard dconf location
# ---------------------------------------------------------------------------
echo "## HOT EDGE — additional search"
echo "$EXTSEP"
echo "Searching all of /org/gnome/ for 'hotedge' or 'hot-edge'..."
dconf dump /org/gnome/ 2>/dev/null | grep -i -A2 -B2 "hotedge\|hot.edge" || echo "(nothing found)"
echo ""

# ---------------------------------------------------------------------------
# 6. Keyboard shortcuts (custom and extension-set)
# ---------------------------------------------------------------------------
echo "## KEYBOARD SHORTCUTS"
echo "$EXTSEP"
echo "### Custom keybindings"
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ 2>/dev/null || echo "(failed)"
echo ""
echo "### Mutter keybindings"
dconf dump /org/gnome/desktop/wm/keybindings/ 2>/dev/null || echo "(failed)"
echo ""
echo "### Shell keybindings"
dconf dump /org/gnome/shell/keybindings/ 2>/dev/null || echo "(failed)"
echo ""

echo "$SEP"
echo "DUMP COMPLETE"
echo ""
echo "Next step: paste this entire output into Claude with the following prompt"
echo "(see README.md for the full prompt template)."
echo "$SEP"
