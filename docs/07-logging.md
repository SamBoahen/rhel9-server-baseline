# 07 — Logging

## Goal

- The systemd journal persists across reboots
- Journal disk usage is capped at 1000M, defined in a drop-in under `/etc/systemd/journald.conf.d/`
- Messages of priority `err` and higher from all facilities are also written to `/var/log/errors.log`

## Commands

### Journal: persistent storage and size cap

```bash
sudo mkdir -p /etc/systemd/journald.conf.d
sudo vim /etc/systemd/journald.conf.d/50-baseline.conf
```

```ini
[Journal]
Storage=persistent
SystemMaxUse=1000M
```

```bash
sudo systemctl restart systemd-journald
sudo journalctl --flush
sudo systemd-tmpfiles --create --prefix /var/log/journal
```

### Errors to a separate file

```bash
sudo vim /etc/rsyslog.d/errors.conf
```

```
*.err    /var/log/errors.log
```

```bash
sudo systemctl restart rsyslog
logger -p user.err "baseline test error"
sudo tail -n 3 /var/log/errors.log
```

`*.err` means every facility, priority `err` and higher.

## Why these choices

- **Persistent storage:** without `/var/log/journal`, journald keeps logs in `/run/log/journal`. `/run` is a tmpfs in RAM, so every log is lost at reboot, including the logs explaining *why* the server went down.
- **A size cap:** a crashing service or a brute-force attack can produce log entries at a huge rate. Without `SystemMaxUse`, the journal can fill the disk.
- **A drop-in instead of editing `journald.conf`:** custom settings stay separate from the vendor file and survive package updates (same idea as Stages 1 and 2).
- **A separate errors file:** a quick place to look for problems with plain `tail`/`grep`, without searching the whole journal.

## Incident: restarting journald doesn't create `/var/log/journal`

After setting `Storage=persistent` and restarting journald, `/var/log/journal` still didn't exist. journald only creates it when it **flushes** the in-memory journal to disk, which normally happens at boot. `journalctl --flush` triggered it straight away; journald's own log confirmed both settings:

```
System Journal (/var/log/journal/...) is 8.0M, max 1000.0M, 992.0M free.
```

The directory had briefly been created by hand with `mkdir`, giving plain `root:root 755` permissions. `systemd-tmpfiles --create --prefix /var/log/journal` restored the correct group (`systemd-journal`) and ACLs, so members of `wheel`/`adm` can read the journal without sudo.

## Verification

After a reboot:

```
$ journalctl --list-boots
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
 -1 49ab008144df4203b88b5653e060d29f Wed 2026-11-25 09:53:46 CET Wed 2026-11-25 10:22:44 CET
  0 7117ace7126f4e26aeadfcc134c03cdc Wed 2026-11-25 10:23:58 CET Wed 2026-11-25 10:25:29 CET
```

Two boots listed: the previous boot's logs survived.

```
$ sudo tail -n 1 /var/log/errors.log
Nov 25 10:17:02 server1 obibiniitakyi[7523]: baseline test error
```

```
$ sudo ./scripts/verify.sh
...
PASS: journal is persistent
PASS: journal size is capped at 1000M
PASS: errors.log exists
Result: 22/22 checks passed
```

## Changes from v1

- Settings moved from `journald.conf` into a drop-in
- `Storage=persistent` set explicitly, instead of relying on the directory existing
- Added the `errors.log` rule with rsyslog
