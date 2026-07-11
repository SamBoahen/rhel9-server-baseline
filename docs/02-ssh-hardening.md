*IP addresses partially redacted for security reasons.*

## What was configured
I configured key-based SSH authentication for the baseline server and then
hardened its SSH daemon: root login disabled, password authentication
disabled, and a maximum of 3 authentication attempts per connection.
The key was generated on my client VM and installed onto the baseline
server, so that I could log in with the key before disabling passwords.

## Commands

### On the client VM — generate a key and install it on the server
ssh-keygen -t ed25519
ssh-copy-id kwame@192.168.134.XXX

### Test the key login before hardening anything
ssh kwame@192.168.134.XXX

### On the baseline server — edit the SSH daemon configuration
sudo vim /etc/ssh/sshd_config
    PermitRootLogin no
    MaxAuthTries 3
    PasswordAuthentication no

### Test the configuration for errors BEFORE restarting
sudo sshd -t

### Restart the service
sudo systemctl restart sshd

## Why these choices
I generated the key and tested it on the server BEFORE editing sshd_config,
because a wrong SSH configuration can lock me out of the server permanently.
The key must be tested on the machine being hardened — the public key
travels from the client to the server, and the server holds it in
authorized_keys.
Running `sshd -t` before restarting is the same idea as visudo for sudoers:
it checks the syntax first, so a broken configuration never goes live.

## Verification
sudo cat /etc/ssh/sshd_config | grep -Ei 'PermitRootLogin|MaxAuthTries|PasswordAuthentication'
PermitRootLogin no
MaxAuthTries 3
PasswordAuthentication no

# Key-based login succeeds (from the client):
ssh kwame@192.168.134.XXX
Last login: Fri Jul 10 00:53:14 2026
[kwame@obibinii ~]$

# Password login is refused (from the client):
ssh -o PubkeyAuthentication=no kwame@192.168.134.XXX
kwame@192.168.134.XXX: Permission denied (publickey,gssapi-keyex,gssapi-with-mic)

sudo systemctl status sshd
Active: active (running)

## What went wrong
Two real incidents in this stage:

1. **I hardened the server before its lock had any keys.** I generated the
key on the server and copied it TO my client — the wrong direction. When I
then disabled password authentication, nobody could SSH into the server at
all, because its authorized_keys was empty. I was only saved by being
logged in at the console. Lesson: the server holds the lock, the client
holds the key — `ssh-copy-id user@SERVER` runs on the client, pointed at
the machine being hardened, and the key login must be proven BEFORE
passwords are disabled.

2. **I overwrote my GitHub SSH key.** When ssh-keygen said the key already
exists, I answered "y" — which silently replaced the key that GitHub knew
about, so git push would have failed. I had to register the new public key
with GitHub. Lesson: when a key already exists, either reuse it or generate
to a different filename with -f; never overwrite without knowing what the
old key was registered with.

Also, when testing with `sshd -t` I forgot sudo at first and got
"Permission denied" — the command reads the SSH host keys, which
requires root.
