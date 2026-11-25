# 02 — SSH Hardening

*IP addresses partially redacted for security reasons.*

## Goal

- `sysadmin` logs in with an ed25519 key
- Root login over SSH is denied
- Password authentication is disabled
- Only members of `admins` may log in over SSH
- All changes live in a drop-in under `/etc/ssh/sshd_config.d/`; the main `sshd_config` stays unmodified

## Commands

### On the client: create a key and install it for sysadmin

```bash
ssh-keygen -t ed25519
ssh-copy-id sysadmin@192.168.134.XXX
```

### Test the key login BEFORE hardening anything

```bash
ssh sysadmin@192.168.134.XXX
```

### On the server: the drop-in

```bash
sudo vim /etc/ssh/sshd_config.d/10-hardening.conf
```

```
PermitRootLogin no
PasswordAuthentication no
AllowGroups admins
MaxAuthTries 3
```

### Test, then restart

```bash
sudo sshd -t
sudo systemctl restart sshd
```

## Why these choices

- **Key first, hardening second:** disabling passwords before a key works locks you out.
- **A drop-in, not the main file:** package updates may replace `sshd_config`; files in `sshd_config.d/` are left alone, and all custom settings sit in one place.
- **`sshd -t` before restart:** same idea as `visudo` for sudoers: catch syntax errors before they take effect.
- **`AllowGroups admins`:** SSH access is granted by group membership, matching the sudo setup from Stage 1.
- **The file name `10-…`:** for most settings, sshd uses the *first* value it reads, and drop-ins are read in alphabetical order. A low number makes sure these settings win over `50-redhat.conf`.

## Incident: v1 hardening left in the main file

The v1 build had put `PermitRootLogin no` and `PasswordAuthentication no` directly into `/etc/ssh/sshd_config`. For v2 those lines were commented out and moved into the drop-in. With only the main file edited, `verify.sh` showed `password authentication is off` turning FAIL; after adding the drop-in it was back to PASS, which confirmed the drop-in is actually being read.

## Verification

```
$ sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|allowgroups'
permitrootlogin no
passwordauthentication no
allowgroups admins
```

```
$ sudo ./scripts/verify.sh
...
PASS: ssh root login is denied
PASS: ssh password authentication is off
PASS: ssh only allows group admins
Result: 10/10 checks passed
```

## Changes from v1

- Settings moved from `sshd_config` into a drop-in
- Added `AllowGroups admins`
- Key installed for `sysadmin` instead of the earlier `kwame` account
