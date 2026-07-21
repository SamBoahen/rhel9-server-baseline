# 06 — Web Container

## What was configured
A rootless httpd container, running as the websvc service account created
in Stage 1, serving static content from the /srv/web volume created in
Stage 5. The container is configured to start automatically as a systemd
user service under websvc, surviving both logout and reboot.

## Commands

### Give websvc a proper session (nologin accounts need this — see What went wrong)
sudo machinectl shell websvc@ /bin/bash

### Fix ownership so websvc can relabel the volume with :Z
sudo chown -R websvc:websvc /srv/web

### Give websvc a subuid/subgid range (system accounts don't get one by default)
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 websvc
podman system migrate

### Pull the image and run the container (inside the websvc session)
podman pull docker.io/library/httpd
podman inspect httpd | grep -i workingdir
podman run -d --name websvc-httpd -p 8080:80 -v /srv/web:/usr/local/apache2/htdocs:Z httpd

### Enable it as a systemd user service, surviving logout and reboot
loginctl enable-linger websvc
mkdir -p /home/websvc/.config/systemd/user
cd /home/websvc/.config/systemd/user
podman generate systemd --name websvc-httpd --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-websvc-httpd.service
systemctl --user status container-websvc-httpd.service

### Fix content permissions for the container process (see What went wrong)
chmod 644 /srv/web/index.html

## Why these choices
The container runs as websvc, not as sysadmin or root, for separation of
duty: the account that serves web content has no sudo access and cannot
touch anything outside what it owns.

I used machinectl shell instead of su -s /bin/bash to get into websvc,
because websvc is a nologin system account. su -s can start a shell without
setting up a real systemd user session, which left XDG_RUNTIME_DIR missing
and rootless podman unable to start. machinectl shell goes through
systemd-logind properly, so the runtime directory podman needs actually
gets created.

I used loginctl enable-linger websvc so the container keeps running after
the session ends and after a reboot, the same as the rootless container
pattern from earlier stages — just applied to a service account instead of
an interactive user.

## Verification
podman ps
CONTAINER ID  IMAGE                           COMMAND           STATUS        PORTS                 NAMES
af9b8a37bc24  docker.io/library/httpd:latest  httpd-foreground  Up 2 minutes  0.0.0.0:8080->80/tcp  websvc-httpd

systemctl --user status container-websvc-httpd.service
Active: active (running)
Loaded: loaded (...container-websvc-httpd.service; enabled; preset: ...)

curl http://localhost:8080
<h1>It works</h1>

## What went wrong
This stage had three real incidents, each with a different root cause.

**1. No subuid/subgid range for websvc.** The first podman pull failed with
"no subuid ranges found for user websvc" and then a second error unpacking
the image layers. System accounts created with useradd -r do not get an
automatic subuid/subgid allocation the way normal interactive users do,
and rootless podman needs that range to map container UIDs safely. Fixed
with `usermod --add-subuids/--add-subgids` and `podman system migrate` to
rebuild podman's storage against the new mapping.

**2. su -s did not give podman a working session.** Even after fixing the
subuid range, podman still behaved as if no runtime directory existed.
websvc is a nologin account, and su -s /bin/bash can drop into a shell
without going through a full systemd login, so XDG_RUNTIME_DIR was never
set up. Switching to `machinectl shell websvc@ /bin/bash` — which goes
through systemd-logind like a real login — fixed it.

**3. A 403 Forbidden with two independent causes.** Once the container was
running, curl returned 403. I diagnosed this in two separate checks rather
than guessing:
   - `ls -Zd /srv/web` showed `container_file_t`, not the `httpd_sys_content_t`
     I had set in Stage 4. The `:Z` flag on the volume mount relabels the
     host directory for the container at mount time, which overwrites
     whatever fcontext rule was there before. This means the Stage 4
     SELinux labeling work is functionally superseded inside /srv/web —
     worth stating plainly rather than treating as still active.
   - `ls -la /srv/web` showed index.html at mode 640 (rw-r-----), inherited
     from the Stage 1 umask 027 policy on websvc. That mode has no
     permission at all for "other," which is the bucket the container's
     internal process falls into. `chmod 644` fixed it.
   Both had to be checked and ruled in/out separately — the label being
   "wrong" and the file being unreadable were two different problems that
   happened to produce the same symptom.
