#!/usr/bin/env bash
# firefox.sh — Apply arkenfox user.js + personal overrides to Firefox profile
#
# Extension auto-install via CLI is not supported by Firefox.
# See the manual steps section at the bottom of this file.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDES_SRC="$SCRIPT_DIR/../configs/firefox/user-overrides.js"

# ---------------------------------------------------------------------------
# Find the default Firefox profile directory
# ---------------------------------------------------------------------------
FIREFOX_DIR="$HOME/.mozilla/firefox"

if [ ! -d "$FIREFOX_DIR" ]; then
  echo "WARNING: Firefox profile directory not found at $FIREFOX_DIR"
  echo "  Open Firefox at least once to create a profile, then re-run this script."
  exit 0
fi

# Prefer *.default-release, fall back to any *.default
PROFILE_DIR=$(find "$FIREFOX_DIR" -maxdepth 1 -name "*.default-release" -type d | head -1)
if [ -z "$PROFILE_DIR" ]; then
  PROFILE_DIR=$(find "$FIREFOX_DIR" -maxdepth 1 -name "*.default" -type d | head -1)
fi

if [ -z "$PROFILE_DIR" ]; then
  echo "WARNING: No Firefox profile found. Launch Firefox once to create one."
  exit 0
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
  # Append overrides to user.js (arkenfox convention)
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
echo "  Firefox does not support CLI extension installs for normal profiles."
echo "  Install these extensions manually from addons.mozilla.org:"
echo ""
echo "    1. uBlock Origin"
echo "       https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/"
echo ""
echo "    2. 1Password"
echo "       https://addons.mozilla.org/en-US/firefox/addon/1password-x-password-manager/"
echo ""
echo "    3. Firefox Multi-Account Containers"
echo "       https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/"
echo ""
echo "    4. Facebook Container"
echo "       https://addons.mozilla.org/en-US/firefox/addon/facebook-container/"
echo ""
echo "    5. Privacy Badger"
echo "       https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/"
echo ""
echo "------------------------------------------------------------------------"
