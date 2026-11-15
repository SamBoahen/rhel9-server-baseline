#!/usr/bin/env bash 

set -euo pipefail 

### Stage 1 
## Checking to see if the user sysadmin exists.

if id sysadmin >&/dev/null; then 
	echo "PASS: user sysadmin exists"
else
	echo "FAIL: user sysadmin exists"
fi 


