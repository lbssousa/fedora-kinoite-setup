#!/usr/bin/env bash
set -euo pipefail

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
# Run modules in order
# ---------------------------------------------------------------------------

section "System basics"
source "$SCRIPT_DIR/install/system.sh"

section "GNOME preferences"
source "$SCRIPT_DIR/install/gnome.sh"

section "Flatpaks"
source "$SCRIPT_DIR/install/flatpaks.sh"

section "Homebrew"
source "$SCRIPT_DIR/install/brew.sh"

section "Developer tools"
source "$SCRIPT_DIR/install/dev-tools.sh"

section "GNOME extensions"
source "$SCRIPT_DIR/install/extensions.sh"

section "Extension preferences"
source "$SCRIPT_DIR/install/extension-prefs.sh"

section "Firefox"
source "$SCRIPT_DIR/install/firefox.sh"

section "Dotfiles"
source "$SCRIPT_DIR/install/dotfiles.sh"

section "CLI tools"
source "$SCRIPT_DIR/install/cli-tools.sh"

# NVIDIA is opt-in — only run if --nvidia flag is passed
if [[ "${1:-}" == "--nvidia" ]]; then
  section "NVIDIA drivers"
  source "$SCRIPT_DIR/install/nvidia.sh"
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
echo ""
echo "  Manual follow-ups:"
echo "    - Set display resolution (hardware-specific)"
echo "    - Configure extension preferences via Extension Manager"
echo "    - Install Firefox extensions manually (see install/firefox.sh)"
echo "    - Verify dconf extension keys (see install/extension-prefs.sh)"
echo -e "\033[1;33m============================================================\033[0m"
echo ""
