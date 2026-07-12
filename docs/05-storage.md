# 05 — Storage

## What was configured
In this stage I built a dedicated logical volume for the web content that
the container in Stage 6 will serve. I created a partition, turned it into
a physical volume, created a volume group on it, and then a logical volume.
I refreshed the partition table with partprobe, because the kernel sometimes
does not load a newly created partition on its own. I formatted the LV as
XFS with the label "webdata" and mounted it persistently at /srv/web using
that label in /etc/fstab. Finally — the most important step — I re-ran
restorecon on /srv/web, because mounting a fresh filesystem over the
directory hides the old labeled directory and presents a new, unlabeled one.

## Commands

### Checking all disks
lsblk

### Creating a partition
sudo gdisk /dev/nvme0n2

### Refreshing the partition table
sudo partprobe /dev/nvme0n2

### Creating the PV
sudo pvcreate /dev/nvme0n2p1
sudo pvdisplay /dev/nvme0n2p1

### Creating the VG
sudo vgcreate -s 100 webvg /dev/nvme0n2p1
sudo vgdisplay webvg

### Creating the LV
sudo lvcreate -l 10 -n weblv webvg
sudo lvdisplay /dev/webvg/weblv

### Formatting the LV with a label
sudo mkfs.xfs -L webdata /dev/webvg/weblv

### Mounting the LV
sudo mount -t xfs /dev/webvg/weblv /srv/web/

### Making the mount permanent, by label
sudo vim /etc/fstab
    LABEL=webdata   /srv/web   xfs   defaults   0 2

### Reloading and testing the fstab entry
sudo systemctl daemon-reload
sudo mount -a

### Relabeling /srv/web after the mount
sudo restorecon -Rv /srv/web/

## Why these choices
I used LVM instead of a bare partition because a logical volume can be
extended later without rebuilding anything — if the web content outgrows
1 GB, one lvextend fixes it.

I mounted by label instead of by device path because device names like
/dev/nvme0n2p1 can change; a label follows the filesystem itself.

The restorecon at the end is required because /srv/web already carried its
SELinux label from Stage 4 — but mounting a fresh filesystem over the
directory hides the old directory and presents a brand-new, unlabeled root.
The relabel output proves it: the new filesystem root was unlabeled_t until
restorecon applied the httpd_sys_content_t rule from Stage 4.

## Verification
sudo mount -a
(silent — no errors)

lsblk
nvme0n2         259:4    0    20G  0 disk
└─nvme0n2p1     259:7    0     2G  0 part
  └─webvg-weblv 253:4    0  1000M  0 lvm  /srv/web

sudo cat /etc/fstab | grep webdata
LABEL=webdata         /srv/web                xfs     defaults        0 2

sudo restorecon -Rv /srv/web/
Relabeled /srv/web from system_u:object_r:unlabeled_t:s0
                     to system_u:object_r:httpd_sys_content_t:s0

## What went wrong
I ran vgcreate with -s 100, thinking of it as a small tuning value but a bare number is read as MiB, so I created a volume group with a physical
extent size of 100 MiB (vgdisplay showed only 20 total extents).Nothing
broke, but it means the smallest possible resize step on this VG is now
100 MiB.
 
Lesson: only use -s when a specific PE size is actually required;

I also lost a minute searching the fstab with `grep /Srv` — capital S — and
finding nothing. Case sensitivity.
