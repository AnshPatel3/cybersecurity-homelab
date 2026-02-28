# Phase 1 Build Checklist — SOC Foundation
**Weeks 1–4 · Prerequisite: Pre-build complete (Tailscale up on all 3 nodes, PBS working)**

Mark each item `[x]` when complete. Do not start Phase 2 until every item in this file is checked.

---

## Pre-Phase 1 Verification

- [ ] Tailscale running on Node 1 host: `tailscale status`
- [ ] Tailscale running on Node 2 host: `tailscale status`
- [ ] Tailscale running on Node 3 host: `tailscale status`
- [ ] All three nodes can ping each other via Tailscale
- [ ] PBS accessible at `https://PBS_TS_IP:8007`
- [ ] Backup jobs created with vm100 and vm101 excluded
- [ ] vmbr1 and vmbr2 created on Node 1 and Node 2

---

## vm102 — OPNsense

- [ ] VM created (ID 102, i440fx, SeaBIOS, VirtIO disk, 2GB RAM, RAM ballooning OFF)
- [ ] Three NICs added: vmbr0 (WAN), vmbr1 (LAN), vmbr2 (OPT1)
- [ ] OPNsense installed and booted
- [ ] Interfaces assigned: vtnet0=WAN, vtnet1=LAN, vtnet2=OPT1
- [ ] LAN IP set: 10.10.20.1/24, DHCP 10.10.20.100-200
- [ ] OPT1 IP set: 10.10.50.1/24, DHCP 10.10.50.100-200
- [ ] OPT1 interface enabled in GUI as "ATTACK"
- [ ] **CRITICAL RULE ADDED: ATTACK → LAN block rule (first rule on ATTACK tab)**
- [ ] Suricata IDS/IPS enabled on LAN and ATTACK interfaces
- [ ] ET/Open rules downloaded
- [ ] Syslog target added: UDP, 10.10.20.10:514
- [ ] Test: `ping 8.8.8.8` from OPNsense console succeeds
- [ ] Test: DHCP works (VM on vmbr1 gets 10.10.20.100+)
- [ ] Test: VLAN isolation — VM on vmbr2 CANNOT ping 10.10.20.1
- [ ] Boot order set: Order 1, Up Delay 30s, Start at Boot YES

---

## vm103 — Wazuh SIEM

- [ ] VM created (ID 103, Ubuntu 24.04 LTS, 8GB RAM, 120GB disk)
- [ ] Static IP set during install: 10.10.20.10/24, GW 10.10.20.1
- [ ] qemu-guest-agent installed and enabled
- [ ] Wazuh all-in-one install complete (check current URL at docs.wazuh.com)
- [ ] Passwords saved from `wazuh-install-files.tar`
- [ ] All three services enabled: `wazuh-manager wazuh-indexer wazuh-dashboard`
- [ ] Dashboard accessible at `https://10.10.20.10`
- [ ] Syslog receiver added to ossec.conf (port 514 UDP, allowed-ips 10.10.20.1)
- [ ] `sudo ss -ulnp | grep 514` confirms port is open
- [ ] OPNsense events appear in Wazuh Discover (filter: agent.name:opnsense)
- [ ] Boot order set: Order 3, Up Delay 60s, Start at Boot YES

---

## vm104 — Domain Controller

- [ ] VM created (ID 104, q35, OVMF UEFI, TPM v2.0, EFI disk, Win Server 2022 Eval)
- [ ] VirtIO SCSI driver loaded during install (vioscsi → w2k22 → amd64)
- [ ] qemu-ga-x86_64.msi installed (Proxmox guest agent)
- [ ] netkvm.inf installed (network adapter)
- [ ] Static IP: 10.10.20.20/24, GW 10.10.20.1, DNS 127.0.0.1
- [ ] AD DS promoted, new forest: lab.local
- [ ] DSRM password recorded
- [ ] Advanced audit policy configured (8 categories)
- [ ] Test users created: alice (IT_Admins), bob (HR_Staff)
- [ ] NTP configured: pool.ntp.org
- [ ] Boot order: Order 2, Up Delay 45s, Start at Boot YES

