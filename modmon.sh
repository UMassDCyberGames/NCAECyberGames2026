#! /bin/bash

if [ $# -lt 1 ]; then
	echo Error, there must be at least one file path argument;
	exit;
fi;

echo "Reading existing modification times";

declare -a modtime=();
for i in "$@"; do
	modtime+=("$(ls "$i" -l | awk '{print $6$7$8}')")
	echo "$i ${modtime[-1]}";
done;

echo -e "\nMonitoring any changes to these files";

while [ 1 ]; do
	for i in $(seq 1 $#); do
		curr_modtime="$(ls ${!i} -l | awk '{print $6$7$8}')"
		#echo $curr_modtime ${!i}
		if [[ "${curr_modtime}" != "${modtime[$((i - 1))]}" ]]; then
			echo "Warn! ${!i} modified at $curr_modtime";
			echo
			modtime[$((i - 1))]="$curr_modtime"
		fi
	done;
	sleep 1;
done;
