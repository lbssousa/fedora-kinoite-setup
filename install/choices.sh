#!/usr/bin/env bash
# choices.sh — Interactive setup choices using gum
#
# Runs after brew (gum is available) and after hardware detection.
# Exports decision variables consumed by later modules.
# All variables default to false — gum prompts set them to true.

export INSTALL_NVIDIA=false
export INSTALL_NVIDIA_CONTAINERS=false
export INSTALL_GHOSTTY=true   # almost always wanted; user can say no

# ---------------------------------------------------------------------------
# Require gum
# ---------------------------------------------------------------------------
if ! command -v gum &>/dev/null; then
  echo "WARNING: gum not found — skipping interactive choices, using defaults."
  echo "  Re-run install/choices.sh manually after brew is set up."
  return 0
fi

echo ""
gum style \
  --border normal --padding "0 1" --border-foreground 212 \
  "Hardware: $(echo "$GPU_SUMMARY" | head -3)" \
  "VM: $IS_VM  |  NVIDIA: $HAS_NVIDIA  |  AMD: $HAS_AMD  |  Intel GPU: $HAS_INTEL_GPU"
echo ""

# ---------------------------------------------------------------------------
# Ghostty terminal
# ---------------------------------------------------------------------------
if gum confirm "Install Ghostty terminal? (COPR repo + rpm-ostree, reboot required)"; then
  INSTALL_GHOSTTY=true
else
  INSTALL_GHOSTTY=false
fi

# ---------------------------------------------------------------------------
# NVIDIA drivers
# ---------------------------------------------------------------------------
if [ "$IS_VM" = true ]; then
  echo "  Running in a VM — skipping NVIDIA driver prompt."
elif [ "$HAS_NVIDIA" = true ]; then
  echo ""
  if [ "$MULTI_GPU" = true ]; then
    gum style --foreground 214 "  Multi-GPU system detected (NVIDIA + other). Proprietary drivers will"
    gum style --foreground 214 "  control the NVIDIA card. Hybrid setups may need extra configuration."
    echo ""
  fi
  if gum confirm "NVIDIA GPU detected. Install proprietary drivers? (rpm-ostree, reboot required)"; then
    INSTALL_NVIDIA=true
    if gum confirm "  Also install NVIDIA container toolkit for GPU access in Podman/Docker?"; then
      INSTALL_NVIDIA_CONTAINERS=true
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "  Choices:"
echo "    Ghostty:           $INSTALL_GHOSTTY"
echo "    NVIDIA drivers:    $INSTALL_NVIDIA"
if [ "$INSTALL_NVIDIA" = true ]; then
echo "    NVIDIA containers: $INSTALL_NVIDIA_CONTAINERS"
fi
echo ""

export INSTALL_NVIDIA INSTALL_NVIDIA_CONTAINERS INSTALL_GHOSTTY
