#!/bin/bash
read -p "Team number: " T
ROUTER="172.18.13.$T"
SMB="172.18.14.$T"
JUMP="172.18.12.15"
CDN="172.18.13.25"

while true; do
  clear
  echo "==== External Kali Dashboard - Team $T ===="
  echo "$(date '+%Y-%m-%d %H:%M:%S')"

  ping -c1 -W2 $ROUTER &>/dev/null && echo -e "Router ($ROUTER): \033[32mUP\033[0m" || echo -e "Router ($ROUTER): \033[31mDOWN\033[0m"
  ping -c1 -W2 $SMB &>/dev/null && echo -e "SMB/Shell ($SMB): \033[32mUP\033[0m" || echo -e "SMB/Shell ($SMB): \033[31mDOWN\033[0m"
  nc -z -w3 $JUMP 2213 &>/dev/null && echo -e "Jumphost SSH (2213): \033[32mOPEN\033[0m" || echo -e "Jumphost SSH (2213): \033[31mCLOSED\033[0m"
  curl -sI --max-time 5 http://$CDN | head -n1 | grep -q "200" && echo -e "CDN HTTP: \033[32m200 OK\033[0m" || echo -e "CDN HTTP: \033[33m???\033[0m"

  sleep 15
done