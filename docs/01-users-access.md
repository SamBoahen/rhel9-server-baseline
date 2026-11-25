# 01 — Users & Access Control

## Goal

- Group `admins` with a fixed GID (3000)
- Admin user `sysadmin` with a fixed UID (3001), member of `admins`
- Members of `admins` can run any command via sudo, defined in `/etc/sudoers.d/`
- Service account `webapp` with no interactive login, used later to run the rootless container (Stage 6)
- Password aging: new users expire after 90 days; `sysadmin` must change password every 60 days

## Commands

### Password aging default (before creating users)

```bash
sudo vim /etc/login.defs        # set: PASS_MAX_DAYS   90
grep ^PASS_MAX_DAYS /etc/login.defs
```

`login.defs` only applies to users created *after* the change, so this comes first.

### Group

```bash
sudo groupadd -g 3000 admins
```

### Admin user

```bash
sudo useradd -u 3001 -G admins sysadmin
sudo passwd sysadmin
sudo chage -M 60 sysadmin
sudo chage -l sysadmin
```

Creating the group first lets `useradd -G` add the membership in one step.

### Service account

```bash
sudo useradd -r -m -s /sbin/nologin webapp
```

- `-r` creates a system account (UID below 1000)
- `-m` still creates a home directory, which the rootless container needs in Stage 6
- `-s /sbin/nologin` blocks interactive logins

### Sudo rule

```bash
sudo visudo -f /etc/sudoers.d/admins
```

Contents:

```
%admins ALL=(ALL) ALL
```

`%` marks a group rather than a user.

## Incident: wrong permissions on the sudoers drop-in

After creating the file with `visudo -f`, `verify.sh` reported:

```
FAIL: sudoers files are valid
```

The file had been created as `0640`:

```
-rw-r-----. 1 root root 22 Nov 21 23:31 /etc/sudoers.d/admins
```

`visudo -c` rejects sudoers files that aren't `0440`, because files in
`/etc/sudoers.d/` grant root-level access and must be read-only.

Fix:

```bash
sudo chmod 0440 /etc/sudoers.d/admins
sudo visudo -c
```

The same check also found an older drop-in from the original VM setup
(`/etc/sudoers.d/obibiniitakyi`) with the same problem, fixed the same way.

## Why these choices

- **Fixed UID/GID:** consistent IDs across machines make file ownership predictable, for example on shared storage or restored backups.
- **Drop-in file instead of editing `/etc/sudoers`:** keeps custom rules separate from the vendor file, so package updates never touch them.
- **`visudo -f` instead of a plain editor:** it checks syntax before saving, so a typo can't lock everyone out of sudo. (It does not guarantee correct permissions, as the incident above shows.)
- **Group-based sudo:** access is granted by adding someone to `admins`, not by editing sudoers per person.

## Verification

```
$ sudo -l -U sysadmin
User sysadmin may run the following commands on server1:
    (ALL) ALL
```

```
$ sudo ./scripts/verify.sh
PASS: user sysadmin exists
PASS: user sysadmin has UID 3001
PASS: group admins has GID 3000
PASS: user sysadmin is in group admins
PASS: user webapp has no login shell
PASS: sudoers files are valid
PASS: group admins has a sudo rule
Result: 7/7 checks passed
```

## Changes from v1

- Service account renamed from `websvc` to `webapp`
- Fixed the nologin path: v1 used `/bin/nologin`, which doesn't exist on RHEL 9
- Added fixed UID/GID and password aging
- Dropped `umask 027` in the service account's `.bashrc`: a `nologin` account never starts an interactive shell, so `.bashrc` is never read
