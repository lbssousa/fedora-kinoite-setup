#!/usr/bin/env bash
# epson.sh — Install Epson printer software and Epson Scan 2
#
# Installs:
#   epson-inkjet-printer-escpr  — Epson ESC/P-R inkjet driver (built from SRPM)
#   epson-printer-utility       — Epson Printer Utility for Linux (binary RPM)
#   net.epson.epsonscan2        — Epson Scan 2 (Flatpak)
#
# The Epson download site uses Akamai CDN/WAF which blocks automated requests.
# Downloads use User-Agent 'Firefox' to bypass the WAF, with a fallback to
# download3.ebz.epson.net (AkamaiNetStorage CDN) which has no bot protection.
#
# The ESCPR driver is shipped as a source RPM and must be compiled. Because
# GCC 14+ (Fedora 41+) promotes -Wimplicit-function-declaration to an error,
# the spec is patched during build. Compilation runs inside a disposable
# Fedora container via podman (pre-installed on Kinoite) so no build
# dependencies are layered permanently onto the host.
#
# The epson-printer-utility binary RPM was built without a SHA-256 payload
# digest header. RPM 4.19+ (Fedora 40+) rejects such packages by default.
# The install temporarily sets %_pkgverify_level none to skip the check.
#
# Reference: lbssousa/bluefin-br build/20-epson-printer.sh (container build
# equivalent), scripts/check-epson-updates.sh (version tracking).

# ── Pinned versions & URLs ────────────────────────────────────────────────
# Primary: download-center.epson.com (latest; requires browser UA)
# Fallback: download3.ebz.epson.net (AkamaiNetStorage CDN; no UA check)

ESCPR_VERSION="1.8.8"
ESCPR_SRPM_URL="https://download-center.epson.com/f/module/e934c1f6-0fc1-43e5-8d3e-0de8f3a3d357/epson-inkjet-printer-escpr-${ESCPR_VERSION}-1.src.rpm"
ESCPR_FALLBACK_URL="https://download3.ebz.epson.net/dsc/f/03/00/16/21/79/6d53e6ec3f8c1e55733eb7860e992a425883bf88/epson-inkjet-printer-escpr-1.8.6-1.src.rpm"

UTILITY_VERSION="1.2.2"
UTILITY_RPM_URL="https://download-center.epson.com/f/module/0fd7dd73-92c2-451e-88cf-cf385e0f6db7/epson-printer-utility-${UTILITY_VERSION}-1.x86_64.rpm"
UTILITY_FALLBACK_URL="https://download3.ebz.epson.net/dsc/f/03/00/15/43/24/e0c56348985648be318592edd35955672826bf2c/epson-printer-utility-1.1.3-1.x86_64.rpm"

# ── Idempotency check ─────────────────────────────────────────────────────
ESCPR_INSTALLED=false
UTILITY_INSTALLED=false

# rpm-ostree lists layered packages; check both rpm db and ostree status
rpm -q epson-inkjet-printer-escpr &>/dev/null && ESCPR_INSTALLED=true
rpm -q epson-printer-utility      &>/dev/null && UTILITY_INSTALLED=true

if [ "$ESCPR_INSTALLED" = true ] && [ "$UTILITY_INSTALLED" = true ]; then
  echo "Epson printer RPMs already installed."
  echo "Installing Epson Scan 2 flatpak..."
  flatpak install --noninteractive flathub net.epson.epsonscan2 2>/dev/null || \
    echo "WARNING: failed to install Epson Scan 2 flatpak — check the app ID."
  return 0
fi

# ── Download helper ───────────────────────────────────────────────────────
# Tries the primary URL (download-center.epson.com) with a browser-like
# User-Agent to bypass Akamai WAF, then falls back to the direct CDN URL
# (download3.ebz.epson.net) which has no anti-bot restrictions.
download_epson() {
  local output="$1" primary_url="$2" fallback_url="$3" desc="$4"
  echo "Downloading ${desc}..."
  if curl -L --fail --retry 3 --retry-delay 5 -A 'Firefox' \
      --output "${output}" "${primary_url}"; then
    return 0
  fi
  echo "WARNING: Primary download failed (Akamai may be blocking this IP)."
  echo "WARNING: Falling back to CDN URL (may be an older version)."
  if curl -L --fail --retry 3 --retry-delay 5 \
      --output "${output}" "${fallback_url}"; then
    return 0
  fi
  echo "ERROR: All download sources failed for ${desc}."
  return 1
}

# ── Temporary build directory ─────────────────────────────────────────────
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$BUILD_DIR"
}

