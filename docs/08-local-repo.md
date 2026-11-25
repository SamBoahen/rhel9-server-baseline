# 08 — Local Repository

## Goal

- The RHEL 9 installation ISO is mounted read-only at `/mnt/rhel9` at boot
- Repositories `local-baseos` and `local-appstream` in `/etc/yum.repos.d/local.repo` point to the mounted ISO
- GPG checking is enabled for both, using the Red Hat release key
- A package can be installed with only these two repositories enabled

## Commands

### Mount the ISO at boot, by label

```bash
sudo mkdir -p /mnt/rhel9
sudo vim /etc/fstab
```

```
LABEL=RHEL-9-7-0-BaseOS-x86_64   /mnt/rhel9   iso9660   ro,nofail   0 0
```

```bash
sudo systemctl daemon-reload
sudo mount -a
ls /mnt/rhel9
```

### Define both repositories

`/etc/yum.repos.d/local.repo`:

```ini
[local-baseos]
name=RHEL 9 BaseOS (local ISO)
baseurl=file:///mnt/rhel9/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[local-appstream]
name=RHEL 9 AppStream (local ISO)
baseurl=file:///mnt/rhel9/AppStream
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

### Prove it works with only the local repositories

```bash
sudo dnf clean all
sudo dnf --disablerepo='*' --enablerepo='local-*' reinstall -y tree
```

`reinstall` forces a download from the repository and a signature check, even when the package is already installed.

## Why these choices

- **Mount by label:** the CD drive's device name (`/dev/sr1`) can change; the ISO's label stays the same (same idea as Stage 5).
- **`ro`:** an ISO can't be written to, and the mount makes that explicit.
- **`nofail`:** if the ISO isn't connected, the boot continues instead of stopping in emergency mode.
- **`gpgcheck=1`:** every package is checked against Red Hat's signing key, so a tampered or corrupted package is refused.
- **Two repositories:** on RHEL 9, packages are split between BaseOS (core OS) and AppStream (applications, runtimes). Many installs need both.

## Verification

```
$ findmnt /mnt/rhel9
TARGET     SOURCE   FSTYPE  OPTIONS
/mnt/rhel9 /dev/sr1 iso9660 ro,...
```

```
$ sudo ./scripts/verify.sh
...
PASS: rhel9 iso is mounted at /mnt/rhel9
PASS: repo local-baseos is enabled
PASS: repo local-appstream is enabled
Result: 25/25 checks passed
```

## Changes from v1

- **GPG checking turned on.** v1 used `gpgcheck=0`, which installs packages without verifying their signatures.
- **The mount is now persistent.** v1 mounted the ISO by hand, so the repositories broke after every reboot. v2 mounts it from fstab, by label, with `nofail`.
- **No more unmounting the desktop's automount.** v1 had to unmount the GNOME auto-mount under `/run/media`, because its permission bits blocked dnf. v2 mounts the ISO separately at `/mnt/rhel9`, owned by root.
- Mount point renamed from `/mnt/iso` to `/mnt/rhel9`
