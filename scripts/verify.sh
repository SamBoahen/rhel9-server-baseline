#!/usr/bin/env bash 

set -euo pipefail 
total="0"
passed="0"

check () { 
	label="$1"
	shift
	total=$((total + 1))

	if [ "$#" -eq 0 ]; then
		echo "FAIL: $label (no command given)"
		return	
	fi


	if "$@" &>/dev/null; then 
		echo "PASS: $label"
		passed=$((passed + 1))

	else 
		echo "FAIL: $label"
 	fi
}

# Stage 1
check "user sysadmin exists" id sysadmin
echo "Result: $passed/$total checks passed"

if [ "$passed" -eq "$total" ]; then
	exit 0
else 
	exit 1
fi


