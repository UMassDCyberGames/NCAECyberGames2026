#!/bin/bash
# Process Audit — Ubuntu 24.04 / Rocky Linux 9

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'
warn()  { echo -e "${YEL}[WARN]${RST} $*"; }
alert() { echo -e "${RED}[ALERT]${RST} $*"; }
info()  { echo -e "${CYN}[INFO]${RST} $*"; }
ok()    { echo -e "${GRN}[ OK ]${RST} $*"; }
sep()   { echo -e "${BLD}──────────────────────────────────────────${RST}"; }

echo -e "\n${BLD}=== PROCESS AUDIT ===${RST}"
echo "Host: $(hostname)  |  Date: $(date)"
sep

# ── 1. Processes running as root (non-system) ────────────────────────────────
echo -e "\n${BLD}[1] NON-STANDARD ROOT PROCESSES${RST}"
KNOWN_ROOT="systemd|kthread|migration|rcu|watchdog|cpuhp|kworker|kdevtmpfs|netns|oom_reaper|writeback|kcompactd|ksmd|khugepaged|crypto|kintegrityd|kblockd|blkcg|edac|devfreq|requeue|scsi|ata|mpt|ehci|usb|nvme|jbd2|ext4|xfs|btrfs|nfs|rpc|aio|sshd|getty|agetty|login|crond|cron|rsyslog|journald|udevd|dbus|polkit|NetworkManager|firewalld|tuned|auditd|sssd|chronyd|ntpd|nginx|apache|httpd|mysqld|postgres|named|dhclient|wpa_supplicant|avahi|cups"
ps aux | awk '$1 == "root" && $11 !~ /^\[/ {print $0}' | grep -Ev "$KNOWN_ROOT" | grep -v "ps aux" | grep -v "awk" | while read -r line; do
    cmd=$(echo "$line" | awk '{print $11}')
    pid=$(echo "$line" | awk '{print $2}')
    warn "Root process: PID=$pid CMD=$cmd"
done

# ── 2. Processes with deleted binaries (replaced on disk) ────────────────────
sep
echo -e "\n${BLD}[2] PROCESSES WITH DELETED/REPLACED BINARIES${RST}"
found=0
for pid in /proc/[0-9]*/exe; do
    if ls -la "$pid" 2>/dev/null | grep -q "(deleted)"; then
        pinfo=$(ps -p "${pid//[^0-9]/}" -o pid=,comm=,user= 2>/dev/null)
        alert "Deleted binary in use: $pinfo  [$pid]"
        found=1
    fi
done
[ "$found" -eq 0 ] && ok "No processes with deleted binaries"

# ── 3. Processes listening on unexpected ports ───────────────────────────────
sep
echo -e "\n${BLD}[3] ALL LISTENING PROCESSES${RST}"
if command -v ss &>/dev/null; then
    ss -tlnup 2>/dev/null | tail -n +2 | while read -r line; do
        port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
        proc=$(echo "$line" | grep -oP 'users:\(\(".*?"\)' | head -1)
        COMMON_PORTS="22 80 443 3306 5432 53 25 587 993 995 8080 8443 3389 111 2049"
        is_common=0
        for p in $COMMON_PORTS; do [ "$port" = "$p" ] && is_common=1 && break; done
        if [ "$is_common" -eq 0 ]; then
            warn "Uncommon port $port — $proc — $line"
        else
            info "Port $port — $proc"
        fi
    done
else
    netstat -tlnup 2>/dev/null | tail -n +3
fi

# ── 4. High CPU processes (>10%) ─────────────────────────────────────────────
sep
echo -e "\n${BLD}[4] HIGH CPU USAGE (>10%)${RST}"
found=0
ps aux --sort=-%cpu | awk 'NR>1 && $3+0 > 10 {print}' | while read -r line; do
    warn "$line"
    found=1
done
[ "$found" -eq 0 ] && ok "No processes above 10% CPU"

# ── 5. Hidden processes (pid gaps in /proc vs ps) ────────────────────────────
sep
echo -e "\n${BLD}[5] CHECKING FOR HIDDEN PROCESSES${RST}"
proc_pids=$(ls /proc | grep -E '^[0-9]+$' | sort -n)
ps_pids=$(ps -e -o pid= | tr -d ' ' | sort -n)
hidden=$(comm -23 <(echo "$proc_pids") <(echo "$ps_pids"))
if [ -n "$hidden" ]; then
    alert "PIDs in /proc but not in ps (possible rootkit): $hidden"
else
    ok "No hidden processes detected"
fi

# ── 6. Processes running from /tmp or /dev/shm ──────────────────────────────
sep
echo -e "\n${BLD}[6] PROCESSES RUNNING FROM /tmp OR /dev/shm${RST}"
found=0
for pid in /proc/[0-9]*/exe; do
    target=$(readlink "$pid" 2>/dev/null)
    if echo "$target" | grep -qE '^(/tmp|/dev/shm|/var/tmp)'; then
        pinfo=$(ps -p "${pid//[^0-9]/}" -o pid=,comm=,user= 2>/dev/null)
        alert "Suspicious location: $target — $pinfo"
        found=1
    fi
done
[ "$found" -eq 0 ] && ok "No processes running from /tmp or /dev/shm"

sep
echo -e "\n${BLD}Process audit complete.${RST}\n"
