# 03 — Firewall

## What was configured
In this stage I configured the firewall to allow only ssh, http, and https, permanently, and reloaded afterwards so the rules took effect immediately. Default services that were not needed (cockpit, dhcpv6-client) were removed.

## Commands
sudo firewall-cmd --add-service=http --permanent 
sudo firewall-cmd --add-service=https --permanent 
sudo firewall-cmd --add-service=ssh --permanent

sudo firewall-cmd --reload 
sudo firewall-cmd --list-all

## Why these choices

why only these three services (minimal attack surface: ssh for administration, http/https because Stage 6 serves web content everything else has no reason to listen). 
Why did i remove the defaults (a baseline should allow only what it needs unexamined defaults are unowned risk).

## Verification
sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens160
  sources: 
  services: cockpit dhcpv6-client http https ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 


## What went wrong