---

## vm105 — Windows 11 Lab Endpoint

- [ ] VM created (ID 105, q35, OVMF UEFI, TPM v2.0, VirtIO SCSI)
- [ ] VirtIO drivers installed (same process as dc01)
- [ ] Static IP: 10.10.20.30/24, GW 10.10.20.1, DNS 10.10.20.20
- [ ] Joined to lab.local domain
- [ ] Sysmon installed with SwiftOnSecurity config
- [ ] Wazuh agent installed and running, manager: 10.10.20.10
- [ ] ossec.conf updated with Sysmon, Security, System localfile entries
- [ ] Agent shows Active in Wazuh dashboard
- [ ] Boot order: Order 6, Up Delay 20s, Start at Boot YES

---

## vm300 — Remote Sensor (Node 3)

- [ ] VM created on Node 3 via Tailscale: `https://NODE3_TS_IP:8006`
- [ ] Ubuntu 24.04 installed, static IP 10.0.0.20/24 on friend's network
- [ ] Tailscale installed inside vm300: `tailscale up`
- [ ] Authenticated to same Tailscale account
- [ ] Sensor Tailscale IP recorded as `SENSOR_TS_IP`
- [ ] Wazuh agent installed, manager set to `NODE1_TS_IP` (Tailscale IP — NOT 10.10.20.10)
- [ ] Wazuh agent shows Active in dashboard
- [ ] Suricata installed and running
- [ ] eve.json forwarded via Wazuh agent localfile config
- [ ] Boot order: Order 1, Up Delay 30s, Start at Boot YES

---

## lxc350 — AdGuard Home (Node 3)

- [ ] LXC created on Node 3 (ID 350, ubuntu-22.04, 512MB RAM)
- [ ] Static IP: 10.0.0.21/24 on friend's network
- [ ] AdGuard Home installed and configured
- [ ] DNS port 53 operational
- [ ] Boot order: Order 2, Up Delay 20s, Start at Boot YES

---

## lxc351 — Proxmox Backup Server (Node 3)

- [ ] LXC created on Node 3 (ID 351, 2GB RAM, 100GB disk)
- [ ] Tailscale installed inside LXC, authenticated, PBS_TS_IP recorded
- [ ] PBS installed and `lab-backup` datastore created at `/mnt/lab-backup`
- [ ] TLS fingerprint saved
- [ ] PBS GUI accessible: `https://PBS_TS_IP:8007`
- [ ] PBS registered on Node 1 as storage `pbs-offsite` using PBS_TS_IP
- [ ] PBS registered on Node 2 as storage `pbs-offsite` using PBS_TS_IP
- [ ] Node 1 backup job: weekly, exclude 100, snapshot mode, ZSTD
- [ ] Node 2 backup job: weekly, exclude 101, snapshot mode, ZSTD
- [ ] Manual backup test: vm103 → pbs-offsite → verify in PBS GUI
- [ ] Boot order: Order 3, Up Delay 20s, Start at Boot YES

---

## Custom Detection Rules

- [ ] `/var/ossec/etc/rules/local_rules.xml` created with rules 100001–100005
- [ ] `systemctl restart wazuh-manager` — no errors in ossec.log
- [ ] Rule 100001 tested: RDP brute force fires at level 12
- [ ] Rule 100002 tested: User added to Administrators fires at level 14
- [ ] Rule 100003 tested: PowerShell encoded command fires at level 13
- [ ] Rule 100004 tested: Suricata high severity fires at level 14
- [ ] Rule 100005 tested: New service installed fires at level 11

---

## Phase 1 Done When

- [ ] 5+ agents showing Active in Wazuh dashboard
- [ ] All 5 custom rules have produced at least one real triggered alert
- [ ] OPNsense syslog events appear in Wazuh Discover with parsed fields
- [ ] sensor-remote (vm300) shows Active, connected via Tailscale
- [ ] Manual PBS backup completed for all Phase 1 VMs
- [ ] Screenshot evidence saved to `screenshots/phase1/`
