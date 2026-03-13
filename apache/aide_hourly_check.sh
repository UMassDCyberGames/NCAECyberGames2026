#!/bin/bash
set -euo pipefail

OUT_DIR="/root/blue_checks"
DATE_TAG="$(date +%F_%H-%M-%S)"
OUT_FILE="${OUT_DIR}/aide_check_${DATE_TAG}.txt"

mkdir -p "$OUT_DIR"

echo "==== AIDE Integrity Scan: $DATE_TAG ====" > "$OUT_FILE"

# Capture AIDE output
AIDE_OUTPUT=$(aide --check 2>&1 || true)

# Save output to log file
echo "$AIDE_OUTPUT" >> "$OUT_FILE"

# Detect integrity changes
if echo "$AIDE_OUTPUT" | grep -E "changed|added|removed" >/dev/null; then
    echo "🚨 ALERT: AIDE detected file integrity changes!"
    
    # Send alert to all terminals
    wall "SECURITY ALERT: AIDE detected file integrity changes on $(hostname)"

    # Optional terminal bell
    echo -e "\a\a\a"
fi

echo "[+] AIDE check complete: $OUT_FILE"