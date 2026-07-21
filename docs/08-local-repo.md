# 08 — Local Repository

## What was configured
A local DNF repository was configured using the mounted RHEL 9 installation
ISO as the package source, with both BaseOS and AppStream defined, so that
packages can be installed without internet access.

## Commands

### Mount the ISO with root-accessible permissions
sudo umount /run/media/kwame/RHEL-9-7-0-BaseOS-x86_64
sudo mkdir -p /mnt/iso
sudo mount -o loop,ro /dev/sr1 /mnt/iso

### Define both repos
sudo tee /etc/yum.repos.d/local.repo > /dev/null << 'EOF'
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/iso/BaseOS
enabled=1
gpgcheck=0

[local-appstream]
name=Local AppStream
baseurl=file:///mnt/iso/AppStream
enabled=1
gpgcheck=0
EOF

### Verify
sudo dnf clean all
sudo dnf repolist

### Prove ( isolation test, subscription repos disabled entirely)
sudo dnf --disablerepo="*" --enablerepo="local-appstream" install httpd -y

## Why these choices
Both BaseOS and AppStream are configured because RHEL 9 content is split
across the two  BaseOS holds the core OS, AppStream holds most
applications (including httpd). Configuring only one leaves half of all
installable packages unavailable.

gpgcheck=0 is used because packages from a local ISO cannot be verified
against Red Hat's online signing keys without extra setup; on an exam or
offline system this is the expected default unless a GPG key is provided.

The repo was pointed at a manually created mount under /mnt/iso instead of
the desktop's automatic mount under /run/media, because of a real
permissions problem found while debugging — see What went wrong.

## Verification
sudo dnf repolist
repo id                          repo name
local-appstream                  Local AppStream
local-baseos                     Local BaseOS
rhel-9-for-x86_64-appstream-rpms Red Hat Enterprise Linux 9 for x86_64 - AppStream (RPMs)
rhel-9-for-x86_64-baseos-rpms    Red Hat Enterprise Linux 9 for x86_64 - BaseOS (RPMs)

sudo dnf --disablerepo="*" --enablerepo="local-appstream" install httpd -y
Installing:
 httpd    x86_64    2.4.62-7.el9    local-appstream    46 k
(...11 packages total, all from local-appstream, dependencies resolved)
Complete!

## What went wrong
My first repo file failed to load entirely, with only a generic
"Warning: failed loading '/etc/yum.repos.d/local.repo', skipping." I
checked the file with `cat -A` for hidden characters (a real possibility
after editing on a mobile terminal) — the file was clean, no carriage
returns, valid syntax.

`dnf repolist -v` gave no further detail, so I checked the mount itself
that the repo pointed at:

    mount | grep RHEL-9-7-0-BaseOS
    ... dmode=500,fmode=400,uid=1000,gid=1000 ...

The ISO was auto-mounted by udisks2 under /run/media/kwame with
dmode=500 (directories: owner-only, r-x------) and fmode=400 (files:
owner-only, r--------). dnf runs as root, but root was not the owner
(uid=1000, my user, was)  so root had zero access to even enter the
directories, let alone read repodata/. This is a sensible default for a
desktop session browsing their own media, but it silently blocks any
root-run service from reading the same mount.

The fix was to unmount the auto-mount and manually mount the same device
at /mnt/iso, which uses normal permissions (root-owned, 0755) instead of
the restrictive desktop defaults. Repointing the repo file at /mnt/iso
fixed it immediately.

Lesson: a repo baseurl can be perfectly correct and still fail if the
underlying mount's permissions block the user actually reading it dnf's
generic "failed loading" error does not distinguish a syntax problem from
a permissions problem, so checking the mount options directly was
necessary to find the real cause.
