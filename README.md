<div align="center">

```
 ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗      █████╗ ██████╗
██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║     ██╔══██╗██╔══██╗
██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝██║     ███████║██████╔╝
██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██║     ██╔══██║██╔══██╗
╚██████╗   ██║   ██████╔╝███████╗██║  ██║███████╗██║  ██║██████╔╝
 ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝
                      H O M E L A B
```

# 🛡️ Cybersecurity Homelab
### A 3-Node Proxmox SOC · Purple Team Range · Agentic AI Triage System

[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow?style=flat-square&logo=proxmox)](.)
[![Phase](https://img.shields.io/badge/Current%20Phase-Pre--Build-blue?style=flat-square)](.)
[![Nodes](https://img.shields.io/badge/Nodes-3%20Proxmox%20Hosts-orange?style=flat-square)](.)
[![Tailscale](https://img.shields.io/badge/Network-Tailscale%20WireGuard-brightgreen?style=flat-square)](.)
[![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](LICENSE)

</div>

---

## 👥 Project Team

| | Name | Role | Node |
|---|---|---|---|
| 🧠 | **Ansh Patel** | Project Lead · SOC Architect · Primary Builder | Node 1 & 2 (Home) |
| 🤝 | **Jeenitesh Nandwani** | Infrastructure Partner · Node 3 Host | Node 3 (Remote) |

> **Jeenitesh** is hosting Node 3 at his house, providing the offsite infrastructure that makes this a genuinely distributed, real-world SOC topology. Node 3 runs the Proxmox Backup Server and remote sensor — accessible by Ansh exclusively via Tailscale.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Hardware](#-hardware)
- [Network Architecture](#-network-architecture)
- [VM & Container Map](#-vm--container-map)
- [Project Phases](#-project-phases)
- [Repository Structure](#-repository-structure)
- [Screenshots](#-screenshots)
- [Tools & Technologies](#-tools--technologies)
- [Progress Log](#-progress-log)

---

## 🎯 Project Overview

This is a **production-grade cybersecurity homelab** built across three physical Proxmox servers. The goal is to build, break, and learn every layer of a modern Security Operations Centre — from raw log ingestion through automated response, threat intelligence, DFIR, adversary simulation, and ultimately an AI agent that autonomously triages security alerts.

**What makes this different from a typical homelab:**

- **Real distributed topology** — Node 3 is physically at a different house. Tailscale WireGuard connects everything. Node 3 is managed 100% remotely — no physical access.
- **Offsite backups** — Node 3 runs Proxmox Backup Server. All backups travel encrypted over Tailscale. A fire at home can't take out both the lab and its backups.
- **No cloud shortcuts** — every service is self-hosted and self-managed.
- **Purple team from day one** — the attack range (VLAN 50) is isolated from the SOC (VLAN 20) at the firewall before a single attack VM is ever started.
- **Agentic AI layer** — Phase 4 replaces manual triage with a LangChain agent that autonomously investigates Wazuh alerts using Velociraptor, OpenCTI, and VirusTotal.

---

## 💻 Hardware

| Node | Location | Host | RAM | Storage | Network | Role |
|------|----------|------|-----|---------|---------|------|
| **Node 1** | Ansh's Home | Proxmox 8.x | 24 GB | 512 GB SSD | `192.168.1.x` | SOC Core — always on |
| **Node 2** | Ansh's Home | Proxmox 8.x | 32 GB | 1 TB HDD | `192.168.1.x` | Attack Range + AI — always on |
| **Node 3** | Jeenitesh's House | Proxmox 8.x | 24 GB | 512 GB SSD | `10.0.0.x` | Remote Backup + Sensor |

> ⚠️ **Protected VMs (never modified by lab procedures)**
> - `vm100` on Node 1 — Ansh's personal Windows 11 (college use)
> - `vm101` on Node 2 — TrueNAS NAS server (ZFS pool on 1TB HDD)
>
> All backup jobs explicitly exclude IDs `100` and `101`.

---

## 🌐 Network Architecture

### Physical Topology

```
                          ┌─────────────────────────────┐
                          │          INTERNET            │
                          └──────────┬──────────┬────────┘
                                     │          │
                      ┌──────────────▼──┐   ┌───▼──────────────┐
                      │  Home Router    │   │ Jeenitesh Router  │
                      │  192.168.1.1    │   │    10.0.0.1       │
                      └──────┬──────┬──┘   └────────┬──────────┘
                             │      │               │
                    ┌────────▼─┐  ┌─▼───────┐  ┌───▼──────────┐
                    │  Node 1  │  │  Node 2  │  │    Node 3     │
                    │192.168.  │  │192.168.  │  │   10.0.0.x    │
                    │  1.x     │  │  1.x     │  │ (Jeenitesh's) │
                    └────────┬─┘  └─┬────────┘  └───┬──────────┘
                             │      │               │
                             └──────┴───────────────┘
                                Tailscale WireGuard
                              (100.x.x.x on all nodes)
```

### Logical Lab Network (Inside Proxmox)

```
                    ┌─────────────────────────────────────────────┐
                    │             OPNsense vm102 (Node 1)          │
                    │  WAN: 192.168.1.x (home router DHCP)        │
                    │  LAN: 10.10.20.1/24  (SOC fabric - vmbr1)   │
                    │  OPT1: 10.10.50.1/24 (attack range - vmbr2) │
                    │  Suricata IDS/IPS · REST API · SOAR block   │
                    │  🛑 RULE: VLAN50 → VLAN20 BLOCKED           │
                    └──────────┬─────────────┬─────────────────────┘
                               │             │
               ┌───────────────▼──┐   ┌──────▼──────────────────┐
               │  VLAN 20 - SOC   │   │   VLAN 50 - Attack Range │
               │  10.10.20.0/24   │   │   10.10.50.0/24          │
               │  vmbr1 (virtual) │   │   vmbr2 (virtual)        │
               └───────────────┬──┘   └──────┬──────────────────┘
                               │              │
          ┌────────────────────┤              ├──────────────┐
          │   NODE 1 (SOC)     │              │  NODE 2 ATK  │
          │  vm103 wazuh       │              │  vm203 kali  │
          │  vm104 dc01        │              │  vm205 tgts  │
          │  vm105 win11       │              │              │
          │  vm106 shuffle     │              └──────────────┘
          │  lxc150 authentik  │
          │                    │
          │   NODE 2 (DFIR+AI) │
          │  vm200 velociraptor│
          │  vm201 opencti     │
          │  vm202 ai-agent    │
          │  vm204 caldera     │
          └────────────────────┘
```

### Remote Node 3 (Jeenitesh's House) via Tailscale

```
  ┌─────────────────────────────────────────────────────────────────┐
  │  NODE 3  —  10.0.0.x physical  +  100.x.x.x Tailscale          │
  │  No physical access  ·  100% remote management via Tailscale    │
  │                                                                  │
  │  vm300  sensor-remote    10.0.0.20  +  own Tailscale IP         │
  │  └─ Wazuh agent  →  NODE1_TAILSCALE_IP:1514 (NOT 10.10.20.10)  │
  │  └─ Suricata eve.json forwarded to Wazuh                        │
  │                                                                  │
  │  lxc350  adguard         10.0.0.21  ·  DNS filter for Node 3    │
  │                                                                  │
  │  lxc351  pbs             10.0.0.50  +  own Tailscale IP         │
  │  └─ Receives backups from Node 1 + Node 2 via Tailscale         │
  │  └─ GUI: https://PBS_TAILSCALE_IP:8007                          │
  │  └─ lab-backup datastore  ·  100 GB  ·  ZSTD  ·  keep-last 3  │
  └─────────────────────────────────────────────────────────────────┘
```

### Tailscale Backbone

```
  ┌──────────────────────────────────────────────────────────────┐
  │  🔐  TAILSCALE WIREGUARD OVERLAY  —  5 ENDPOINTS            │
  │                                                              │
  │  Node 1 Proxmox host  →  100.x.x.x   (NODE1_TS_IP)         │
  │  Node 2 Proxmox host  →  100.x.x.x   (NODE2_TS_IP)         │
  │  Node 3 Proxmox host  →  100.x.x.x   (NODE3_TS_IP)         │
  │  PBS lxc351           →  100.x.x.x   (PBS_TS_IP)           │
  │  Sensor vm300         →  100.x.x.x   (SENSOR_TS_IP)        │
  │                                                              │
  │  Cross-site traffic encrypted · No port forwarding needed   │
  │  Auto-reconnects after any power cut or internet outage     │
  └──────────────────────────────────────────────────────────────┘
```

### IP Address Map

| Component | VM/LXC ID | Node | Internal Lab IP | Tailscale IP | Web UI |
|-----------|-----------|------|-----------------|--------------|--------|
| **opnsense** | vm102 | 1 | `10.10.20.1` / `10.10.50.1` | — | `https://10.10.20.1` |
| **wazuh** | vm103 | 1 | `10.10.20.10` | — | `https://10.10.20.10` |
| **dc01** | vm104 | 1 | `10.10.20.20` | — | RDP |
| **win11-lab** | vm105 | 1 | `10.10.20.30` | — | RDP |
| **shuffle** | vm106 | 1 | `10.10.20.40` | — | `http://10.10.20.40:3001` |
| **authentik** | lxc150 | 1 | `10.10.20.45` | — | `http://10.10.20.45:9000` |
| **velociraptor** | vm200 | 2 | `10.10.20.50` | — | `https://10.10.20.50:8889` |
| **opencti** | vm201 | 2 | `10.10.20.60` | — | `http://10.10.20.60:8080` |
| **ai-agent** | vm202 | 2 | `10.10.20.80` | — | `http://10.10.20.80:3000` |
| **kali** | vm203 | 2 | `10.10.50.10` | — | manual only |
| **caldera** | vm204 | 2 | `10.10.20.70` | — | `http://10.10.20.70:8888` |
| **targets** | vm205 | 2 | `10.10.50.20` | — | manual only |
| **sensor-remote** | vm300 | 3 | `10.0.0.20` | `SENSOR_TS_IP` | SSH via Tailscale |
| **adguard** | lxc350 | 3 | `10.0.0.21` | — | `http://10.0.0.21:3000` |
| **pbs** | lxc351 | 3 | `10.0.0.50` | `PBS_TS_IP` | `https://PBS_TS_IP:8007` |

> **Why `10.10.20.x` and not `10.0.20.x`?**
> Node 3 is on a `10.0.0.x` physical network. Using `10.0.20.x` for the lab VLAN creates routing conflicts through the Tailscale tunnel — packets meant for lab VMs could be misrouted toward Jeenitesh's physical network. The `10.10.x.x` range avoids all conflicts.

---

## 📦 VM & Container Map

### Node 1 — SOC Core (24 GB RAM / 512 GB SSD)

```
┌─────────────────────────────────────────────────────────────────┐
│  NODE 1  ·  192.168.1.x  ·  ALL ALWAYS-ON                      │
│                                                                  │
│  ⛔  vm100  Personal Win11 (college)     EXCLUDED — DO NOT TOUCH│
│                                                                  │
│  Phase 1 ──────────────────────────────────────────────────────│
│  vm102   opnsense         10.10.20.1   2GB  Boot:1/30s         │
│  vm103   wazuh            10.10.20.10  8GB  Boot:3/60s         │
│  vm104   dc01             10.10.20.20  4GB  Boot:2/45s         │
│  vm105   win11-lab        10.10.20.30  4GB  Boot:6/20s         │
│                                                                  │
│  Phase 2 ──────────────────────────────────────────────────────│
│  vm106   shuffle          10.10.20.40  4GB  Boot:4/30s         │
│  lxc150  authentik        10.10.20.45  2GB  Boot:5/30s         │
└─────────────────────────────────────────────────────────────────┘
```

### Node 2 — Attack Range + DFIR + AI (32 GB RAM / 1 TB HDD)

```
┌─────────────────────────────────────────────────────────────────┐
│  NODE 2  ·  192.168.1.x  ·  ALWAYS-ON + ON-DEMAND              │
│                                                                  │
│  ⛔  vm101  TrueNAS NAS (ZFS pool)      EXCLUDED — DO NOT TOUCH │
│                                                                  │
│  Phase 3 — Always-on ──────────────────────────────────────────│
│  vm200   velociraptor     10.10.20.50  3GB  Boot:1/30s         │
│  vm201   opencti          10.10.20.60  4GB  Boot:2/90s  ⚠slow  │
│  vm202   ai-agent         10.10.20.80  8GB  Boot:3/30s         │
│                                                                  │
│  Phase 3 — On-demand ──────────────────────────────────────────│
│  vm203   kali             10.10.50.10  4GB  ⊘ manual           │
│  vm204   caldera          10.10.20.70  3GB  ⊘ manual           │
│  vm205   targets          10.10.50.20  2GB  ⊘ manual           │
└─────────────────────────────────────────────────────────────────┘
```

### Node 3 — Offsite (Jeenitesh's House) (24 GB RAM / 512 GB SSD)

```
┌─────────────────────────────────────────────────────────────────┐
│  NODE 3  ·  10.0.0.x physical  ·  TAILSCALE ONLY MANAGEMENT    │
│  Hosted by: Jeenitesh Nandwani                                  │
│                                                                  │
│  Phase 1 ──────────────────────────────────────────────────────│
│  vm300   sensor-remote    10.0.0.20  4GB   Boot:1/30s          │
│          └─ Wazuh agent reports to NODE1_TS_IP:1514            │
│          └─ Suricata IDS running locally                       │
│                                                                  │
│  lxc350  adguard          10.0.0.21  512MB  Boot:2/20s         │
│  lxc351  pbs              10.0.0.50  2GB    Boot:3/20s         │
│          └─ Own Tailscale IP (PBS_TS_IP)                       │
│          └─ lab-backup datastore (100 GB / ZSTD / keep-last 3) │
│          └─ Backup source: Node 1 pbs-offsite + Node 2         │
│          └─ Excludes vm100 (Node 1) and vm101 (Node 2)         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ Project Phases

### Overview

```
 PHASE 1          PHASE 2          PHASE 3          PHASE 4
 Weeks 1–4        Weeks 5–8        Weeks 9–12       Weeks 13–16
 ──────────       ──────────       ──────────       ──────────
 SOC              SOAR +           Attack +         Agentic
 Foundation       Identity         DFIR +           AI SOC
                                   Threat Intel
 OPNsense         Shuffle          Velociraptor     Ollama
 Wazuh SIEM       Auto-block       OpenCTI          LangChain
 AD + Sysmon      OPNsense API     Kali             Wazuh MCP
 Remote sensor    Authentik SSO    Caldera v5        Flask API
 5 custom rules   MFA policy       Purple team       Auto-triage
```

---

### Phase 1 — SOC Foundation `[Weeks 1–4]`

**Goal:** Every endpoint reporting to Wazuh. OPNsense Suricata alerts parsed. Remote sensor on Node 3 connected via Tailscale. 5 custom detection rules firing real alerts.

| VM | Service | Purpose | Status |
|----|---------|---------|--------|
| vm102 | OPNsense | Firewall / IDS / DHCP / NAT | ⬜ Pending |
| vm103 | Wazuh 4.x | SIEM · Indexer · Dashboard | ⬜ Pending |
| vm104 | Windows Server 2022 | AD DS · DNS (lab.local) | ⬜ Pending |
| vm105 | Windows 11 | Endpoint · Sysmon · Wazuh agent | ⬜ Pending |
| vm300 | Ubuntu 24.04 | Remote sensor (via Tailscale) | ⬜ Pending |
| lxc350 | AdGuard Home | DNS filter for Node 3 | ⬜ Pending |
| lxc351 | Proxmox Backup Server | Offsite backup (via Tailscale) | ⬜ Pending |

**Key configurations:**
- OPNsense VLAN 50 → VLAN 20 block rule (attack cannot reach SOC)
- Sysmon with SwiftOnSecurity config on all Windows VMs
- Wazuh syslog receiver on `0.0.0.0:514/udp` for OPNsense
- Remote sensor Wazuh agent points to `NODE1_TS_IP:1514` (Tailscale — not internal lab IP)
- PBS receives backups from Nodes 1 & 2 over Tailscale tunnel

**Custom Detection Rules (all 5 must fire before Phase 2):**

| Rule ID | Description | MITRE | Level |
|---------|-------------|-------|-------|
| 100001 | RDP brute force — 5+ fails same source IP | T1110.001 | 12 |
| 100002 | User added to local Administrators group | T1136.001 | 14 |
| 100003 | PowerShell encoded command (`-enc`/`-EncodedCommand`) | T1059.001 | 13 |
| 100004 | Suricata high-severity alert (severity 1 or 2) | T1046 | 14 |
| 100005 | New service installed on Windows endpoint (Event 7045) | T1543.003 | 11 |

---

### Phase 2 — SOAR + Identity `[Weeks 5–8]`

**Goal:** Alerts automatically trigger playbooks. OPNsense blocks attacker IPs via REST API. Authentik syncs AD users with MFA enforced for IT_Admins.

| VM | Service | Purpose | Status |
|----|---------|---------|--------|
| vm106 | Shuffle SOAR | Workflow automation | ⬜ Pending |
| lxc150 | Authentik | SSO · LDAP sync · MFA | ⬜ Pending |

**Key configurations:**
- Shuffle `OUTER_HOSTNAME=10.10.20.40` (required — without this webhooks use wrong hostname)
- Docker CE from official repo only (not `apt install docker.io`)
- Authentik in dedicated LXC with `keyctl` and `nesting` enabled
- OPNsense `soar_blocklist` alias + auto-reload via Shuffle HTTP steps

**Automation Playbook (brute force → auto-block):**
```
Wazuh rule 100001 fires
  → Webhook to Shuffle 10.10.20.40:3001
    → Extract src_ip from alert JSON
      → POST https://10.10.20.1/api/firewall/alias/addEntry/soar_blocklist
        → POST https://10.10.20.1/api/firewall/filter/reloadFilter
          → Discord notification
```

---

### Phase 3 — Attack + DFIR + Threat Intel `[Weeks 9–12]`

**Goal:** Full purple team cycle. Caldera runs ATT&CK techniques against win11. Wazuh detection rate measured. Velociraptor hunts validate endpoint forensics. OpenCTI correlates observed TTPs.

| VM | Service | Purpose | Status |
|----|---------|---------|--------|
| vm200 | Velociraptor | DFIR · VQL hunts · live response | ⬜ Pending |
| vm201 | OpenCTI | Threat intel · ATT&CK · OTX | ⬜ Pending |
| vm202 | AI Agent | Ollama + Open WebUI (pre-stage) | ⬜ Pending |
| vm203 | Kali Linux | Red team (vmbr2 only — isolated) | ⬜ Pending |
| vm204 | Caldera v5.0.0 | ATT&CK simulation | ⬜ Pending |
| vm205 | Target VMs | Vulnerable systems (vmbr2) | ⬜ Pending |

> ⚠️ **Caldera must use `--branch 5.0.0`** — main branch breaks on Python 3.12 which Ubuntu 24.04 ships. Python venv required.
>
> ⚠️ **OpenCTI staged startup** — start `redis elasticsearch minio rabbitmq` first, wait 90s, then start `opencti worker`. Starting all simultaneously causes Elasticsearch race condition that looks like random failure.
>
> ⚠️ **Kali gets `vmbr2` ONLY** — never add a vmbr1 NIC to vm203 under any circumstance.

---

### Phase 4 — Agentic AI SOC `[Weeks 13–16]`

**Goal:** LangChain agent autonomously investigates Wazuh alerts using 3 tools (Wazuh REST, VirusTotal, OpenCTI GraphQL). Full loop: alert → Shuffle → Flask API → AI summary → Discord.

| Component | Version | Purpose | Status |
|-----------|---------|---------|--------|
| Ollama | latest | Local LLM server (`qwen2.5:7b`) | ⬜ Pending |
| Open WebUI | latest | Chat interface for Ollama | ⬜ Pending |
| Wazuh MCP | latest | Wazuh API → MCP server bridge | ⬜ Pending |
| LangChain | `0.3.7` (pinned) | Agent framework | ⬜ Pending |
| langchain-ollama | `0.2.0` (pinned) | Ollama integration | ⬜ Pending |
| Flask | `3.0.3` (pinned) | Triage API endpoint | ⬜ Pending |

> ⚠️ **LangChain versions are pinned.** The API changed 3 times in 2024. Unpinned installs silently fail with confusing errors. Use exactly: `langchain==0.3.7 langchain-ollama==0.2.0 langchain-community==0.3.7`

**Agent Tool Chain:**
```
Wazuh alert (level ≥ 5)
  → Shuffle webhook
    → POST to Flask :5000
      → LangChain agent invokes:
          Tool 1: WazuhAlerts  → GET /api/alerts  (JWT auto-refresh every 800s)
          Tool 2: VirusTotal   → GET /vtotal/v3/ip_addresses/{srcip}
          Tool 3: OpenCTI      → GraphQL query → indicators + TTPs
        → LLM (qwen2.5:7b via Ollama) reasons over tool results
          → Structured triage summary returned to Shuffle
            → Discord notification with AI analysis
```

---

## 📁 Repository Structure

```
cybersecurity-homelab/
│
├── README.md                          ← You are here
├── LICENSE
│
├── docs/
│   ├── PHASE1-checklist.md            ← Step-by-step Phase 1 build checklist
│   ├── PHASE2-checklist.md            ← Phase 2 build checklist
│   ├── PHASE3-checklist.md            ← Phase 3 build checklist
│   ├── PHASE4-checklist.md            ← Phase 4 build checklist
│   ├── NETWORK-DECISIONS.md           ← Why key design decisions were made
│   ├── BOOT-ORDER.md                  ← Proxmox start/shutdown order for all nodes
│   ├── COLD-BOOT-RECOVERY.md          ← What to expect and what to do after power cut
│   └── PBS-SETUP.md                   ← Proxmox Backup Server configuration guide
│
├── configs/
│   ├── opnsense/
│   │   ├── suricata-notes.md          ← IDS/IPS interface config notes
│   │   └── firewall-rules.md          ← Key firewall rules (VLAN block, soar_blocklist)
│   ├── wazuh/
│   │   ├── local_rules.xml            ← All 5 custom detection rules
│   │   ├── ossec-syslog.conf          ← OPNsense syslog receiver block
│   │   └── agent-windows.conf         ← Sysmon + Security log localfile config
│   └── caldera/
│       └── setup-notes.md             ← v5.0.0 install with Python venv
│
├── scripts/
│   ├── healthcheck.sh                 ← Post-reboot health check for all services
│   ├── wazuh_auth.py                  ← JWT auto-refresh helper (800s interval)
│   └── tailscale-verify.sh            ← Verify all 5 Tailscale endpoints connected
│
└── screenshots/
    ├── phase1/                        ← Drop screenshots here as Phase 1 completes
    ├── phase2/                        ← Phase 2 screenshots
    ├── phase3/                        ← Phase 3 screenshots
    └── phase4/                        ← Phase 4 screenshots
```

---

## 📸 Screenshots

*Screenshots will be added here as each phase is completed.*

### Phase 1
| Screenshot | Description |
|-----------|-------------|
| `screenshots/phase1/` | *(add as you go)* |

### Phase 2
| Screenshot | Description |
|-----------|-------------|
| `screenshots/phase2/` | *(add as you go)* |

### Phase 3
| Screenshot | Description |
|-----------|-------------|
| `screenshots/phase3/` | *(add as you go)* |

### Phase 4
| Screenshot | Description |
|-----------|-------------|
| `screenshots/phase4/` | *(add as you go)* |

---

## 🛠️ Tools & Technologies

| Category | Technology | Version Policy |
|----------|-----------|----------------|
| **Hypervisor** | Proxmox VE | Latest stable |
| **Firewall** | OPNsense | Latest stable (always latest on install) |
| **SIEM** | Wazuh | Latest stable (check docs.wazuh.com) |
| **SOAR** | Shuffle | Latest (Docker image) |
| **Identity** | Authentik | Latest (Docker image) |
| **DFIR** | Velociraptor | Latest stable release |
| **Threat Intel** | OpenCTI | Latest (Docker Compose) |
| **AD Simulation** | Windows Server 2022 Eval | Fixed |
| **Attack Platform** | Kali Linux | Latest |
| **ATT&CK Sim** | MITRE Caldera | **Pinned v5.0.0** |
| **LLM Runtime** | Ollama | Latest |
| **Agent Framework** | LangChain | **Pinned 0.3.7** |
| **LLM Integration** | langchain-ollama | **Pinned 0.2.0** |
| **API Wrapper** | Flask | **Pinned 3.0.3** |
| **VPN/Overlay** | Tailscale WireGuard | Latest |
| **Backup** | Proxmox Backup Server | Latest |
| **DNS Filter** | AdGuard Home | Latest |

> **Version pinning rationale:** OS-layer tools (Proxmox, OPNsense, Ubuntu) always use latest stable — these have stable APIs and regular security patches. Application-layer tools that have volatile APIs (Caldera, LangChain) are pinned to tested versions. These are documented throughout the build guide.

---

## 📊 Progress Log

| Date | Phase | Milestone | Notes |
|------|-------|-----------|-------|
| — | Pre-build | Planning complete | Full KB document created |
| — | Pre-build | Hardware confirmed | 3 nodes across 2 locations |
| — | Pre-build | Tailscale design finalised | Node 3 offsite via Jeenitesh |

*More entries will be added as the build progresses.*

---

## 🔐 Security Notes

- No real credentials, API keys, or passwords are stored anywhere in this repository
- All IP addresses shown are internal lab addresses or Tailscale overlay addresses — they are not internet-routable
- The physical management IPs of the Proxmox nodes are intentionally omitted from this README
- `vm100` and `vm101` contain personal and private data and are never part of any lab experiment

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built by [Ansh Patel](https://github.com/anshpatel) with infrastructure hosted by Jeenitesh Nandwani**

*A distributed, real-world cybersecurity homelab — no cloud shortcuts*

</div>