# ── Download SRPM and utility RPM ─────────────────────────────────────────
if [ "$ESCPR_INSTALLED" = false ]; then
  download_epson \
    "${BUILD_DIR}/epson-inkjet-printer-escpr.src.rpm" \
    "${ESCPR_SRPM_URL}" \
    "${ESCPR_FALLBACK_URL}" \
    "epson-inkjet-printer-escpr SRPM" || { cleanup; return 1; }
fi

if [ "$UTILITY_INSTALLED" = false ]; then
  download_epson \
    "${BUILD_DIR}/epson-printer-utility.x86_64.rpm" \
    "${UTILITY_RPM_URL}" \
    "${UTILITY_FALLBACK_URL}" \
    "epson-printer-utility RPM" || { cleanup; return 1; }
fi

# ── Build epson-inkjet-printer-escpr binary RPM ───────────────────────────
# Runs inside a disposable Fedora container (rootless podman, pre-installed
# on Kinoite). The container root maps to the current user in the host
# namespace; files written to /build appear in BUILD_DIR on the host.
#
# Steps inside the container:
#   1. Install build dependencies (autoconf, automake, cups-devel, gcc, etc.)
#   2. Install the SRPM to populate ~/rpmbuild (spec + sources)
#   3. Patch the spec to export CFLAGS that suppress the GCC 14 error, and
#      also override %optflags (used by %configure on Fedora) to the same value
#   4. Run rpmbuild -bb to produce a binary x86_64 RPM
#   5. Copy the resulting RPM to /build so the host can pick it up

if [ "$ESCPR_INSTALLED" = false ]; then
  . /etc/os-release
  echo "Building epson-inkjet-printer-escpr in a Fedora ${VERSION_ID} container..."

  podman run --rm \
    -v "${BUILD_DIR}:/build:z" \
    -e HOME=/root \
    "registry.fedoraproject.org/fedora:${VERSION_ID}" \
    bash -c '
      set -euo pipefail

      mkdir -p /root/.local/state

      dnf install -y \
        autoconf automake cups-devel gcc libtool rpm-build

      mkdir -p /root/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

      # Install SRPM to extract spec + source tarball
      rpm --define "_topdir /root/rpmbuild" -ivh \
        /build/epson-inkjet-printer-escpr.src.rpm

      SPEC=/root/rpmbuild/SPECS/epson-inkjet-printer-escpr.spec

      # Patch 1: export CFLAGS before %configure / ./configure so that
      #          -Wno-implicit-function-declaration is present regardless of
      #          whether the spec uses %configure or a bare ./configure.
      sed -i '"'"'/^%build/a export CFLAGS="${CFLAGS:--O2} -Wno-implicit-function-declaration"'"'"' "$SPEC"

      # Build binary RPM; also override %optflags (used by %configure macro)
      rpmbuild -bb \
        --define "_topdir /root/rpmbuild" \
        --define "optflags -O2 -Wno-implicit-function-declaration" \
        "$SPEC"

      find /root/rpmbuild/RPMS -name "*.rpm" -exec cp {} /build/ \;
    ' || { cleanup; return 1; }

  ESCPR_RPM=$(ls "${BUILD_DIR}"/epson-inkjet-printer-escpr-*.rpm 2>/dev/null \
              | grep -v src | head -1)
  if [ -z "$ESCPR_RPM" ]; then
    echo "ERROR: Build completed but no RPM found in ${BUILD_DIR}."
    cleanup
    return 1
  fi

  echo "Staging epson-inkjet-printer-escpr via rpm-ostree..."
  sudo mkdir -p /root/.local/state
  sudo rpm-ostree install "$ESCPR_RPM"
fi

# ── Install epson-printer-utility binary RPM ─────────────────────────────
# The Epson utility RPM was built without a SHA-256 payload digest header.
# RPM 4.19+ (Fedora 40+) rejects such packages; temporarily set the RPM
# macro %_pkgverify_level to none before the rpm-ostree install, then
# restore the default by removing the override file.
if [ "$UTILITY_INSTALLED" = false ]; then
  MACRO_FILE=/etc/rpm/macros.d/epson-nodigest.macro
  echo '%_pkgverify_level none' | sudo tee "$MACRO_FILE" > /dev/null
  echo "Staging epson-printer-utility via rpm-ostree..."
  sudo rpm-ostree install "${BUILD_DIR}/epson-printer-utility.x86_64.rpm"
  sudo rm -f "$MACRO_FILE"
fi

cleanup

# ── Epson Scan 2 (Flatpak) ────────────────────────────────────────────────
echo "Installing Epson Scan 2 via Flatpak..."
flatpak install --noninteractive flathub net.epson.epsonscan2 || \
  echo "WARNING: failed to install Epson Scan 2 flatpak — check the app ID."

echo "Epson software staged. Reboot to complete RPM installation."
