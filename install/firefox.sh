#!/usr/bin/env bash
# firefox.sh — Apply arkenfox user.js + personal overrides to Firefox profile

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDES_SRC="$SCRIPT_DIR/../configs/firefox/user-overrides.js"

# ---------------------------------------------------------------------------
# Locate Firefox and its profile directory
#
# Flatpak Firefox → ~/.var/app/org.mozilla.firefox/.mozilla/firefox/
# System Firefox  → ~/.mozilla/firefox/
# ---------------------------------------------------------------------------
FLATPAK_FIREFOX_DIR="$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
SYSTEM_FIREFOX_DIR="$HOME/.mozilla/firefox"

# Determine which Firefox is installed and where its profile lives
if flatpak list --columns=application 2>/dev/null | grep -q "^org.mozilla.firefox$"; then
  FIREFOX_CMD="flatpak run org.mozilla.firefox"
  FIREFOX_DIR="$FLATPAK_FIREFOX_DIR"
elif command -v firefox &>/dev/null; then
  FIREFOX_CMD="firefox"
  FIREFOX_DIR="$SYSTEM_FIREFOX_DIR"
else
  echo "WARNING: Firefox not found (neither flatpak nor system install)."
  echo "  Install Firefox then re-run: bash install/firefox.sh"
  return 0
fi

# ---------------------------------------------------------------------------
# Launch Firefox headlessly to create the profile if it doesn't exist yet
# ---------------------------------------------------------------------------
find_profile() {
  find "$FIREFOX_DIR" -maxdepth 1 \( -name "*.default-release" -o -name "*.default" \) -type d 2>/dev/null | head -1
}

if [ -z "$(find_profile)" ]; then
  echo "No Firefox profile found — launching headlessly to initialize one..."
  $FIREFOX_CMD --headless --no-remote >/dev/null 2>&1 &
  FIREFOX_PID=$!

  # Poll up to 20 seconds for the profile to appear
  for i in $(seq 1 20); do
    if [ -n "$(find_profile)" ]; then
      break
    fi
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
