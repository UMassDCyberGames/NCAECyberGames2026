#!/bin/bash
# Cron & Persistence Audit — Ubuntu 24.04 / Rocky Linux 9

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'
warn()  { echo -e "${YEL}[WARN]${RST} $*"; }
alert() { echo -e "${RED}[ALERT]${RST} $*"; }
info()  { echo -e "${CYN}[INFO]${RST} $*"; }
ok()    { echo -e "${GRN}[ OK ]${RST} $*"; }
sep()   { echo -e "${BLD}──────────────────────────────────────────${RST}"; }

# Flags anything that looks like a reverse shell, downloader, or obfuscation
SUSPICIOUS_PATTERN='(bash -i|nc |ncat |netcat|/dev/tcp|/dev/udp|curl.*sh|wget.*sh|python.*socket|perl.*socket|base64.*decode|eval.*base64|mkfifo|socat|xterm.*display|chmod.*\+x.*tmp|/tmp/.*\.sh|/dev/shm)'

check_content() {
    local file="$1"
    local label="$2"
    if grep -qiE "$SUSPICIOUS_PATTERN" "$file" 2>/dev/null; then
        alert "Suspicious content in $label ($file):"
        grep -iE "$SUSPICIOUS_PATTERN" "$file" 2>/dev/null | while read -r line; do
            alert "  >> $line"
        done
    fi
}

echo -e "\n${BLD}=== CRON & PERSISTENCE AUDIT ===${RST}"
echo "Host: $(hostname)  |  Date: $(date)"
sep

# ── 1. System-wide crontab ────────────────────────────────────────────────────
echo -e "\n${BLD}[1] /etc/crontab${RST}"
if [ -f /etc/crontab ]; then
    content=$(grep -Ev '^\s*(#|$)' /etc/crontab)
    if [ -n "$content" ]; then
        warn "Entries in /etc/crontab:"
        echo "$content" | while read -r line; do echo "  $line"; done
        check_content /etc/crontab "/etc/crontab"
    else
        ok "No active entries"
    fi
fi

# ── 2. /etc/cron.d/ ──────────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[2] /etc/cron.d/${RST}"
if [ -d /etc/cron.d ]; then
    files=$(find /etc/cron.d -type f 2>/dev/null)
    if [ -n "$files" ]; then
        echo "$files" | while read -r f; do
            content=$(grep -Ev '^\s*(#|$)' "$f" 2>/dev/null)
            [ -z "$content" ] && continue
            warn "File: $f"
            echo "$content" | while read -r line; do echo "  $line"; done
            check_content "$f" "$f"
        done
    else
        ok "No files in /etc/cron.d"
    fi
fi

# ── 3. cron.hourly / daily / weekly / monthly ────────────────────────────────
sep
echo -e "\n${BLD}[3] CRON PERIODIC DIRS${RST}"
for dir in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
    files=$(find "$dir" -type f 2>/dev/null)
    if [ -n "$files" ]; then
        info "$dir:"
        echo "$files" | while read -r f; do
            echo "  • $f"
            check_content "$f" "$f"
        done
    fi
done

# ── 4. Per-user crontabs ──────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[4] USER CRONTABS${RST}"
CRON_SPOOL="/var/spool/cron/crontabs"  # Ubuntu
[ -d /var/spool/cron ] && [ ! -d "$CRON_SPOOL" ] && CRON_SPOOL="/var/spool/cron"  # Rocky

