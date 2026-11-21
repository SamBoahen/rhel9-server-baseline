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

sysadmin_uid_ok() { id --user sysadmin | grep -qx 3001; }

admins_gid_ok() { getent group sysadmin  | awk -F: '{ print $3 }' | grep -qx 3000; }

# Stage 1
check "user sysadmin exists" id sysadmin
check "user sysadmin has UID 3001" sysadmin_uid_ok
check "group admins has GID 3000" admins_gid_ok
echo "Result: $passed/$total checks passed"

if [ "$passed" -eq "$total" ]; then
	exit 0
else 
	exit 1
fi


