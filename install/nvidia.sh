#!/usr/bin/env bash
# nvidia.sh — NVIDIA drivers, CUDA, and container toolkit via rpm-ostree
#
# Runs automatically when NVIDIA hardware is detected and not in a VM.
# All changes require a reboot to take effect.

# ---------------------------------------------------------------------------
# Hardware check — self-skip if not applicable
# ---------------------------------------------------------------------------
if [ -z "${HAS_NVIDIA:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/detect-hardware.sh"
  detect_hardware
fi

if [ "${IS_VM:-false}" = true ]; then
  echo "Running in a VM — NVIDIA driver install skipped."
  return 0
fi

if [ "${HAS_NVIDIA:-false}" != "true" ]; then
  echo "No NVIDIA GPU detected — skipping."
  return 0
fi

if [ "${HAS_AMD:-false}" = true ] || [ "${HAS_INTEL_GPU:-false}" = true ]; then
  echo "Hybrid/multi-GPU system detected:"
  echo "$GPU_SUMMARY" | sed 's/^/  /'
  echo "Proceeding with NVIDIA driver install."
fi

if [ "${SILVERBLUE:-false}" != "true" ]; then
  echo "WARNING: Not running on Silverblue — rpm-ostree commands may not work."
  echo "  On plain Fedora, use: sudo dnf install akmod-nvidia"
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
sudo update-ca-trust
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
  | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

echo "Installing NVIDIA container toolkit..."
sudo rpm-ostree install nvidia-container-toolkit

echo ""
echo "NVIDIA setup staged. Reboot to apply."
echo "  After reboot: nvidia-smi  |  nvidia-ctk"
