#!/bin/bash
read -p "Team number: " T
ROUTER="172.18.13.$T"
JUMP="172.18.12.15"
SMB="172.18.14.$T"

echo "==== Port Scan for Team $T ===="
for IP in $ROUTER $JUMP $SMB; do
    echo -e "\nScanning $IP..."
    nc -zv -w2 $IP 22 80 443 445 2213
done
echo "Done!"