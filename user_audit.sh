#!/bin/bash
# User & Privilege Audit — Ubuntu 24.04 / Rocky Linux 9
# Run as root for full output

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
RST='\033[0m'

warn()  { echo -e "${YEL}[WARN]${RST} $*"; }
alert() { echo -e "${RED}[ALERT]${RST} $*"; }
info()  { echo -e "${CYN}[INFO]${RST} $*"; }
ok()    { echo -e "${GRN}[ OK ]${RST} $*"; }
sep()   { echo -e "${BLD}──────────────────────────────────────────${RST}"; }

echo -e "\n${BLD}=== USER & PRIVILEGE AUDIT ===${RST}"
echo "Host: $(hostname)  |  Date: $(date)"
echo "Running as: $(whoami) (UID=$(id -u))"
sep

# ── 1. Current user privileges ──────────────────────────────────────────────
echo -e "\n${BLD}[1] CURRENT USER PRIVILEGES${RST}"
if [ "$(id -u)" -eq 0 ]; then
    info "Running as root — full audit available"
else
    warn "Not root — some checks may be incomplete"
fi

SUDO_GROUPS=("sudo" "wheel" "admin")
for g in "${SUDO_GROUPS[@]}"; do
    if id -nG 2>/dev/null | grep -qw "$g"; then
        warn "Current user is in group: $g"
    fi
done

# ── 2. All login-capable users ───────────────────────────────────────────────
sep
echo -e "\n${BLD}[2] LOGIN-CAPABLE USERS${RST}"
LOGIN_USERS=$(awk -F: '$7 !~ /(nologin|false|sync|halt|shutdown)/ && $3 >= 1000 {print $1, $3, $6, $7}' /etc/passwd)
USER_COUNT=$(echo "$LOGIN_USERS" | grep -c .)
info "Human accounts (UID ≥ 1000): $USER_COUNT"
echo "$LOGIN_USERS" | while read -r name uid home shell; do
    echo "  • $name  (UID=$uid)  home=$home  shell=$shell"
done

# ── 3. Root-equivalent accounts (UID 0) ──────────────────────────────────────
sep
echo -e "\n${BLD}[3] ROOT-EQUIVALENT ACCOUNTS (UID 0)${RST}"
ROOT_EQUIV=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
ROOT_COUNT=$(echo "$ROOT_EQUIV" | grep -c .)
if [ "$ROOT_COUNT" -gt 1 ]; then
    alert "Multiple UID-0 accounts found!"
    echo "$ROOT_EQUIV" | while read -r u; do alert "  UID-0: $u"; done
elif echo "$ROOT_EQUIV" | grep -q "^root$" && [ "$ROOT_COUNT" -eq 1 ]; then
    ok "Only root has UID 0"
else
    alert "Unexpected UID-0 situation: $ROOT_EQUIV"
fi

# ── 4. Sudo / wheel members ───────────────────────────────────────────────────
sep
echo -e "\n${BLD}[4] SUDO / WHEEL GROUP MEMBERS${RST}"
for g in sudo wheel admin; do
    members=$(getent group "$g" 2>/dev/null | cut -d: -f4)
    if [ -n "$members" ]; then
        warn "Group '$g': $members"
    fi
done

