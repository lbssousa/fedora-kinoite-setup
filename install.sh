#!/usr/bin/env bash
set -uo pipefail
# Note: -e (exit on error) is intentionally omitted at the top level so that
# a single module failure does not abort the entire install. Each module that
# sources this file runs in the same shell, so we use run_module() below to
# catch and report failures without stopping the run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/ascii.sh"
print_banner

# ---------------------------------------------------------------------------
# Detect OS variant
# ---------------------------------------------------------------------------
detect_variant() {
  if [ -f /run/ostree-booted ]; then
    # Distinguish Kinoite (KDE) from Silverblue (GNOME) and other variants
    if grep -qi "kinoite" /etc/os-release 2>/dev/null; then
      echo "Detected: Fedora Kinoite (ostree-based, KDE Plasma)"
    else
      echo "Detected: Fedora ostree-based system (Silverblue or variant)"
    fi
    SILVERBLUE=true
  elif grep -qi "fedora" /etc/os-release 2>/dev/null; then
    echo "Detected: Fedora (not ostree-based) — some rpm-ostree steps will be skipped or may need adaptation"
    SILVERBLUE=false
  else
    echo "WARNING: This does not appear to be a Fedora system."
    echo "Proceeding anyway, but expect failures."
    SILVERBLUE=false
  fi
  export SILVERBLUE
}

section() {
  echo ""
  echo -e "\033[1;32m===> $1\033[0m"
  echo ""
}

FAILED_MODULES=()

run_module() {
  local label="$1"
  local script="$2"
  section "$label"
  if (set -euo pipefail; source "$script"); then
    echo -e "\033[0;32m  ✓ $label done\033[0m"
  else
    echo -e "\033[1;31m  ✗ $label FAILED — continuing\033[0m"
    FAILED_MODULES+=("$label")
  fi
}

# ---------------------------------------------------------------------------
# Detect hardware
# ---------------------------------------------------------------------------
source "$SCRIPT_DIR/install/detect-hardware.sh"

section "Hardware detection"
detect_variant
echo ""
detect_hardware

if [ "$IS_VM" = true ]; then
  echo ""
  echo "  Running in a VM — hardware-specific driver prompts will be skipped."
fi

# ---------------------------------------------------------------------------
# Tier 1 — Core dev environment
# These run first. By the time they finish you have brew, mise, stow, and
# your dotfiles. If anything in Tier 2 fails you can still work.
# ---------------------------------------------------------------------------

run_module "System basics"   "$SCRIPT_DIR/install/system.sh"
run_module "Homebrew"        "$SCRIPT_DIR/install/brew.sh"

# Brew is required by everything below — abort if it failed to install.
if ! command -v brew &>/dev/null; then
  echo ""
  echo -e "\033[1;31m  FATAL: Homebrew is not available after install.\033[0m"
  echo "  Cannot continue — dev-tools, dotfiles, and CLI tools all require brew."
  echo "  Fix the brew install and re-run this script."
  exit 1
fi

run_module "Developer tools" "$SCRIPT_DIR/install/dev-tools.sh"
run_module "Dotfiles"        "$SCRIPT_DIR/install/dotfiles.sh"

# ---------------------------------------------------------------------------
# Tier 2 — Desktop polish
# Network-dependent and more likely to have transient failures (bad flatpak
# IDs, extensions.gnome.org being slow, no Firefox profile yet). All of
# these are independent — a failure in one doesn't affect the others.
# ---------------------------------------------------------------------------

run_module "Fonts"                "$SCRIPT_DIR/install/fonts.sh"
run_module "KDE Plasma settings"  "$SCRIPT_DIR/install/plasma.sh"
run_module "Flatpaks"             "$SCRIPT_DIR/install/flatpaks.sh"
run_module "Editors"              "$SCRIPT_DIR/install/editors.sh"
run_module "CLI tools"            "$SCRIPT_DIR/install/cli-tools.sh"

# ---------------------------------------------------------------------------
# Tier 3 — rpm-ostree layers (always staged last; single reboot covers all)
# ---------------------------------------------------------------------------

run_module "rpm-ostree packages"         "$SCRIPT_DIR/install/rpm-ostree.sh"
run_module "Firefox codecs"              "$SCRIPT_DIR/install/firefox-codecs.sh"
run_module "Google Drive (kio-gdrive)"   "$SCRIPT_DIR/install/gdrive.sh"
run_module "Epson printer"               "$SCRIPT_DIR/install/epson.sh"
run_module "NVIDIA SecureBoot keys"      "$SCRIPT_DIR/install/nvidia-secureboot.sh"
run_module "NVIDIA drivers"              "$SCRIPT_DIR/install/nvidia.sh"

# ---------------------------------------------------------------------------
# Tier 4 — sudo-required steps (last, so a skipped password doesn't block
# anything above)
# ---------------------------------------------------------------------------

run_module "sudo tweaks"     "$SCRIPT_DIR/install/sudo-tweaks.sh"
run_module "TPM2 LUKS unlock" "$SCRIPT_DIR/install/tpm2-luks.sh"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo -e "\033[1;33m============================================================\033[0m"
echo -e "\033[1;33m  Setup complete!\033[0m"
echo ""
if [ "$SILVERBLUE" = true ]; then
  echo -e "\033[1;31m  REBOOT REQUIRED\033[0m"
  echo "  rpm-ostree changes (NVIDIA drivers, packages) take effect"
  echo "  after rebooting into the new deployment."
fi
if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
  echo -e "\033[1;31m  The following modules had errors:\033[0m"
  for m in "${FAILED_MODULES[@]}"; do
    echo "    - $m"
  done
  echo ""
fi
echo ""
echo "  Manual follow-ups:"
echo "    - Set device name: System Settings → About This System"
echo "    - Set display resolution and scaling: System Settings → Display & Monitor"
echo "    - If NVIDIA SecureBoot keys were enrolled: reboot and select"
echo "      'Enroll MOK' on the blue screen, then re-run to install drivers"
echo -e "\033[1;33m============================================================\033[0m"
echo ""

# Open KDE System Settings to the About page so the user can set their
# device name and review system info before rebooting.
if command -v systemsettings6 &>/dev/null; then
  echo "Opening System Settings → About This System..."
  systemsettings6 about-distro &>/dev/null &
elif command -v systemsettings5 &>/dev/null; then
  echo "Opening System Settings..."
  systemsettings5 &>/dev/null &
fi
