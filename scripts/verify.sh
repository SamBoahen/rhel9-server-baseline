#!/usr/bin/env bash 

set -euo pipefail 
total="0"
passed="0"

if [ "$EUID" -ne 0 ]; then 
	echo "$0 must be run as root (try: sudo ./scripts/verify.sh)"
	exit 1
fi


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

sysadmin_uid_ok() { id --user sysadmin | grep -x 3001; }

admins_gid_ok() { getent group admins | awk -F: '{ print $3 }' | grep -x 3000; }

sysadmin_in_admins () { id -nG sysadmin  | grep -w admins ; }
webapp_nologin () { getent passwd webapp | awk -F: '$NF == "/sbin/nologin" { print $NF }' | grep -x /sbin/nologin ; } 

### Stage 2 functions
ssh_root_login_denied() { sshd -T | grep -x 'permitrootlogin no'; }
ssh_password_auth_off() { sshd -T | grep -x 'passwordauthentication no'; }
ssh_only_admins()       { sshd -T | grep -x 'allowgroups admins'; }

### Stage 3
fw_8080_open()       { firewall-cmd --permanent --list-ports | grep -w 8080/tcp; }
fw_cockpit_removed() { ! firewall-cmd --permanent --list-services | grep -w cockpit; }

### Stage 4 
selinux_enforcing_config () { grep -qx 'SELINUX=enforcing' /etc/selinux/config ; }
web_fcontext_rule () { semanage fcontext -l -C | grep "/srv/web" ; }

### Stage 5
web_mounted()        { mountpoint -q /srv/web; }
web_label_ok()       { blkid -s LABEL -o value /dev/vg_web/lv_web | grep -x WEBDATA; }
fstab_uses_label()   { awk '$2 == "/srv/web" { print $1 }' /etc/fstab | grep -x LABEL=WEBDATA; }

### Stage 6
web_page_ok() { curl -s http://localhost:8080 | grep -x 'rhel9-server-baseline v2'; }

### Stage 8
repo_enabled() { dnf repolist --enabled | grep -w "$1"; }
# Stage 1
check "user sysadmin exists" id sysadmin
check "user sysadmin has UID 3001" sysadmin_uid_ok
check "group admins has GID 3000" admins_gid_ok
check "user sysadmin is in group admins" sysadmin_in_admins
check "user webapp has no login shell" webapp_nologin
check "sudoers files are valid" visudo -c
check "group admins has a sudo rule" grep -rqs '^%admins' /etc/sudoers.d/

# Stage 2
check "ssh root login is denied" ssh_root_login_denied
check "ssh password authentication is off" ssh_password_auth_off
check "ssh only allows group admins" ssh_only_admins

# Stage 3
check "firewall allows 8080/tcp permanently" fw_8080_open
check "firewall no longer allows cockpit" fw_cockpit_removed

# Stage 4
check "selinux is enforcing" selinux_enforcing_config
check "selinux labels /srv/web as container_file_t" web_fcontext_rule


# Stage 5
check "/srv/web is mounted" web_mounted
check "lv_web has filesystem label WEBDATA" web_label_ok
check "fstab mounts /srv/web by label" fstab_uses_label

# Stage 6
check "webapp lingering is enabled" test -f /var/lib/systemd/linger/webapp
check "port 8080 serves the v2 page" web_page_ok

# Stage 7
check "journal is persistent" test -d /var/log/journal
check "journal size is capped at 1000M" grep -rqs '^SystemMaxUse=1000M' /etc/systemd/journald.conf.d/
check "errors.log exists" test -f /var/log/errors.log

# Stage 8
check "rhel9 iso is mounted at /mnt/rhel9" mountpoint -q /mnt/rhel9
check "repo local-baseos is enabled" repo_enabled local-baseos
check "repo local-appstream is enabled" repo_enabled local-appstream

echo "Result: $passed/$total checks passed"

if [ "$passed" -eq "$total" ]; then
	exit 0
else 
	exit 1
fi
