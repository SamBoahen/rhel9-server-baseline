# 07 — Logging

## What was configured
Persistent systemd journal storage was enabled, and a disk-usage cap was
set so the journal cannot grow unbounded.

## Commands

### Enable persistent storage
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald

### Cap journal disk usage
sudo vim /etc/systemd/journald.conf
    SystemMaxUse=1000M
sudo systemctl restart systemd-journald

## Why these choices
On boot, journald looks for the directory /var/log/journal. If it does not exist, it stores log data in RAM at /run/log/journal/. Because /run is a temporary file system (tmpfs), all logs are lost on reboot.
If a service crashes or your system experiences a brute-force attack, journald will write log entries at a massive rate.
Without explicit caps (SystemMaxUse), the journal will greedily consume gigabytes of storage in minutes or hours.

## Verification
sudo systemctl status systemd-journald
● systemd-journald.service - Journal Service
     Loaded: loaded (/usr/lib/systemd/system/systemd-journald.service; static)
     Active: active (running) since Tue 2026-07-21 20:45:13 CEST; 47s ago
TriggeredBy: ● systemd-journald.socket
             ● systemd-journald-dev-log.socket
       Docs: man:systemd-journald.service(8)
             man:journald.conf(5)
   Main PID: 14079 (systemd-journal)
     Status: "Processing requests..."
      Tasks: 1 (limit: 80639)
     Memory: 1.6M (peak: 1.9M)
        CPU: 30ms
     CGroup: /system.slice/systemd-journald.service
             └─14079 /usr/lib/systemd/systemd-journald

Jul 21 20:45:13 obibinii systemd-journald[14079]: Journal started
Jul 21 20:45:13 obibinii systemd-journald[14079]: Runtime Journal (/run/log/journal/d9bab


sudo journalctl | grep "stage 7 checkpoint"
Jul 21 20:44:45 obibinii kwame[13943]: rhel9-server-baseline: stage 7 checkpoint

journalctl --disk-usage
Archived and active journals take up 8.0M in the file system.

sudo cat /etc/systemd/journald.conf | grep -i MaxUse
SystemMaxUse=  1000M


sudo journalctl --list-boots
IDX BOOT ID                          FIRST ENTRY                  LAST ENTRY             >
  0 81ea564c31114a2ca883c549c188cf50 Tue 2026-07-21 14:11:06 CEST Tue 2026-07-21 21:01:43


## What went wrong

--list-boots currently shows only one boot (IDX 0), because the VM has not
been rebooted since persistent storage was configured. This is not proof
of failure — it is simply proof there is only one boot to list yet. 
