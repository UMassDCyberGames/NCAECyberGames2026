#!/bin/bash
read -p "Team number: " T
ROUTER="172.18.13.$T"

echo "==== Router Check for Team $T ===="
ping -c2 -W2 $ROUTER &>/dev/null && echo -e "Ping: \033[32mSuccess\033[0m" || echo -e "Ping: \033[31mFail\033[0m"
nc -z -v -w3 $ROUTER 22 80 &>/dev/null && echo -e "Ports 22/80: \033[32mOpen\033[0m" || echo -e "Ports 22/80: \033[31mClosed\033[0m"