if [ -d "$CRON_SPOOL" ] && [ "$(id -u)" -eq 0 ]; then
    found=0
    for f in "$CRON_SPOOL"/*; do
        [ -f "$f" ] || continue
        user=$(basename "$f")
        content=$(grep -Ev '^\s*(#|$)' "$f" 2>/dev/null)
        [ -z "$content" ] && continue
        warn "Crontab for user '$user':"
        echo "$content" | while read -r line; do echo "  $line"; done
        check_content "$f" "crontab:$user"
        found=1
    done
    [ "$found" -eq 0 ] && ok "No user crontabs found"
else
    [ "$(id -u)" -ne 0 ] && warn "Need root to read all user crontabs"
    # Check current user's crontab
    current_cron=$(crontab -l 2>/dev/null)
    if [ -n "$current_cron" ]; then
        warn "Current user crontab:"
        echo "$current_cron"
    else
        ok "No crontab for current user"
    fi
fi

# ── 5. Systemd timers ────────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[5] SYSTEMD TIMERS${RST}"
if command -v systemctl &>/dev/null; then
    timers=$(systemctl list-timers --all 2>/dev/null | grep -v "^NEXT\|^$\|listed\|--")
    if [ -n "$timers" ]; then
        info "Active timers:"
        echo "$timers" | while read -r line; do
            unit=$(echo "$line" | awk '{print $NF}')
            # Flag user-created timers (not in standard locations)
            unit_file=$(systemctl show "$unit" -p FragmentPath 2>/dev/null | cut -d= -f2)
            if echo "$unit_file" | grep -qE '^(/home|/tmp|/var/tmp|/root)'; then
                alert "Timer with suspicious unit file: $unit → $unit_file"
            else
                info "  $line"
            fi
        done
    else
        ok "No active systemd timers"
    fi
fi

# ── 6. Systemd services (non-standard) ───────────────────────────────────────
sep
echo -e "\n${BLD}[6] NON-STANDARD SYSTEMD SERVICES${RST}"
if command -v systemctl &>/dev/null; then
    systemctl list-units --type=service --state=running 2>/dev/null | grep -Ev "(UNIT|loaded|listed|--)" | while read -r line; do
        unit=$(echo "$line" | awk '{print $1}')
        unit_file=$(systemctl show "$unit" -p FragmentPath 2>/dev/null | cut -d= -f2)
        if [ -n "$unit_file" ] && ! echo "$unit_file" | grep -qE '^(/lib/systemd|/usr/lib/systemd|/etc/systemd/system/(multi-user|network|sysinit|basic|sockets|getty|ssh|cron|rsyslog|udev|dbus|polkit|firewall|audit))'; then
            # Check if it's in a suspicious location
            if echo "$unit_file" | grep -qE '^(/home|/tmp|/root|/var/tmp)'; then
                alert "Service running from suspicious location: $unit → $unit_file"
            else
                warn "Non-standard service: $unit → $unit_file"
            fi
        fi
    done
fi

# ── 7. rc.local & init scripts ───────────────────────────────────────────────
sep
echo -e "\n${BLD}[7] RC.LOCAL & INIT SCRIPTS${RST}"
for f in /etc/rc.local /etc/rc.d/rc.local; do
    if [ -f "$f" ]; then
        content=$(grep -Ev '^\s*(#|$|exit)' "$f" 2>/dev/null)
        if [ -n "$content" ]; then
            warn "Active entries in $f:"
            echo "$content" | while read -r line; do echo "  $line"; done
            check_content "$f" "$f"
        else
            ok "$f is empty/default"
        fi
    fi
done

# ── 8. Shell profile backdoors ───────────────────────────────────────────────
sep
echo -e "\n${BLD}[8] SHELL PROFILE FILES${RST}"
PROFILE_FILES=(
    /etc/profile
    /etc/bashrc
    /etc/bash.bashrc
    /etc/environment
    /root/.bashrc
    /root/.bash_profile
    /root/.profile
)
# Add user profiles
for home in /home/*/; do
    for f in .bashrc .bash_profile .profile .zshrc; do
        [ -f "$home$f" ] && PROFILE_FILES+=("$home$f")
    done
done

for f in "${PROFILE_FILES[@]}"; do
    [ -f "$f" ] || continue
    check_content "$f" "$f"
    # Also flag any non-comment additions to system profiles
    if echo "$f" | grep -qE '^/etc/'; then
        nondefault=$(grep -Ev '^\s*(#|$|umask|export PATH|export|PS1|if \[|fi|esac|case|\.|source|\.|\[\[)' "$f" 2>/dev/null)
        if [ -n "$nondefault" ]; then
            warn "Non-standard content in $f:"
            echo "$nondefault" | while read -r line; do echo "  $line"; done
        fi
    fi
done

sep
echo -e "\n${BLD}Cron & persistence audit complete.${RST}\n"
