#!/usr/bin/env bash
# gdrive.sh — Install kio-gdrive and add a Dolphin sidebar bookmark for Google Drive
#
# Prerequisites: after rebooting into the new rpm-ostree deployment, open
# System Settings → Online Accounts, add your Google account, and Google
# Drive will appear under the bookmark added here.

# ---------------------------------------------------------------------------
# Install kio-gdrive via rpm-ostree
# kio-gdrive pulls in kaccounts-integration and kaccounts-providers as deps,
# which are required for the KDE Online Accounts Google provider.
# ---------------------------------------------------------------------------
if rpm -q kio-gdrive &>/dev/null; then
  echo "kio-gdrive already installed."
else
  echo "Staging kio-gdrive via rpm-ostree (requires reboot to take effect)..."
  sudo rpm-ostree install --allow-inactive kio-gdrive
fi

# ---------------------------------------------------------------------------
# Add a Dolphin sidebar bookmark for gdrive:/
# The user-places.xbel file is created by Dolphin on first launch; we create
# a minimal one here if it does not yet exist.
# ---------------------------------------------------------------------------
PLACES_FILE="${HOME}/.local/share/user-places.xbel"
GDRIVE_HREF="gdrive:/"

if grep -qs "${GDRIVE_HREF}" "${PLACES_FILE}" 2>/dev/null; then
  echo "Google Drive bookmark already present in Dolphin places."
else
  mkdir -p "$(dirname "${PLACES_FILE}")"

  if [ ! -f "${PLACES_FILE}" ]; then
    cat > "${PLACES_FILE}" <<'XBEL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xbel PUBLIC "+//IDN python.org//DTD XML Bookmark Exchange Language 1.0//EN//XML"
          "http://pyxml.sourceforge.net/topics/dtds/xbel-1.0.dtd">
<xbel version="1.0">
</xbel>
XBEL
  fi

  # Generate a stable numeric ID from the current timestamp (KDE format: epoch/0)
  BOOKMARK_ID="$(date +%s)/0"

  python3 - "${PLACES_FILE}" "${BOOKMARK_ID}" <<'PYEOF'
import sys, re

places_file = sys.argv[1]
bookmark_id = sys.argv[2]

entry = f"""  <bookmark href="gdrive:/">
    <title>Google Drive</title>
    <info>
      <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-gdrive"/>
      </metadata>
      <metadata owner="http://www.kde.org">
        <ID>{bookmark_id}</ID>
        <IsHidden>false</IsHidden>
      </metadata>
    </info>
  </bookmark>
"""

with open(places_file, "r", encoding="utf-8") as f:
    content = f.read()

# Insert before the closing </xbel> tag
content = re.sub(r"(</xbel>\s*)$", entry + r"\1", content, flags=re.DOTALL)

with open(places_file, "w", encoding="utf-8") as f:
    f.write(content)
PYEOF

  echo "Google Drive bookmark added to Dolphin places (${PLACES_FILE})."
fi

echo ""
echo "  Next steps after reboot:"
echo "    1. Open System Settings → Online Accounts"
echo "    2. Add your Google account"
echo "    3. Open Dolphin — 'Google Drive' will appear in the sidebar"
