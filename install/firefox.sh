#!/usr/bin/env bash
# firefox.sh — Apply arkenfox user.js + personal overrides to Firefox profile

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDES_SRC="$SCRIPT_DIR/../configs/firefox/user-overrides.js"

# ---------------------------------------------------------------------------
# Locate Firefox and its profile directory
#
# Flatpak Firefox  → ~/.var/app/org.mozilla.firefox/.mozilla/firefox/
# System Firefox   → ~/.mozilla/firefox/  (upstream default)
#                  → ~/.config/mozilla/firefox/  (Fedora patched)
# ---------------------------------------------------------------------------
FLATPAK_FIREFOX_DIR="$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"

# Determine which Firefox is installed and where its profile lives
if flatpak list --columns=application 2>/dev/null | grep -q "^org.mozilla.firefox$"; then
  FIREFOX_CMD="flatpak run org.mozilla.firefox"
  FIREFOX_DIR="$FLATPAK_FIREFOX_DIR"
elif command -v firefox &>/dev/null; then
  FIREFOX_CMD="firefox"
  # Fedora patches Firefox to use ~/.config/mozilla/firefox/
  if [ -d "$HOME/.config/mozilla/firefox" ]; then
    FIREFOX_DIR="$HOME/.config/mozilla/firefox"
  else
    FIREFOX_DIR="$HOME/.mozilla/firefox"
  fi
else
  echo "WARNING: Firefox not found (neither flatpak nor system install)."
  echo "  Install Firefox then re-run: bash install/firefox.sh"
  return 0
fi

# ---------------------------------------------------------------------------
# Create Firefox profile if it doesn't exist yet
#
# Firefox needs a real graphical launch to reliably create a profile.
# --headless doesn't work (especially Flatpak Firefox). We check for a
# display session and launch Firefox visually if possible, otherwise bail
# with instructions for the user to run this script later.
# ---------------------------------------------------------------------------
find_profile() {
  find "$FIREFOX_DIR" -maxdepth 1 \( -name "*.default-release" -o -name "*.default" \) -type d 2>/dev/null | head -1
}

has_display() {
  # Check for a graphical session via multiple methods
  if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    return 0
  fi
  # systemd/logind session type check
  if command -v loginctl &>/dev/null; then
    local session_type
    session_type="$(loginctl show-session "$(loginctl --no-legend | awk '/\b'"$USER"'\b/{print $1; exit}')" -p Type --value 2>/dev/null || true)"
    [ "$session_type" = "wayland" ] || [ "$session_type" = "x11" ] && return 0
  fi
  return 1
}

if [ -z "$(find_profile)" ]; then
  if ! has_display; then
    echo "WARNING: No graphical session detected — cannot create Firefox profile."
    echo "  Open Firefox manually, close it, then re-run: bash install/firefox.sh"
    return 0
  fi

  echo "No Firefox profile found — launching Firefox to create one..."
  $FIREFOX_CMD --no-remote >/dev/null 2>&1 &
  FIREFOX_PID=$!

  # Poll up to 20 seconds for the profile to appear
  for i in $(seq 1 20); do
    [ -n "$(find_profile)" ] && break
    sleep 1
  done

  kill "$FIREFOX_PID" 2>/dev/null
  wait "$FIREFOX_PID" 2>/dev/null || true
fi

PROFILE_DIR=$(find_profile)
if [ -z "$PROFILE_DIR" ]; then
  echo "WARNING: Firefox profile still not found after launch attempt."
  echo "  Try opening Firefox manually, then re-run: bash install/firefox.sh"
  return 1
fi

echo "Firefox profile: $PROFILE_DIR"

# ---------------------------------------------------------------------------
# Download arkenfox user.js
# ---------------------------------------------------------------------------
echo "Downloading arkenfox user.js..."
curl -sL \
  "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" \
  -o "$PROFILE_DIR/user.js"
echo "arkenfox user.js installed."

# ---------------------------------------------------------------------------
# Apply personal overrides
# ---------------------------------------------------------------------------
if [ -f "$OVERRIDES_SRC" ]; then
  cp "$OVERRIDES_SRC" "$PROFILE_DIR/user-overrides.js"
  echo "" >> "$PROFILE_DIR/user.js"
  echo "// === user-overrides.js ===" >> "$PROFILE_DIR/user.js"
  cat "$OVERRIDES_SRC" >> "$PROFILE_DIR/user.js"
  echo "Personal overrides applied."
else
  echo "WARNING: user-overrides.js not found at $OVERRIDES_SRC"
fi

# ---------------------------------------------------------------------------
# Manual steps — Firefox extension install
# ---------------------------------------------------------------------------
echo ""
echo "------------------------------------------------------------------------"
echo "  MANUAL STEPS: Firefox extensions"
echo "  Install these from addons.mozilla.org after first launch:"
echo ""
echo "    1. uBlock Origin          https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/"
echo "    2. 1Password              https://addons.mozilla.org/en-US/firefox/addon/1password-x-password-manager/"
echo "    3. Multi-Account Containers  https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/"
echo "    4. Facebook Container     https://addons.mozilla.org/en-US/firefox/addon/facebook-container/"
echo "    5. Privacy Badger         https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/"
echo "------------------------------------------------------------------------"