# ── 5. Sudoers rules (non-default) ───────────────────────────────────────────
sep
echo -e "\n${BLD}[5] SUDOERS RULES${RST}"
if [ "$(id -u)" -eq 0 ]; then
    SUDOERS_FILES=(/etc/sudoers /etc/sudoers.d/*)
    for f in "${SUDOERS_FILES[@]}"; do
        [ -f "$f" ] || continue
        matches=$(grep -Ev '^\s*(#|$|Defaults)' "$f" 2>/dev/null)
        if [ -n "$matches" ]; then
            warn "Rules in $f:"
            echo "$matches" | while read -r line; do
                if echo "$line" | grep -q "NOPASSWD"; then
                    alert "  NOPASSWD: $line"
                else
                    echo "  • $line"
                fi
            done
        fi
    done
else
    warn "Skipped — need root to read sudoers"
fi

# ── 6. Users with empty passwords ────────────────────────────────────────────
sep
echo -e "\n${BLD}[6] EMPTY PASSWORDS${RST}"
if [ "$(id -u)" -eq 0 ]; then
    EMPTY=$(awk -F: '($2 == "" || $2 == "!!" || $2 == "!") && $3 >= 0 {print $1}' /etc/shadow 2>/dev/null)
    if [ -n "$EMPTY" ]; then
        echo "$EMPTY" | while read -r u; do alert "Empty/locked password: $u"; done
    else
        ok "No empty passwords found"
    fi
else
    warn "Skipped — need root to read /etc/shadow"
fi

# ── 7. Recently created users (last 7 days) ───────────────────────────────────
sep
echo -e "\n${BLD}[7] RECENTLY CREATED/MODIFIED ACCOUNTS${RST}"
if [ "$(id -u)" -eq 0 ]; then
    recent=$(find /home -maxdepth 1 -type d -newer /etc/passwd -not -name home 2>/dev/null)
    if [ -n "$recent" ]; then
        warn "Recently created home dirs (newer than /etc/passwd mod time):"
        echo "$recent" | while read -r d; do warn "  $d"; done
    else
        ok "No recently created home directories detected"
    fi
    # Also check passwd change times via lastchg in shadow
    while IFS=: read -r user pass lastchg _; do
        if [ -n "$lastchg" ] && [ "$lastchg" -gt 0 ] 2>/dev/null; then
            changed_epoch=$(( lastchg * 86400 ))
            now_epoch=$(date +%s)
            diff=$(( now_epoch - changed_epoch ))
            if [ "$diff" -lt 604800 ]; then  # 7 days
                warn "Password changed recently: $user (${diff}s ago)"
            fi
        fi
    done < /etc/shadow 2>/dev/null
else
    warn "Skipped — need root"
fi

# ── 8. Users currently logged in ─────────────────────────────────────────────
sep
echo -e "\n${BLD}[8] CURRENTLY LOGGED-IN USERS${RST}"
who_output=$(who 2>/dev/null)
if [ -n "$who_output" ]; then
    echo "$who_output" | while read -r line; do
        user=$(echo "$line" | awk '{print $1}')
        if [ "$user" != "$(logname 2>/dev/null)" ] && [ "$user" != "$(whoami)" ]; then
            warn "Other user logged in: $line"
        else
            info "  $line"
        fi
    done
else
    ok "No other active sessions"
fi

# ── 9. Last logins ────────────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[9] LAST 10 LOGINS${RST}"
last 2>/dev/null | head -10

# ── 10. Suspicious indicators ─────────────────────────────────────────────────
sep
echo -e "\n${BLD}[10] SUSPICIOUS INDICATORS${RST}"
SUSPICIOUS=0

# Users with shells but UID < 1000 (except root)
awk -F: '$3 > 0 && $3 < 1000 && $7 !~ /(nologin|false)/ {print $1, $3, $7}' /etc/passwd | while read -r name uid shell; do
    alert "System account with login shell: $name (UID=$uid) shell=$shell"
    SUSPICIOUS=1
done

# World-writable home dirs
for homedir in /home/*/; do
    [ -d "$homedir" ] || continue
    perms=$(stat -c "%a" "$homedir" 2>/dev/null || stat -f "%Lp" "$homedir" 2>/dev/null)
    if [[ "$perms" == *7 ]] || [[ "$perms" == *6 ]] || [[ "$perms" == *5 ]]; then
        warn "World-writable home: $homedir ($perms)"
        SUSPICIOUS=1
    fi
done

# .ssh authorized_keys check
for home in /root /home/*/; do
    ak="$home/.ssh/authorized_keys"
    if [ -f "$ak" ]; then
        count=$(wc -l < "$ak")
        warn "$ak — $count key(s)"
    fi
done

if [ "$SUSPICIOUS" -eq 0 ]; then
    ok "No obvious suspicious indicators"
fi

sep
echo -e "\n${BLD}Audit complete.${RST}\n"
