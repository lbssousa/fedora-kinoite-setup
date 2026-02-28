#!/usr/bin/env bash
# sshd.sh — sudo-required system tweaks
#
# Runs last so a skipped or failed password prompt doesn't block anything else.

# ---------------------------------------------------------------------------
# GeoClue — use BeaconDB instead of Mozilla Location Services
# ---------------------------------------------------------------------------
# BeaconDB is an open-source, community-run WiFi/cell location service.
# Same API as MLS, no commercial entity, GDPR jurisdiction.
# https://beacondb.net
GEOCLUE_CONF="/etc/geoclue/conf.d/99-beacondb.conf"
if [ -f "$GEOCLUE_CONF" ]; then
  echo "BeaconDB geoclue config already present."
else
  echo "Configuring GeoClue to use BeaconDB..."
  sudo mkdir -p /etc/geoclue/conf.d
  echo -e "[wifi]\nurl=https://api.beacondb.net/v1/geolocate?key=geoclue" \
    | sudo tee "$GEOCLUE_CONF" > /dev/null
  echo "GeoClue BeaconDB config written."
fi

# ---------------------------------------------------------------------------
# SSH daemon
# ---------------------------------------------------------------------------
if ! command -v systemctl &>/dev/null; then
  echo "WARNING: systemctl not found — skipping sshd setup."
  return 0
fi

echo "Enabling sshd..."
sudo systemctl enable --now sshd && echo "sshd enabled and started." || \
  echo "WARNING: sshd not enabled — run 'sudo systemctl enable --now sshd' manually."
