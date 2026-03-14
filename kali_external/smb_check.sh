#!/bin/bash
read -p "Team number: " T
SMB="172.18.14.$T"

echo "==== Checking SMB Shares on $SMB ===="
smbclient -L //$SMB -N &>/dev/null
if [ $? -eq 0 ]; then
    echo -e "\033[32mSMB is reachable\033[0m"
else
    echo -e "\033[31mSMB unreachable\033[0m"
fi