#!/usr/bin/env bash 

set -euo pipefail 
total="0"
passed="0"

### Stage 1 
## Checking to see if the user sysadmin exists.

if id  sysadmin &>/dev/null; then 
	echo "PASS: user sysadmin exists"
	passed="$((passed + 1 ))"
else
	echo "FAIL: user sysadmin exists"
fi 

total="$((total + 1 ))"


echo "Result: $passed/$total checks passed"

if [ "$passed" -eq "$total" ]; then 
	exit 0 
else 
	exit 1
fi


