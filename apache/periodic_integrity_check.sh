#!/bin/bash
set -euo pipefail

OUT_DIR="/root/blue_checks"
DATE_TAG="$(date +%F_%H-%M-%S)"
OUT_FILE="${OUT_DIR}/integrity_check_${DATE_TAG}.txt"

mkdir -p "$OUT_DIR"

alert() {
    MSG="$1"

    echo "🚨 ALERT: $MSG"
    wall "SECURITY ALERT on $(hostname): $MSG"
    echo -e "\a\a\a"
}

echo "==== Integrity Check: $DATE_TAG ====" > "$OUT_FILE"
echo >> "$OUT_FILE"

echo "[1] UFW status" >> "$OUT_FILE"
UFW_OUTPUT=$(ufw status verbose 2>&1 || true)
echo "$UFW_OUTPUT" >> "$OUT_FILE"
echo >> "$OUT_FILE"

echo "[2] debsums check" >> "$OUT_FILE"
DEBSUMS_OUTPUT=$(debsums -s 2>&1 || true)
echo "$DEBSUMS_OUTPUT" >> "$OUT_FILE"
echo >> "$OUT_FILE"

if [ -n "$DEBSUMS_OUTPUT" ]; then
    alert "Package integrity violation detected (debsums)"
fi

echo "[3] Running deleted files" >> "$OUT_FILE"
DELETED_OUTPUT=$(lsof | grep deleted || true)
echo "$DELETED_OUTPUT" >> "$OUT_FILE"
echo >> "$OUT_FILE"

if [ -n "$DELETED_OUTPUT" ]; then
    alert "Running process using deleted executable detected"
fi

echo "[4] Recently modified system binaries" >> "$OUT_FILE"
MODIFIED_OUTPUT=$(find /bin /sbin /usr/bin /usr/sbin -type f -mtime -1 2>/dev/null || true)
echo "$MODIFIED_OUTPUT" >> "$OUT_FILE"
echo >> "$OUT_FILE"

if [ -n "$MODIFIED_OUTPUT" ]; then
    alert "Critical system binaries modified within last 24 hours"
fi

echo "[+] Check complete: $OUT_FILE"