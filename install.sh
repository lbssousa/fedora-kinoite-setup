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
    echo "Detected: Fedora Silverblue (ostree-based)"
    SILVERBLUE=true
  elif grep -qi "fedora" /etc/os-release 2>/dev/null; then
    echo "Detected: Fedora (not Silverblue) — some rpm-ostree steps will be skipped or may need adaptation"
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

# Suggest --nvidia if GPU is detected and flag wasn't passed
if [ "$HAS_NVIDIA" = true ] && [[ "${1:-}" != "--nvidia" ]]; then
  echo ""
  echo -e "\033[1;33m  NOTE: NVIDIA GPU detected. Re-run with --nvidia to install drivers:\033[0m"
  echo "        bash install.sh --nvidia"
fi
if [ "$IS_VM" = true ]; then
  echo ""
  echo "  Running in a VM — skipping NVIDIA driver install automatically."
fi

# ---------------------------------------------------------------------------
# Tier 1 — Core dev environment
# These run first. By the time they finish you have brew, mise, stow, and
# your dotfiles. If anything in Tier 2 fails you can still work.
# ---------------------------------------------------------------------------

run_module "System basics"   "$SCRIPT_DIR/install/system.sh"
run_module "Homebrew"        "$SCRIPT_DIR/install/brew.sh"
run_module "Developer tools" "$SCRIPT_DIR/install/dev-tools.sh"
run_module "Dotfiles"        "$SCRIPT_DIR/install/dotfiles.sh"

# ---------------------------------------------------------------------------
# Tier 2 — Desktop polish
# Network-dependent and more likely to have transient failures (bad flatpak
# IDs, extensions.gnome.org being slow, no Firefox profile yet). All of
# these are independent — a failure in one doesn't affect the others.
# ---------------------------------------------------------------------------

run_module "GNOME preferences"     "$SCRIPT_DIR/install/gnome.sh"
run_module "Flatpaks"              "$SCRIPT_DIR/install/flatpaks.sh"
run_module "GNOME extensions"      "$SCRIPT_DIR/install/extensions.sh"
run_module "Extension preferences" "$SCRIPT_DIR/install/extension-prefs.sh"
run_module "Firefox"               "$SCRIPT_DIR/install/firefox.sh"
run_module "CLI tools"             "$SCRIPT_DIR/install/cli-tools.sh"

# ---------------------------------------------------------------------------
# Tier 3 — Opt-in hardware
# ---------------------------------------------------------------------------

if [[ "${1:-}" == "--nvidia" ]]; then
  run_module "NVIDIA drivers" "$SCRIPT_DIR/install/nvidia.sh"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo -e "\033[1;33m============================================================\033[0m"
echo -e "\033[1;33m  Setup complete!\033[0m"
echo ""
if [ "$SILVERBLUE" = true ]; then
  echo -e "\033[1;31m  REBOOT REQUIRED\033[0m"
  echo "  rpm-ostree changes (GNOME extensions, NVIDIA) take effect"
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
echo "    - Set display resolution (hardware-specific)"
echo "    - Configure extension preferences via Extension Manager"
echo "    - Install Firefox extensions manually (see install/firefox.sh)"
echo "    - Verify dconf extension keys (see install/extension-prefs.sh)"
echo -e "\033[1;33m============================================================\033[0m"
echo ""
