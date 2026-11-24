# 05 — Storage

## Goal

- Volume group `vg_web` with a physical extent size of 8 MiB
- Logical volume `lv_web`: 50 extents (400 MiB), XFS, label `WEBDATA`, mounted at `/srv/web` at boot by its label
- Logical volume `lv_swap`: 512 MiB, active as swap at boot
- `/srv/web` keeps the SELinux label from Stage 4

## Commands

### Partition the disk

```bash
lsblk
sudo gdisk /dev/nvme0n3        # n, default start, +2G, type 8300, w
sudo partprobe /dev/nvme0n3
```

### LVM

```bash
sudo pvcreate /dev/nvme0n3p1
sudo vgcreate -s 8M vg_web /dev/nvme0n3p1
sudo lvcreate -l 50 -n lv_web vg_web
sudo lvcreate -L 512M -n lv_swap vg_web
```

### Filesystem and swap

```bash
sudo mkfs.xfs -L WEBDATA /dev/vg_web/lv_web
sudo mkswap /dev/vg_web/lv_swap
```

### Persistent mounts (`/etc/fstab`)

```
LABEL=WEBDATA          /srv/web  xfs   defaults  0 0
/dev/vg_web/lv_swap    none      swap  defaults  0 0
```

```bash
sudo systemctl daemon-reload
sudo mount -a
sudo swapon -a
```

### Restore the SELinux label

```bash
sudo restorecon -Rv /srv/web
```

## Why these choices

- **Mount by label:** device names like `nvme0n3` can change between boots or when disks are added; a filesystem label stays with the filesystem.
- **Swap by LV path:** `/dev/vg_web/lv_swap` is stable, and unlike a UUID it doesn't change if the swap area is recreated.
- **`mount -a` before rebooting:** a broken fstab line shows up immediately instead of stopping the next boot.
- **`restorecon` after mounting:** a new filesystem mounted over `/srv/web` hides the labelled directory underneath and starts out unlabelled (`unlabeled_t`). The Stage 4 rule only takes effect once `restorecon` applies it.

## Incidents

- **Raw `blkid` output in fstab:** piping `blkid` into `tee -a /etc/fstab` added lines like `/dev/vg_web/lv_web: LABEL="WEBDATA" ...`, which isn't fstab format and could stop the boot. Removed and replaced with proper entries.
- **Swap UUID changed:** running `mkswap` a second time created a new UUID, so an fstab entry with the old UUID would have pointed at nothing. Switched to the LV path.
- **Quoted label:** `LABEL="WEBDATA"` mounts fine, but didn't match the expected fstab entry in `verify.sh`. Changed to the usual unquoted form.
- **Stale LVM device entry:** an earlier `pvcreate` on the whole disk left `/dev/nvme0n3` in LVM's devices file, next to the partition actually used. Removed with `lvmdevices --deldev /dev/nvme0n3`.

## Verification

After a reboot:

```
$ findmnt /srv/web
TARGET   SOURCE                    FSTYPE
/srv/web /dev/mapper/vg_web-lv_web xfs

$ ls -ldZ /srv/web
... system_u:object_r:container_file_t:s0 ... /srv/web
```

```
$ sudo ./scripts/verify.sh
...
PASS: /srv/web is mounted
PASS: lv_web has filesystem label WEBDATA
PASS: fstab mounts /srv/web by label
Result: 17/17 checks passed
```

## Changes from v1

- Names changed to `vg_web` / `lv_web`, and the label to `WEBDATA`
- Extent size set to 8 MiB, with a 50-extent LV
- Added a swap LV
