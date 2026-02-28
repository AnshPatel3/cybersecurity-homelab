# Cold Boot & Recovery Guide

## What Happens Automatically

When power is restored after any outage, **you do not need to do anything**. Proxmox starts VMs in the configured boot order with the configured delays. After 10-15 minutes everything is operational.

---

## Scenario: Home Power Cut (Nodes 1 and 2 offline)

**Node 3 continues running independently:**
- AdGuard serves DNS for Node 3 VMs
- PBS stays accessible via Tailscale
- Sensor vm300 continues running, Wazuh agent queues events locally

**When home power returns:**
- Proxmox boots on Node 1 and 2
- Tailscale reconnects to Node 3 automatically
- All VMs start in boot order sequence
- Wazuh agents reconnect and flush queued events

---

## Scenario: Jeenitesh's Internet Down (Node 3 unreachable)

- Tailscale tunnel drops — Node 3 unreachable from anywhere
- Sensor Wazuh agent queues events locally at `/var/ossec/queue`
- PBS backup jobs fail silently (Proxmox logs the error)
- Nodes 1 and 2 continue running normally

**When Jeenitesh's internet comes back:**
- Tailscale auto-reconnects on both sides (no action needed)
- Wazuh agent re-establishes connection, flushes queued events
- PBS reachable again — next scheduled backup runs normally
- Do NOT force-reconnect Tailscale during the outage

---

## Recovery Quick Reference

| Problem | Cause | Fix |
|---------|-------|-----|
| Wazuh agents Disconnected after reboot | Indexer still initializing | Wait 5 more minutes |
| sensor-remote Disconnected | Tailscale not yet reconnected | `tailscale status` on Node 3 host |
| OpenCTI restart loop | Elasticsearch not ready | `docker compose down` on vm201, staged restart |
| PBS backup failed | Tailscale was down at scheduled time | Run job manually in Proxmox GUI |
| DC01 Kerberos errors | Clock drift during downtime | `w32tm /resync /force` on dc01 |
| Cannot reach Node 3 GUI | Tailscale not reconnected | Ask Jeenitesh to check the machine |

---

## Tailscale Not Reconnecting After 5 Minutes

If Tailscale has not automatically reconnected within 5 minutes of internet restoration:

```bash
# On the affected Proxmox host or LXC:
sudo systemctl restart tailscaled
tailscale status  # should show peers connected
```

---

## Health Check Script

Run `/root/healthcheck.sh` on Node 1 after any restart:

```bash
#!/bin/bash
echo '=== OPNsense ===' && ping -c1 -W2 10.10.20.1 > /dev/null && echo OK || echo FAIL
echo '=== Wazuh ===' && curl -sk https://10.10.20.10 -o /dev/null -w '%{http_code}\n'
echo '=== DC01 DNS ===' && nslookup lab.local 10.10.20.20 2>/dev/null | grep -q Name && echo OK || echo FAIL
echo '=== Shuffle ===' && curl -s http://10.10.20.40:3001 -o /dev/null -w '%{http_code}\n'
echo '=== Authentik ===' && curl -s http://10.10.20.45:9000 -o /dev/null -w '%{http_code}\n'
echo '=== Velociraptor ===' && curl -sk https://10.10.20.50:8889 -o /dev/null -w '%{http_code}\n'
echo '=== OpenCTI ===' && curl -s http://10.10.20.60:8080 -o /dev/null -w '%{http_code}\n'
echo '=== AI Agent ===' && curl -s http://10.10.20.80:3000 -o /dev/null -w '%{http_code}\n'
echo '=== Tailscale to Node 3 ===' && tailscale ping -c1 NODE3_TS_IP 2>/dev/null | grep -q pong && echo OK || echo FAIL
```
