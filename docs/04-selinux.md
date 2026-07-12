# 04 — SELinux Configuration

## What was configured
In stage 04 i set my selinux into enforcing mode(also editing selinux files)then labeled a non defaults directory so selinux allows contents being accessed and restorecon and lastly added a seboolean on httpd network 

## Commands
### To check selinux status
sestatus

### Setting selinux into enforcing mode and editing the right file 
sudo setenforce 1
sudo vim /etc/selinux/config 

## Created the dir. for stage 6 and labeled it and restorecon 
sudo mkdir -p /srv/web
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/web(/.*)?"
sudo restorecon -Rv /srv/web/ 

### Checking seboolean configurations 
sudo getsebool -a

### setting seboolean 
sudo setsebool -P httpd_can_network_connect off

## Why these choices
No booleans needed beyond defaults the web container only serves static content
## Verification
sudo ls -Zl /srv/
total 0
drwxr-xr-x. 2 root root unconfined_u:object_r:httpd_sys_content_t:s0 6 Jul 11 15:03 web

sudo getsebool -a | grep -E 'httpd_can_network_connect'
httpd_can_network_connect --> off
httpd_can_network_connect_cobbler --> off
httpd_can_network_connect_db --> off

sestatus 
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33

ls -l /srv/
total 0
drwxr-xr-x. 2 root root 6 Jul 11 15:03 web

## What went wrong
I wrote  (./*)? dot and slash swapped. it LOOKED
fine; the empty directory still relabeled, because the base path matched.

The fix:
semanage fcontext -d to delete the bad rule, -a with the correct pattern.
