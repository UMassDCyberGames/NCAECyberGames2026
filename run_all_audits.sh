#!/bin/bash
# Master Audit Runner — runs all audit scripts and saves output

OUTDIR="/tmp/audit_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== NCAE CYBER GAMES — FULL AUDIT ==="
echo "Host: $(hostname) | Date: $(date)"
echo "Output saved to: $OUTDIR"
echo ""

run_audit() {
    local script="$1"
    local name="$(basename "$script" .sh)"
    local outfile="$OUTDIR/${name}.txt"

    if [ ! -f "$script" ]; then
        echo "[SKIP] $script not found"
        return
    fi

    echo ">>> Running $name ..."
    bash "$script" 2>&1 | tee "$outfile"
    echo ""
    echo "    Saved to $outfile"
    echo ""
}

run_audit "$SCRIPT_DIR/user_audit.sh"
run_audit "$SCRIPT_DIR/process_audit.sh"
run_audit "$SCRIPT_DIR/network_audit.sh"
run_audit "$SCRIPT_DIR/cron_audit.sh"

echo "=== ALL AUDITS COMPLETE ==="
echo "Full output in: $OUTDIR"
echo ""
ls -lh "$OUTDIR"
