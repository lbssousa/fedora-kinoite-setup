#!/usr/bin/env bash
# detect-hardware.sh — Detect GPU and virtualization environment
#
# Sets the following exported variables (all booleans: true/false):
#   IS_VM            — running inside a virtual machine
#   HAS_NVIDIA       — NVIDIA GPU present
#   HAS_AMD          — AMD GPU present
#   HAS_INTEL_GPU    — Intel integrated/discrete GPU present
#   MULTI_GPU        — more than one GPU detected
#   GPU_SUMMARY      — human-readable string of detected GPUs

detect_hardware() {
  IS_VM=false
  HAS_NVIDIA=false
  HAS_AMD=false
  HAS_INTEL_GPU=false
  MULTI_GPU=false
  GPU_SUMMARY=""

  # ---------------------------------------------------------------------------
  # VM detection
  # ---------------------------------------------------------------------------
  if command -v systemd-detect-virt &>/dev/null; then
    VIRT=$(systemd-detect-virt 2>/dev/null || true)
    if [ "$VIRT" != "none" ] && [ -n "$VIRT" ]; then
      IS_VM=true
      echo "  Virtualization detected: $VIRT"
    fi
  elif [ -f /proc/cpuinfo ] && grep -qi "hypervisor" /proc/cpuinfo; then
    IS_VM=true
    echo "  Virtualization detected (hypervisor flag in /proc/cpuinfo)"
  fi

  # ---------------------------------------------------------------------------
  # GPU detection via lspci
  # ---------------------------------------------------------------------------
  if ! command -v lspci &>/dev/null; then
    echo "  WARNING: lspci not found — skipping GPU detection (install pciutils)"
    export IS_VM HAS_NVIDIA HAS_AMD HAS_INTEL_GPU MULTI_GPU GPU_SUMMARY
    return
  fi

  GPU_COUNT=0
  GPUS=()

  while IFS= read -r line; do
    GPUS+=("$line")
    GPU_COUNT=$((GPU_COUNT + 1))

    lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    if echo "$lower" | grep -q "nvidia"; then
      HAS_NVIDIA=true
    fi
    if echo "$lower" | grep -qE "amd|radeon|advanced micro"; then
      HAS_AMD=true
    fi
    if echo "$lower" | grep -qE "intel.*graphics|intel.*uhd|intel.*iris|intel.*arc"; then
      HAS_INTEL_GPU=true
    fi
  done < <(lspci 2>/dev/null | grep -iE "VGA|3D controller|Display controller")

  if [ "$GPU_COUNT" -gt 1 ]; then
    MULTI_GPU=true
  fi

  GPU_SUMMARY=$(printf '%s\n' "${GPUS[@]}")

  export IS_VM HAS_NVIDIA HAS_AMD HAS_INTEL_GPU MULTI_GPU GPU_SUMMARY

  # ---------------------------------------------------------------------------
  # Report
  # ---------------------------------------------------------------------------
  echo "  GPU(s) detected: $GPU_COUNT"
  for g in "${GPUS[@]}"; do
    echo "    $g"
  done

  if [ "$IS_VM" = true ]; then
    echo "  Running in a VM — NVIDIA passthrough possible but not assumed."
  fi

  if [ "$HAS_NVIDIA" = true ] && [ "$HAS_AMD" = true ]; then
    echo "  Multi-vendor GPU setup detected (NVIDIA + AMD)."
  elif [ "$HAS_NVIDIA" = true ] && [ "$HAS_INTEL_GPU" = true ]; then
    echo "  Hybrid GPU setup detected (NVIDIA + Intel)."
  fi
}
