#!/usr/bin/env bash
# nvidia.sh — NVIDIA drivers, CUDA, and container toolkit via rpm-ostree
#
# This script only runs when install.sh is called with --nvidia.
# All changes require a reboot to take effect.

# ---------------------------------------------------------------------------
# Hardware sanity checks
# ---------------------------------------------------------------------------

# If hardware detection ran, use results; otherwise probe now.
if [ -z "${HAS_NVIDIA:-}" ]; then
  SCRIPT_DIR_NV="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR_NV/detect-hardware.sh"
  detect_hardware
fi

if [ "${IS_VM:-false}" = true ]; then
  echo "Running inside a VM — NVIDIA driver install skipped."
  echo "For GPU passthrough, install drivers manually after verifying the vGPU setup."
  exit 0
fi

if [ "${HAS_NVIDIA:-false}" != "true" ]; then
  echo "No NVIDIA GPU detected (lspci found no NVIDIA device)."
  echo "Skipping NVIDIA driver install."
  exit 0
fi

if [ "${HAS_AMD:-false}" = true ] || [ "${HAS_INTEL_GPU:-false}" = true ]; then
  echo "Hybrid/multi-GPU system detected."
  echo "GPU summary:"
  echo "$GPU_SUMMARY" | sed 's/^/  /'
  echo ""
  echo "Proceeding with NVIDIA driver install."
  echo "Note: On hybrid (Optimus) systems, prime-select or kernel params may be"
  echo "needed to control which GPU drives the display."
  echo ""
fi

if [ "${SILVERBLUE:-false}" != "true" ]; then
  echo "WARNING: Not running on Silverblue. rpm-ostree commands may not work."
  echo "  On plain Fedora, use: sudo dnf install akmod-nvidia instead."
fi

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

echo "Enabling RPM Fusion repositories..."
sudo rpm-ostree install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
  || echo "RPM Fusion repos may already be enabled."

echo "Installing NVIDIA drivers and CUDA..."
sudo rpm-ostree install \
  akmod-nvidia \
  xorg-x11-drv-nvidia \
  xorg-x11-drv-nvidia-cuda

echo "Adding NVIDIA container toolkit repository..."
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
  | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

echo "Installing NVIDIA container toolkit..."
sudo rpm-ostree install nvidia-container-toolkit

echo ""
echo "========================================================"
echo "  NVIDIA setup queued. A REBOOT IS REQUIRED."
echo "  After rebooting:"
echo "    nvidia-smi    # verify driver"
echo "    nvidia-ctk    # verify container toolkit"
echo "========================================================"
