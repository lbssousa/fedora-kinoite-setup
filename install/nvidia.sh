#!/usr/bin/env bash
# nvidia.sh — NVIDIA drivers and CUDA via rpm-ostree
#
# Runs automatically when NVIDIA hardware is detected and not in a VM.
# Detects the appropriate driver series for the installed GPU and installs
# the latest compatible version from RPM Fusion.
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
# Detect the appropriate RPM Fusion driver package for this GPU.
#
# Downloads RPM Fusion's nvidia-detect tool via dnf (without installing it),
# extracts it with rpm2cpio, and runs it against the host lspci output.
# Returns the akmod package name (e.g. akmod-nvidia or akmod-nvidia-470xx).
# Falls back to akmod-nvidia on any error.
# ---------------------------------------------------------------------------
resolve_nvidia_pkg() {
  local fedora_ver tmpdir rpm_file detected
  fedora_ver=$(rpm -E %fedora)
  tmpdir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmpdir'" RETURN

  # Direct baseurl for the RPM Fusion nonfree repo — used as a fallback when
  # the repo is not yet present on the running system.
  local repo_url="https://download1.rpmfusion.org/nonfree/fedora/releases/${fedora_ver}/Everything/x86_64/os/"

  echo "  Downloading nvidia-detect from RPM Fusion..."
  # Prefer the configured repo (available after enable_rpmfusion_repos); fall
  # back to a direct --repofrompath URL on a fresh system.
  if [[ -f /etc/yum.repos.d/rpmfusion-nonfree.repo ]]; then
    dnf download \
        --repo=rpmfusion-nonfree \
        --destdir="${tmpdir}" \
        nvidia-detect &>/dev/null || true
  fi
  # If the download above did not produce an RPM, try via --repofrompath.
  if ! find "${tmpdir}" -maxdepth 1 -type f -name 'nvidia-detect-*.rpm' 2>/dev/null | grep -q .; then
    if ! dnf download \
        --disablerepo='*' \
        --repofrompath="rpmfusion-nonfree-tmp,${repo_url}" \
        --repo=rpmfusion-nonfree-tmp \
        --nogpgcheck \
        --destdir="${tmpdir}" \
        nvidia-detect &>/dev/null; then
      echo "  nvidia-detect download failed — defaulting to akmod-nvidia." >&2
      echo "akmod-nvidia"
      return
    fi
  fi

  rpm_file=$(find "${tmpdir}" -maxdepth 1 -type f -name 'nvidia-detect-*.rpm' 2>/dev/null | head -1)
  if [ -z "$rpm_file" ]; then
    echo "  nvidia-detect RPM not found — defaulting to akmod-nvidia." >&2
    echo "akmod-nvidia"
    return
  fi

  pushd "$tmpdir" > /dev/null || { echo "  Failed to enter tmpdir — defaulting to akmod-nvidia." >&2; echo "akmod-nvidia"; return; }
  rpm2cpio "$rpm_file" | cpio -idm 2>/dev/null
  if [ -x "./usr/bin/nvidia-detect" ]; then
    detected=$(./usr/bin/nvidia-detect 2>/dev/null | grep -o 'akmod-nvidia[[:alnum:]-]*' | tail -1)
  fi
  popd > /dev/null || true

  if [[ "$detected" == akmod-nvidia* ]]; then
    echo "$detected"
  else
    echo "akmod-nvidia"
  fi
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
_FEDORA_VER=$(rpm -E %fedora)
_RPMFUSION_FREE_URL="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${_FEDORA_VER}.noarch.rpm"
_RPMFUSION_NONFREE_URL="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${_FEDORA_VER}.noarch.rpm"

echo "Enabling RPM Fusion repositories..."
sudo rpm-ostree install \
  "$_RPMFUSION_FREE_URL" \
  "$_RPMFUSION_NONFREE_URL" \
  || echo "RPM Fusion repos may already be enabled."

# The layered RPM Fusion packages are only active after a reboot.  Extract
# their .repo files now so that the running system can resolve package names
# for subsequent rpm-ostree and dnf calls in this session.
if ! compgen -G '/etc/yum.repos.d/rpmfusion-*.repo' > /dev/null 2>&1; then
  echo "  Configuring RPM Fusion repos on running system..."
  _rf_tmpdir=$(mktemp -d)
  for _rf_url in "$_RPMFUSION_FREE_URL" "$_RPMFUSION_NONFREE_URL"; do
    if curl -fsSL -o "$_rf_tmpdir/pkg.rpm" "$_rf_url" 2>/dev/null; then
      (cd "$_rf_tmpdir" && rpm2cpio pkg.rpm | cpio -idm 2>/dev/null)
      if ls "$_rf_tmpdir"/etc/yum.repos.d/*.repo &>/dev/null 2>&1; then
        sudo cp "$_rf_tmpdir"/etc/yum.repos.d/*.repo /etc/yum.repos.d/
      fi
    fi
  done
  rm -rf "$_rf_tmpdir"
fi
unset _FEDORA_VER _RPMFUSION_FREE_URL _RPMFUSION_NONFREE_URL _rf_tmpdir _rf_url

echo "Detecting compatible NVIDIA driver package for this GPU..."
NVIDIA_PKG=$(resolve_nvidia_pkg)
echo "  Selected: $NVIDIA_PKG"

# Derive the package suffix used by the xorg and CUDA companion packages
# (e.g. "" for current, "-470xx" for legacy, "-580xx" for latest legacy).
# Strip the "akmod-nvidia" prefix to get the suffix dynamically, so that any
# future legacy branch (e.g. -580xx, -550xx) is handled automatically.
NVIDIA_SUFFIX="${NVIDIA_PKG#akmod-nvidia}"

echo "Installing NVIDIA drivers and CUDA..."
sudo rpm-ostree install \
  "$NVIDIA_PKG" \
  "xorg-x11-drv-nvidia${NVIDIA_SUFFIX}" \
  "xorg-x11-drv-nvidia${NVIDIA_SUFFIX}-cuda"

# ---------------------------------------------------------------------------
# Kernel arguments
# Blacklist nouveau to prevent it from grabbing the GPU before the NVIDIA
# driver does, and enable nvidia-drm modesetting (required for Wayland KMS).
# ---------------------------------------------------------------------------
echo "Setting kernel arguments for NVIDIA..."
KARGS_CURRENT=$(rpm-ostree kargs 2>/dev/null || true)

KARGS_TO_ADD=()
for karg in \
  "rd.driver.blacklist=nouveau" \
  "modprobe.blacklist=nouveau" \
  "nvidia-drm.modeset=1"; do
  # Match the exact argument (space-delimited) to avoid false partial matches
  # (e.g. nvidia-drm.modeset=0 must not satisfy nvidia-drm.modeset=1)
  if echo " $KARGS_CURRENT " | grep -qF " $karg "; then
    echo "  $karg already set — skipping."
  else
    KARGS_TO_ADD+=("--append=$karg")
    echo "  Queued: $karg"
  fi
done

if [ ${#KARGS_TO_ADD[@]} -gt 0 ]; then
  sudo rpm-ostree kargs "${KARGS_TO_ADD[@]}"
fi

echo ""
echo "NVIDIA setup staged. Reboot to apply."
echo "  After reboot: nvidia-smi"
