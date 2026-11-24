# 04 — SELinux

## Goal

- SELinux runs in enforcing mode, persistently
- A persistent file-context rule labels `/srv/web` and everything below it as `container_file_t`

## Commands

### Check the mode

```bash
getenforce
grep ^SELINUX= /etc/selinux/config
```

RHEL 9 ships with `SELINUX=enforcing`, so this was already correct. It is still checked by `verify.sh` as a safety check.

### Label rule for the web content

```bash
sudo semanage fcontext -a -t container_file_t '/srv/web(/.*)?'
sudo mkdir -p /srv/web
sudo restorecon -Rv /srv/web
```

`(/.*)?` covers the directory itself and everything inside it. `semanage` saves the rule; `restorecon` applies it to files that already exist.

## Why these choices

- **Enforcing, not permissive:** permissive only logs violations. A baseline should actually enforce the policy.
- **`semanage fcontext` instead of `chcon`:** `chcon` labels are lost on a relabel; a `semanage` rule is permanent and is reapplied by `restorecon`.
- **`container_file_t` instead of `httpd_sys_content_t`:** the content is served by a rootless podman container (Stage 6), and SELinux only lets containers read files labelled `container_file_t`.
- **No booleans changed:** the container serves static files, so no extra permissions are needed.

## Verification

```
$ sudo semanage fcontext -l -C
/srv/web(/.*)?    all files    system_u:object_r:container_file_t:s0

$ ls -ldZ /srv/web
drwxr-xr-x. 2 root root unconfined_u:object_r:container_file_t:s0 6 Nov 24 11:25 /srv/web
```

## Changes from v1

- Label changed from `httpd_sys_content_t` to `container_file_t` to match the rootless container
- Removed `setsebool -P httpd_can_network_connect off`: it set a boolean to its default value, so it changed nothing
