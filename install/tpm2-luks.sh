#!/usr/bin/env bash
# tpm2-luks.sh — Automate LUKS disk decryption via TPM2 chip
#
# Uses systemd-cryptenroll (built into modern Fedora) to bind a LUKS2
# passphrase slot to the system's TPM2 chip. On subsequent boots the
# disk is unlocked automatically as long as the measured PCR values
# match — i.e. firmware, SecureBoot state, and boot loader have not
# changed. If they have changed (firmware update, etc.) you will be
# prompted for your regular passphrase.
#
# PCR banks used:
#   PCR 0 — UEFI firmware code
#   PCR 2 — Extended / pluggable firmware code
#   PCR 7 — SecureBoot state (strongly recommended when SecureBoot is on)
#
# Requirements:
#   - TPM2 chip present and enabled in UEFI firmware
#   - LUKS2-encrypted root partition (LUKS1 is not supported)
#   - Your current LUKS passphrase (prompted by systemd-cryptenroll)
#
# To REMOVE TPM2 auto-unlock later:
#   sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/<device>

# ---------------------------------------------------------------------------
# TPM2 device check
# ---------------------------------------------------------------------------
TPM2_FOUND=false
for tpm_path in /dev/tpm0 /dev/tpmrm0; do
  if [ -e "$tpm_path" ]; then
    TPM2_FOUND=true
    echo "TPM2 device found: $tpm_path"
    break
  fi
done

if [ "$TPM2_FOUND" != "true" ]; then
  echo "No TPM2 device found — skipping TPM2-LUKS setup."
  echo "  Enable TPM2 in UEFI firmware and re-run: bash install/tpm2-luks.sh"
  return 0
fi

# ---------------------------------------------------------------------------
# Ensure sudo credentials are cached before issuing multiple privileged calls
# ---------------------------------------------------------------------------
sudo -v || { echo "ERROR: sudo access required."; return 1; }

# ---------------------------------------------------------------------------
# Find the LUKS-encrypted device
# ---------------------------------------------------------------------------
find_luks_device() {
  # 1. Check /etc/crypttab (most reliable post-install source)
  if sudo test -f /etc/crypttab; then
    local ct_dev
    ct_dev=$(sudo awk '!/^#/ && NF>=2 {print $2; exit}' /etc/crypttab)
    if [ -n "$ct_dev" ]; then
      # Resolve UUID= references before passing to cryptsetup
      if echo "$ct_dev" | grep -q "^UUID="; then
        local uuid="${ct_dev#UUID=}"
        ct_dev=$(sudo blkid --uuid "$uuid" 2>/dev/null)
      fi
      if [ -n "$ct_dev" ] && sudo cryptsetup isLuks "$ct_dev" 2>/dev/null; then
        echo "$ct_dev"
        return
      fi
    fi
  fi

  # 2. Scan all block partitions
  while IFS= read -r dev; do
    if sudo cryptsetup isLuks "$dev" 2>/dev/null; then
      echo "$dev"
      return
    fi
  done < <(lsblk -rno NAME,TYPE 2>/dev/null | awk '$2=="part"{print "/dev/"$1}')
}

LUKS_DEVICE=$(find_luks_device)

if [ -z "$LUKS_DEVICE" ]; then
  echo "ERROR: No LUKS-encrypted device found."
  echo "  Check your disk layout with: lsblk -o NAME,TYPE,FSTYPE"
  echo "  If your system is not LUKS-encrypted, this script is not needed."
  return 1
fi

echo "LUKS device: $LUKS_DEVICE"

# ---------------------------------------------------------------------------
# Verify LUKS version is 2 (systemd-cryptenroll requires LUKS2)
# ---------------------------------------------------------------------------
LUKS_VERSION=$(sudo cryptsetup luksDump "$LUKS_DEVICE" 2>/dev/null | awk '/^Version:/{print $2}')
if [ "$LUKS_VERSION" != "2" ]; then
  echo "ERROR: $LUKS_DEVICE uses LUKS version $LUKS_VERSION."
  echo "  systemd-cryptenroll requires LUKS2."
  echo "  Convert with: sudo cryptsetup convert --type luks2 $LUKS_DEVICE"
  echo "  WARNING: Back up your data before converting."
  return 1
fi

# ---------------------------------------------------------------------------
# Check whether a TPM2 token is already enrolled
# ---------------------------------------------------------------------------
if sudo systemd-cryptenroll "$LUKS_DEVICE" 2>/dev/null | grep -q "tpm2"; then
  echo "TPM2 token is already enrolled in $LUKS_DEVICE."
  echo "  To re-enroll: sudo systemd-cryptenroll --wipe-slot=tpm2 $LUKS_DEVICE"
  echo "  Then re-run this script."
  return 0
fi

# ---------------------------------------------------------------------------
# Enroll TPM2 token
# ---------------------------------------------------------------------------
echo ""
echo "Enrolling TPM2 token into $LUKS_DEVICE..."
echo "  PCR banks: 0+2+7 (UEFI firmware + pluggable firmware + SecureBoot state)"
echo "  You will be prompted for your current LUKS passphrase."
echo ""

sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=0+2+7 \
  "$LUKS_DEVICE"

if [ $? -ne 0 ]; then
  echo "ERROR: TPM2 enrollment failed."
  echo "  Check that your passphrase is correct and that the TPM2 chip is operational."
  return 1
fi

# ---------------------------------------------------------------------------
# Ensure the initramfs includes the tpm2-tss module
# On Fedora Kinoite (ostree), rpm-ostree initramfs --enable rebuilds the
# initrd so it carries the TPM2 support needed for early boot unlock.
# ---------------------------------------------------------------------------
DRACUT_CONF="/etc/dracut.conf.d/99-tpm2-luks.conf"
if [ ! -f "$DRACUT_CONF" ]; then
  echo ""
  echo "Writing dracut config for TPM2 early-boot unlock..."
  sudo mkdir -p /etc/dracut.conf.d
  printf 'add_dracutmodules+=" tpm2-tss "\n' | sudo tee "$DRACUT_CONF" > /dev/null
fi

echo "Enabling rpm-ostree initramfs rebuild with TPM2 support..."
# The dracut.conf.d file written above is the primary mechanism; also flag
# rpm-ostree to regenerate the initramfs so the module is included.
sudo rpm-ostree initramfs --enable 2>/dev/null && \
  echo "  Initramfs rebuild staged (takes effect after reboot)." || \
  echo "  NOTE: Could not stage initramfs rebuild; it may already be enabled."

echo ""
echo "TPM2 LUKS auto-unlock configured successfully."
echo ""
echo "  IMPORTANT:"
echo "    - Keep your LUKS passphrase safe — it is your recovery key."
echo "    - Reboot to verify auto-unlock works."
echo "    - If auto-unlock fails after a firmware/SecureBoot update, enter"
echo "      your passphrase manually and re-run this script to re-enroll."
echo "    - To remove TPM2 auto-unlock:"
echo "        sudo systemd-cryptenroll --wipe-slot=tpm2 $LUKS_DEVICE"
