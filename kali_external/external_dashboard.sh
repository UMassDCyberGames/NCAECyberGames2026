#!/bin/bash

read -p "Team number: " T

ROUTER="172.18.13.$T"
SMB="172.18.14.$T"
JUMP="172.18.12.15"
CDN="172.18.13.25"

LOG="external_alerts.log"

prev_router=""
prev_smb=""
prev_jump=""

check_ping() {
    ping -c1 -W2 $1 &>/dev/null && echo "UP" || echo "DOWN"
}

check_port() {
    nc -z -w3 $1 $2 &>/dev/null && echo "OPEN" || echo "CLOSED"
}

while true
do

clear
echo "==============================="
echo " External Kali Monitoring"
echo " Team $T"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "==============================="

router_status=$(check_ping $ROUTER)
smb_status=$(check_ping $SMB)
jump_status=$(check_port $JUMP 2213)

echo ""
echo "Router ($ROUTER): $router_status"
echo "SMB Host ($SMB): $smb_status"
echo "Jump Host SSH: $jump_status"

echo ""
echo "CDN HTTP status:"
curl -sI --max-time 4 http://$CDN | head -n1

echo ""
echo "Router exposed ports:"
nmap -Pn -F $ROUTER | grep open

echo ""
echo "--------------------------------"

# Change detection

if [[ "$router_status" != "$prev_router" && "$prev_router" != "" ]]; then
echo "$(date) ALERT Router state changed: $router_status" | tee -a $LOG
fi

if [[ "$smb_status" != "$prev_smb" && "$prev_smb" != "" ]]; then
echo "$(date) ALERT SMB host state changed: $smb_status" | tee -a $LOG
fi

if [[ "$jump_status" != "$prev_jump" && "$prev_jump" != "" ]]; then
echo "$(date) ALERT Jump host SSH changed: $jump_status" | tee -a $LOG
fi

prev_router=$router_status
prev_smb=$smb_status
prev_jump=$jump_status

sleep 12

done