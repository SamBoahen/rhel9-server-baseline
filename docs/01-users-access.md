# 01 — Users & Access Control


## What was configured

I created a user called "sysadmin" with shell "bash" and a comment describing who the person is.

I then created a group called admins. I then proceeded to add "sysadmin to the group admins and later gave the group "admins" sudo privileges via visudo

I needed a service user which i will later to run my podman so i create 1 called websvc with no shell. 

## Commands
 
### creating the user sysadmins
sudo useradd -c " This is group admin of group admins " -s /bin/bash sysadmin

### creating the group
sudo groupadd admins 

### adding sysadmin to the group admins 
sudo usermod -aG admins sysadmin

## giving group admins sudo privileges
sudo visudo -f /etc/sudoers.d/admins

%admins ALL=(ALL) ALL

## creating system user 
sudo useradd -r -s /bin/nologin -m -d /home/websvc websvc

### setting default permissions for websvc
echo "umask 027" | sudo tee -a /home/websvc/.bashrc


## Why these choices
Using visudo /etc/sudoers.d is the best practice because it prevents you from getting lock out if there is a syntax error in the file. 

A system user was the best solution for me to use for my podman later. i didnt want to use my user or the sysadmin.

sudo su -s /bin/bash - websvc        
touch testfile && ls -l testfile  

is a tricky way to login as service user websvc; websvc has no interactive shell   

adding "-r creates a system account (UID below 1000 — websvc got 985), keeping it out of login screens and separate from human users." You made the choice; show the reasoning.

## Verification

getent passwd | grep sysadmin
sysadmin:x:1001:1001: This is group admin of group admins :/home/sysadmin:/bin/bash

getent group | grep admins
admins:x:1002:

id sysadmin 
uid=1001(sysadmin) gid=1001(sysadmin) groups=1001(sysadmin),1002(admins)

sudo -l -U sysadmin
Matching Defaults entries for sysadmin on obibinii:
    !visiblepw, always_set_home, match_group_by_gid, always_query_group_plugin, env_reset,
    env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS", env_keep+="MAIL PS1 PS2 QTDIR USERNAME
    LANG LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES",
    env_keep+="LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL LANGUAGE
    LINGUAS _XKB_CHARSET XAUTHORITY", secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User sysadmin may run the following commands on obibinii:
    (ALL) ALL


getent passwd | grep websvc
websvc:x:985:984::/home/websvc:/bin/nologin

id websvc 
uid=985(websvc) gid=984(websvc) groups=984(websvc)

sudo chage -l sysadmin
Last password change					: Jul 10, 2026
Password expires					: Oct 08, 2026
Password inactive					: never
Account expires						: never
Minimum number of days between password change		: 0
Maximum number of days between password change		: 90
Number of days of warning before password expires	: 7

sudo su -s /bin/bash - websvc
[websvc@obibinii ~]$ touch testfile && ls -l testfile
-rw-r-----. 1 websvc websvc 0 Jul 10 03:23 testfile

## What went wrong 
Creating a system user was kind of difficult for me because I need it for my podman later on, and i didnt want to use "sudo" in useradd because podman is a rootless daemon; using sudo means it  wouldn't match my needs later on 
