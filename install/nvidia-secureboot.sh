#!/usr/bin/env bash
# nvidia-secureboot.sh — Sign NVIDIA akmods kernel modules for SecureBoot
#
# Based on https://github.com/CheariX/silverblue-akmods-keys
#
# On Fedora Kinoite (ostree-based), akmods cannot sign kernel modules during
# the rpm-ostree transaction because the signing keys at /etc/pki/akmods/ are
# not accessible from within that context. This script works around the issue
# by packaging the keys into a local RPM (akmods-keys) that is overlaid via
# rpm-ostree, making them available to akmods at the right time.
#
# Run this BEFORE installing akmod-nvidia (i.e. before nvidia.sh).
# After the script completes, reboot and enroll the MOK key when prompted by
# the blue "MOK Management" screen — enter the password you set below.

# ---------------------------------------------------------------------------
# Hardware / environment checks
# ---------------------------------------------------------------------------
if [ -z "${HAS_NVIDIA:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/detect-hardware.sh"
  detect_hardware
fi

if [ "${IS_VM:-false}" = true ]; then
  echo "Running in a VM — NVIDIA SecureBoot key setup skipped."
  return 0
fi

if [ "${HAS_NVIDIA:-false}" != "true" ]; then
  echo "No NVIDIA GPU detected — skipping SecureBoot key setup."
  return 0
fi

# Check whether SecureBoot is actually enabled; skip silently if not.
if command -v mokutil &>/dev/null; then
  SB_STATE=$(mokutil --sb-state 2>/dev/null || echo "unknown")
  if echo "$SB_STATE" | grep -qi "disabled\|not supported\|EFI variables are not supported"; then
    echo "SecureBoot is disabled or not supported — skipping akmods-keys setup."
    echo "  Enable SecureBoot in UEFI firmware if you need signed kernel modules."
    return 0
  fi
  echo "SecureBoot state: $SB_STATE"
fi

# Skip if akmods-keys is already installed
if rpm -q akmods-keys &>/dev/null; then
  echo "akmods-keys already installed — SecureBoot signing keys are in place."
  return 0
fi

echo "Setting up akmods-keys for SecureBoot NVIDIA signing..."

# ---------------------------------------------------------------------------
# Install required tools (apply-live so they are available immediately)
# ---------------------------------------------------------------------------
echo "Installing rpmdevtools and akmods (apply-live)..."
sudo rpm-ostree install --apply-live rpmdevtools akmods || {
  echo "ERROR: Failed to install rpmdevtools/akmods."
  echo "  Try manually: sudo rpm-ostree install --apply-live rpmdevtools akmods"
  return 1
}

# ---------------------------------------------------------------------------
# Generate Machine Owner Key (MOK) if not already present
# ---------------------------------------------------------------------------
if [ ! -f /etc/pki/akmods/certs/public_key.der ]; then
  echo "Generating Machine Owner Key (MOK)..."
  sudo kmodgenca -a
else
  echo "MOK already exists at /etc/pki/akmods/certs/public_key.der"
fi

# ---------------------------------------------------------------------------
# Import the MOK into the firmware database
# ---------------------------------------------------------------------------
echo ""
echo "Importing MOK into firmware database (mokutil)..."
echo "  You will be prompted to set an enrollment password."
echo "  REMEMBER this password — you will need it on the next reboot to enroll"
echo "  the key in the blue 'MOK Management' screen."
echo ""
sudo mokutil --import /etc/pki/akmods/certs/public_key.der || {
  echo "WARNING: mokutil import failed — key may already be enrolled, or"
  echo "  SecureBoot MOK management is unavailable on this system."
}

# ---------------------------------------------------------------------------
# Build and install the akmods-keys RPM
# (packages the signing keys so akmods can reach them during rpm-ostree)
# ---------------------------------------------------------------------------
TMPDIR_AKKEYS=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf '$TMPDIR_AKKEYS'" EXIT

echo ""
echo "Cloning silverblue-akmods-keys..."
git clone --depth=1 https://github.com/CheariX/silverblue-akmods-keys \
  "$TMPDIR_AKKEYS/silverblue-akmods-keys" || {
  echo "ERROR: Failed to clone silverblue-akmods-keys."
  return 1
}

echo "Building akmods-keys RPM..."
(
  cd "$TMPDIR_AKKEYS/silverblue-akmods-keys"
  sudo bash setup.sh
) || {
  echo "ERROR: akmods-keys build failed."
  return 1
}

FEDORA_VERSION=$(rpm -E %fedora)
BUILD_DIR="$TMPDIR_AKKEYS/silverblue-akmods-keys"

# Find the built RPM — use glob in case the version string changes upstream
RPM_FILE=$(find "$BUILD_DIR" -maxdepth 1 -name "akmods-keys-*.fc${FEDORA_VERSION}.noarch.rpm" 2>/dev/null | head -1)

if [ -z "$RPM_FILE" ]; then
  echo "ERROR: akmods-keys RPM not found in $BUILD_DIR after build."
  return 1
fi

echo "Installing akmods-keys via rpm-ostree..."
sudo rpm-ostree install "$RPM_FILE" || {
  echo "ERROR: rpm-ostree install of akmods-keys failed."
  return 1
}

echo ""
echo "akmods-keys setup complete."
echo ""
echo "  NEXT STEPS:"
echo "    1. Reboot the system."
echo "    2. When the blue 'Perform MOK management' screen appears,"
echo "       select 'Enroll MOK' and enter the password you set above."
echo "    3. After rebooting into the new deployment, run nvidia.sh"
echo "       (or re-run install.sh) to install akmod-nvidia."
echo "    4. The NVIDIA kernel modules will be signed automatically."
