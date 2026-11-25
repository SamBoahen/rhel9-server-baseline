# RHEL 9 Server Baseline

**RHCSA certified (October 2026)**

A documented, security-hardened RHEL 9 server, built in 8 stages and checked
by a verification script. Every stage doc includes the commands used, the
reasoning behind each choice, and the real problems that came up along the way.

**v2 (November 2026)** is a complete rebuild on a fresh VM. Each stage was
rebuilt from its own documentation, the docs were corrected wherever they were
wrong, and every stage is now covered by automated checks. The original
version is kept as the [`v1.0` tag](../../tree/v1.0).

## Stages

| # | Stage | Doc |
|---|-------|-----|
| 1 | Users, groups & sudo | [docs/01-users-access.md](docs/01-users-access.md) |
| 2 | SSH hardening (drop-in config) | [docs/02-ssh-hardening.md](docs/02-ssh-hardening.md) |
| 3 | Firewall (firewalld) | [docs/03-firewall.md](docs/03-firewall.md) |
| 4 | SELinux | [docs/04-selinux.md](docs/04-selinux.md) |
| 5 | Storage (LVM, mount by label, swap) | [docs/05-storage.md](docs/05-storage.md) |
| 6 | Rootless web container (Podman + Quadlet) | [docs/06-web-container.md](docs/06-web-container.md) |
| 7 | Persistent logging (journald + rsyslog) | [docs/07-logging.md](docs/07-logging.md) |
| 8 | Local DNF repository (with GPG checking) | [docs/08-local-repo.md](docs/08-local-repo.md) |

## Verifying

```bash
sudo ./scripts/verify.sh
```

Runs read-only checks for every stage, prints PASS or FAIL per check, and
exits `0` only if everything passes. It needs root, because some checks
(sudoers syntax, the effective sshd config) can only be read by root.

```
PASS: user sysadmin exists
PASS: user sysadmin has UID 3001
...
PASS: repo local-appstream is enabled
Result: 25/25 checks passed
```

Every check was written **before** its stage was built and confirmed to FAIL
first, so a PASS means the stage's change is really in place, not just that
RHEL's defaults happen to match.

## Highlights from the rebuild

- **A check caught a real misconfiguration:** two sudoers drop-ins had the wrong permissions (`0640` instead of `0440`). `visudo -c` in the script flagged both.
- **A check that failed at random:** `grep -q` after a pipe, combined with `set -o pipefail`, caused occasional false FAILs. `grep -q` exits as soon as it finds a match, the command feeding it gets a "broken pipe" error, and `pipefail` reports the whole pipeline as failed. Fixed by letting `grep` read all input.
- **Rootless container started at boot without a login**, using lingering and a Quadlet unit ([Stage 6](docs/06-web-container.md)).

## Repository layout

```
configs/   the real configuration files used on the server
docs/      one document per stage
scripts/   verify.sh
```

## Environment

RHEL 9.7 VM on VMware Workstation, built as a learning lab during and after
RHCSA (EX200) preparation. Mistakes and fixes are documented honestly in each
stage rather than only showing the clean result.
