# Phase 1 Screenshots

Add screenshots here as Phase 1 milestones are completed.

## Suggested screenshots to capture

| Filename | What to capture |
|----------|----------------|
| `01-proxmox-nodes.png` | Proxmox dashboard showing all 3 nodes and their VMs |
| `02-opnsense-interfaces.png` | OPNsense interface overview (WAN/LAN/ATTACK with IPs) |
| `03-opnsense-vlan-block.png` | The ATTACK→LAN block rule in Firewall → Rules → ATTACK |
| `04-opnsense-suricata.png` | Suricata listening on both interfaces |
| `05-wazuh-dashboard.png` | Wazuh Dashboard showing active agents |
| `06-wazuh-agents-all.png` | Agents list showing dc01, win11, sensor-remote all Active |
| `07-wazuh-opnsense-events.png` | Discover view with OPNsense syslog events and parsed fields |
| `08-dc01-ad-users.png` | AD Users and Computers showing OU structure, alice, bob |
| `09-sysmon-events.png` | Sysmon events appearing in Wazuh (filter: agent.name:dc01) |
| `10-rule-100001-fired.png` | Custom rule 100001 (RDP brute force) producing an alert |
| `11-rule-100003-fired.png` | Custom rule 100003 (PowerShell encoded command) alert |
| `12-pbs-gui.png` | PBS GUI showing lab-backup datastore with completed backups |
| `13-sensor-tailscale.png` | sensor-remote Active in Wazuh, confirming Tailscale tunnel |
| `14-tailscale-status.png` | tailscale status showing all 5 endpoints connected |
