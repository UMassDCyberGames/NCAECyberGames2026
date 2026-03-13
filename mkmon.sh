#! /bin/bash

if [ $# -lt 1 ]; then
	echo Error, there must be at least one dir path argument;
	exit;
fi;

declare -a filecount=();
for i in "$@"; do
	filecount+=("$(tree "$i" -a | wc -l)")
done;

while [ 1 ]; do
	for i in $(seq 1 $#); do
		curr_count="$(tree ${!i} -a | wc -l)"
		if [[ "${curr_count}" != "${filecount[$((i - 1))]}" ]]; then
			echo "Warn! ${!i} file count changed at $(date)";
			echo
			filecount[$((i - 1))]="$curr_count";
		fi;
	done;
	sleep 1;
done;
