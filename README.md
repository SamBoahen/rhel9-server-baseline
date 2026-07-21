# RHEL 9 Server Baseline

A documented, security-hardened RHEL 9 server build, created as hands-on
practice while preparing for the RHCSA (EX200) exam. Every stage below
includes the commands used, the reasoning behind each choice, and — where
relevant — a genuine incident that came up during the build and how it was
diagnosed and fixed.

Several stages surfaced real problems worth reading on their own:
SSH was hardened in the wrong direction on the first attempt and had to be
recovered ([Stage 2](docs/02-ssh-hardening.md)); a rootless container
running under a locked-down service account hit three separate low-level
issues — missing subuid/subgid ranges, a broken login session, and a
stacked SELinux/permissions bug behind one HTTP 403
([Stage 6](docs/06-web-container.md)); and a local package repository that
looked syntactically correct failed until the underlying mount's
permission bits were inspected directly ([Stage 8](docs/08-local-repo.md)).

## Stages

| # | Stage | Doc |
|---|-------|-----|
| 1 | Users & access control | [docs/01-users-access.md](docs/01-users-access.md) |
| 2 | SSH hardening | [docs/02-ssh-hardening.md](docs/02-ssh-hardening.md) |
| 3 | Firewall (firewalld) | [docs/03-firewall.md](docs/03-firewall.md) |
| 4 | SELinux | [docs/04-selinux.md](docs/04-selinux.md) |
| 5 | Storage (LVM, mount by label) | [docs/05-storage.md](docs/05-storage.md) |
| 6 | Rootless web container + systemd | [docs/06-web-container.md](docs/06-web-container.md) |
| 7 | Persistent logging | [docs/07-logging.md](docs/07-logging.md) |
| 8 | Local DNF repository | [docs/08-local-repo.md](docs/08-local-repo.md) |

All 8 Stages Complete.

## Verify

    ./scripts/verify.sh

Runs read-only checks against each stage and reports PASS/FAIL.

## Environment

Built on a RHEL 9 VM (VMware), as part of RHCSA (EX200) exam preparation.
This is a learning-lab project — choices, tradeoffs, and mistakes are
documented honestly in each stage doc rather than only showing the clean
final result.
