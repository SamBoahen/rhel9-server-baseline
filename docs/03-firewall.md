# 03 — Firewall

## Goal

- firewalld is active and enabled at boot
- The default zone allows only the `ssh` service and port `8080/tcp`
- All rules are permanent and survive a reboot

## Commands

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

`ssh` is allowed by default in the `public` zone, so it only needs to stay.

## Why these choices

- **Minimal attack surface:** `ssh` for administration and `8080/tcp` for the web container in Stage 6. Nothing else has a reason to be reachable.
- **Port 8080 instead of the `http` service (80):** the container in Stage 6 runs rootless, and an unprivileged user can't bind ports below 1024.
- **Removing the defaults:** cockpit and dhcpv6-client are enabled out of the box, but this server doesn't use them. A baseline should allow only what it needs.
- **`--permanent` + `--reload`:** `--permanent` saves the rule; `--reload` applies the saved config to the running firewall. Using `--permanent` alone means nothing changes until the next reload or reboot.

## Incident: leftover ports from earlier builds

The rebuild found `22222/tcp` still open from an earlier SSH port change, and later a duplicate `22/tcp` that the `ssh` service already covers. Both were removed, so the zone lists only what the goal describes.

## Verification

```
$ sudo firewall-cmd --list-all
public (active)
  ...
  services: ssh
  ports: 8080/tcp
  ...
```

```
$ sudo ./scripts/verify.sh
...
PASS: firewall allows 8080/tcp permanently
PASS: firewall no longer allows cockpit
Result: 12/12 checks passed
```

## Changes from v1

- v1 allowed `http` and `https`; v2 opens `8080/tcp` for the rootless container
- v1's verification output still showed cockpit and dhcpv6-client, despite the text saying they were removed. v2 actually removes them.
