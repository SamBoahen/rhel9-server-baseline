#!/usr/bin/env bash


### Task 01
if id sysadmin &>/dev/null; then
    echo "PASS: sysadmin user exists"
else
    echo "FAIL: sysadmin user exists"
fi

### Task 02
if systemctl is-active --quiet sshd; then
    echo "PASS: sshd is active"
else
    echo "FAIL: sshd is inactive; enable it now"
fi

### Task 03
if sudo firewall-cmd --list-services | grep -Eq "http|https|ssh"; then
    echo "PASS: only the required services are allowed"
else
    echo "FAIl: Some not required service is running"
fi


### Task 04
if [ "$(getenforce)" = "Enforcing" ]; then
    echo "PASS: SELinux is enforcing"
else
    echo "FAIL: SELinux is enforcing"
fi


### Task 05
if mountpoint -q /srv/web; then
    echo "PASS: /srv/web is mounted"
else
    echo "FAIL: /srv/web is mounted"
fi

### Task 06

if  curl -sf http://localhost:8080 -o /dev/null; then
    echo "PASS: apacheserver is working"
else
    echo "FAIL: apacherserver is not working"
fi


### Task 07
if [ -d /var/log/journal ]; then
    echo "PASS: persistent journal directory exists"
else
    echo "FAIL: persistent journal directory exists"
fi


### Task 08
if  dnf repolist | grep -q local-baseos; then
    echo "PASS: Local baseOS repo exist"
else
    echo "FAIL: Local baseOS repo doesn't exist "
fi

