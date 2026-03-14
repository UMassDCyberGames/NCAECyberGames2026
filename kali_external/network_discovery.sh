#!/bin/bash
read -p "Team number: " T
EXTERNAL_NET="172.18.0.0/16"
echo "==== Network Discovery for Team $T ===="

# Ping sweep for live hosts
for i in $(seq 1 254); do
    IP="172.18.13.$i"
    ping -c1 -W1 $IP &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Host UP: $IP"
    fi
done

echo "Done!"