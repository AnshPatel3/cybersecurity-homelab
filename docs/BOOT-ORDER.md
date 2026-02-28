# Proxmox Boot Order Reference

Set these in Proxmox GUI: **VM or LXC → Options → Start/Shutdown Order**

Fields: `Order` (startup sequence), `Up Delay` (seconds to wait before starting the next VM in sequence), `Start at Boot` (Yes/No).

---

## Node 1 — SOC Core

| VM / LXC | ID | Order | Up Delay | Start at Boot | Reason |
|----------|----|-------|----------|---------------|--------|
| opnsense | vm102 | 1 | 30s | YES | Firewall first — all VMs need network routing |
| dc01 | vm104 | 2 | 45s | YES | DNS and AD must be up before auth services |
| wazuh | vm103 | 3 | 60s | YES | Indexer is the slowest service in the lab |
| shuffle | vm106 | 4 | 30s | YES | SOAR after SIEM |
| authentik | lxc150 | 5 | 30s | YES | Identity after SOAR |
| win11-lab | vm105 | 6 | 20s | YES | Endpoint last — not critical for other services |
| **vm100 (personal)** | vm100 | — | — | **existing — do not change** | Not part of lab |

---

## Node 2 — Attack Range + AI

| VM / LXC | ID | Order | Up Delay | Start at Boot | Reason |
|----------|----|-------|----------|---------------|--------|
| velociraptor | vm200 | 1 | 30s | YES | Simple startup — first up |
| opencti | vm201 | 2 | 90s | YES | Elasticsearch needs 60-90s before app connects |
| ai-agent | vm202 | 3 | 30s | YES | AI layer last |
| kali | vm203 | — | — | **NO** | Attack VM — manual only |
| caldera | vm204 | — | — | **NO** | Attack sim — manual only |
| targets | vm205 | — | — | **NO** | Target VMs — manual only |
| **vm101 (TrueNAS)** | vm101 | — | — | **existing — do not change** | Not part of lab |

---

## Node 3 — Offsite (Jeenitesh's House)

| VM / LXC | ID | Order | Up Delay | Start at Boot | Reason |
|----------|----|-------|----------|---------------|--------|
| sensor-remote | vm300 | 1 | 30s | YES | Sensor starts → Tailscale reconnects → agent reconnects automatically |
| adguard | lxc350 | 2 | 20s | YES | DNS for Node 3 VMs |
| pbs | lxc351 | 3 | 20s | YES | Backup server should be available whenever Node 3 is up |

---

## Expected Full Cold Boot Timeline

| Time | What is happening |
|------|-------------------|
| 0–30s | Proxmox hosts booting, Tailscale reconnecting |
| 30–90s | OPNsense starting, lab network becoming available |
| 90–150s | dc01 starting, lab.local DNS available |
| 2–5 min | Wazuh starting — Indexer is slow, do not restart it |
| 4–7 min | Shuffle and Authentik containers auto-starting |
| 5–12 min | OpenCTI starting — Elasticsearch takes longest |
| 10–15 min | All services operational, all Wazuh agents Active |
