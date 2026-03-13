#!/bin/bash
# Network Audit — Ubuntu 24.04 / Rocky Linux 9

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'
warn()  { echo -e "${YEL}[WARN]${RST} $*"; }
alert() { echo -e "${RED}[ALERT]${RST} $*"; }
info()  { echo -e "${CYN}[INFO]${RST} $*"; }
ok()    { echo -e "${GRN}[ OK ]${RST} $*"; }
sep()   { echo -e "${BLD}──────────────────────────────────────────${RST}"; }

echo -e "\n${BLD}=== NETWORK AUDIT ===${RST}"
echo "Host: $(hostname)  |  Date: $(date)"
sep

# ── 1. Network interfaces & IPs ──────────────────────────────────────────────
echo -e "\n${BLD}[1] NETWORK INTERFACES${RST}"
ip addr show 2>/dev/null | grep -E '(^[0-9]+:|inet )' | while read -r line; do
    info "$line"
done

# ── 2. All listening ports ────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[2] LISTENING PORTS${RST}"
COMMON_PORTS="20 21 22 25 53 80 110 111 143 443 445 587 993 995 2049 3306 5432 8080 8443 3389 3000 8000"
if command -v ss &>/dev/null; then
    ss -tlnup 2>/dev/null | tail -n +2 | while read -r line; do
        port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
        is_common=0
        for p in $COMMON_PORTS; do [ "$port" = "$p" ] && is_common=1 && break; done
        if [ "$is_common" -eq 0 ]; then
            warn "Uncommon listening port: $port — $line"
        else
            info "Port $port: $line"
        fi
    done
fi

# ── 3. Active outbound connections ───────────────────────────────────────────
sep
echo -e "\n${BLD}[3] ACTIVE OUTBOUND CONNECTIONS${RST}"
if command -v ss &>/dev/null; then
    ss -tnp state established 2>/dev/null | tail -n +2 | while read -r line; do
        dport=$(echo "$line" | awk '{print $5}' | rev | cut -d: -f1 | rev)
        dip=$(echo "$line" | awk '{print $5}' | rev | cut -d: -f2- | rev)
        proc=$(echo "$line" | grep -oP 'users:\(\(".*?"\)' | head -1)
        # Flag connections to non-RFC1918 on unusual ports
        if ! echo "$dip" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)'; then
            COMMON_DPORTS="22 80 443 53 25 587 993 995 8080 8443"
            is_common=0
            for p in $COMMON_DPORTS; do [ "$dport" = "$p" ] && is_common=1 && break; done
            if [ "$is_common" -eq 0 ]; then
                alert "Suspicious outbound: $dip:$dport — $proc"
            else
                info "Outbound $dip:$dport — $proc"
            fi
        fi
    done
fi

# ── 4. /etc/hosts tampering ───────────────────────────────────────────────────
sep
echo -e "\n${BLD}[4] /etc/hosts CHECK${RST}"
info "Contents of /etc/hosts:"
cat /etc/hosts | grep -Ev '^\s*(#|$)' | while read -r line; do
    # Flag anything redirecting common domains
    if echo "$line" | grep -qiE '(google|github|microsoft|ubuntu|rockylinux|centos|debian|apt\.|yum\.|update\.)'; then
        alert "Possible hijack in /etc/hosts: $line"
    else
        echo "  $line"
    fi
done

# ── 5. DNS resolver config ────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[5] DNS RESOLVERS${RST}"
if [ -f /etc/resolv.conf ]; then
    grep "^nameserver" /etc/resolv.conf | while read -r line; do
        ns=$(echo "$line" | awk '{print $2}')
        # Flag non-standard DNS servers
        if ! echo "$ns" | grep -qE '^(8\.8\.[0-9]+\.[0-9]+|1\.1\.[0-9]+\.[0-9]+|9\.9\.9\.[0-9]+|208\.67\.|127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)'; then
            warn "Non-standard DNS server: $ns"
        else
            info "DNS: $ns"
        fi
    done
else
    warn "/etc/resolv.conf not found"
fi

# ── 6. Default gateway & routing table ───────────────────────────────────────
sep
echo -e "\n${BLD}[6] ROUTING TABLE${RST}"
ip route show 2>/dev/null | while read -r line; do info "$line"; done

# ── 7. ARP table (detect ARP spoofing) ───────────────────────────────────────
sep
echo -e "\n${BLD}[7] ARP TABLE (duplicate MACs = ARP spoofing)${RST}"
arp_out=$(arp -n 2>/dev/null || ip neigh 2>/dev/null)
echo "$arp_out"
# Check for duplicate MACs
dupe_macs=$(echo "$arp_out" | awk '{print $3}' | sort | uniq -d | grep -v '^$')
if [ -n "$dupe_macs" ]; then
    alert "Duplicate MACs detected (possible ARP spoofing): $dupe_macs"
else
    ok "No duplicate MACs"
fi

# ── 8. Firewall rules summary ─────────────────────────────────────────────────
sep
echo -e "\n${BLD}[8] FIREWALL STATUS${RST}"
if command -v ufw &>/dev/null; then
    status=$(ufw status 2>/dev/null | head -1)
    if echo "$status" | grep -q "inactive"; then
        alert "UFW is INACTIVE — no firewall!"
    else
        info "$status"
        ufw status numbered 2>/dev/null | head -20
    fi
elif command -v firewall-cmd &>/dev/null; then
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        info "firewalld is running"
        firewall-cmd --list-all 2>/dev/null
    else
        alert "firewalld is NOT running!"
    fi
elif command -v iptables &>/dev/null; then
    rule_count=$(iptables -L 2>/dev/null | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo 0)
    if [ "$rule_count" -eq 0 ]; then
        warn "iptables appears to have no rules"
    else
        info "iptables has $rule_count rules"
        iptables -L -n --line-numbers 2>/dev/null | head -40
    fi
fi

# ── 9. Open network shares ────────────────────────────────────────────────────
sep
echo -e "\n${BLD}[9] NETWORK SHARES (NFS/SAMBA)${RST}"
if [ -f /etc/exports ]; then
    exports=$(grep -Ev '^\s*(#|$)' /etc/exports)
    if [ -n "$exports" ]; then
        warn "NFS exports found:"
        echo "$exports" | while read -r line; do
            if echo "$line" | grep -q "no_root_squash"; then
                alert "  no_root_squash: $line"
            else
                warn "  $line"
            fi
        done
    else
        ok "No NFS exports"
    fi
fi
if command -v smbstatus &>/dev/null; then
    info "Samba status:"
    smbstatus --shares 2>/dev/null | head -20
fi

sep
echo -e "\n${BLD}Network audit complete.${RST}\n"
