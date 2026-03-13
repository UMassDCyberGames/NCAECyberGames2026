#!/bin/bash
set -euo pipefail

BASE_DIR="/root/blue_baseline"
DATE_TAG="$(date +%F_%H-%M-%S)"
RUN_DIR="${BASE_DIR}/${DATE_TAG}"
HASH_FILE="${RUN_DIR}/critical_binaries.sha256"
PKG_FILE="${RUN_DIR}/installed_packages.txt"
SERVICE_FILE="${RUN_DIR}/service_status.txt"
UFW_FILE="${RUN_DIR}/ufw_status.txt"
AIDE_LOG="${RUN_DIR}/aide_init.txt"

echo "[+] Creating baseline directory..."
mkdir -p "$RUN_DIR"

echo "[+] Updating package lists..."
apt update

echo "[+] Upgrading packages..."
DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo "[+] Installing integrity tools..."
DEBIAN_FRONTEND=noninteractive apt install -y aide debsums

echo "[+] Recording installed packages..."
dpkg-query -W -f='${Package} ${Version}\n' | sort > "$PKG_FILE"

echo "[+] Recording running services..."
systemctl list-units --type=service --state=running > "$SERVICE_FILE"

echo "[+] Recording firewall status..."
ufw status verbose > "$UFW_FILE" || true

echo "[+] Hashing critical binaries..."
find /bin /sbin /usr/bin /usr/sbin -type f -exec sha256sum {} \; | sort > "$HASH_FILE"

echo "[+] Initializing AIDE baseline..."
aideinit > "$AIDE_LOG" 2>&1

if [ -f /var/lib/aide/aide.db.new ]; then
    cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
elif [ -f /var/lib/aide/aide.db.new.gz ]; then
    cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

echo "[+] Running quick package integrity check..."
debsums -s > "${RUN_DIR}/debsums_silent_check.txt" 2>&1 || true

echo "[+] Baseline complete."
echo
echo "Saved under: $RUN_DIR"
echo
echo "Key files:"
echo "  Packages : $PKG_FILE"
echo "  Services : $SERVICE_FILE"
echo "  Firewall : $UFW_FILE"
echo "  Hashes   : $HASH_FILE"
echo "  AIDE init: $AIDE_LOG"
echo
echo "[+] Periodic monitoring commands:"
echo "  aide --check"
echo "  debsums -s"
echo "  sha256sum -c $HASH_FILE"
echo "  ufw status verbose"