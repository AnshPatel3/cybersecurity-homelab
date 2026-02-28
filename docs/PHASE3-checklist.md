# Phase 3 Build Checklist — Attack + DFIR + Threat Intel
**Weeks 9–12 · Prerequisite: All Phase 2 checkboxes complete**

> ⚠️ Run a PBS manual backup of all Phase 1+2 VMs before starting Phase 3.

---

## vm200 — Velociraptor DFIR (Node 2)

- [ ] Check Node 2 free space before creating: `pvesm status` on Node 2 shell
- [ ] VM created (ID 200, Ubuntu 24.04, 3GB RAM, 50GB disk)
- [ ] Static IP: 10.10.20.50/24
- [ ] Latest stable version downloaded from GitHub releases (not pinned URL — check releases page)
- [ ] `velociraptor config generate -i` completed (DNS: 10.10.20.50, GUI: 8889)
- [ ] systemd service created and enabled
- [ ] GUI accessible: `https://10.10.20.50:8889`
- [ ] Agents deployed to dc01 and win11 via Server Artifacts
- [ ] VQL hunt: process list returns from all Windows VMs
- [ ] Boot order: Order 1, Up Delay 30s, Start at Boot YES

---

## vm201 — OpenCTI Threat Intelligence (Node 2)

- [ ] VM created (ID 201, Ubuntu 24.04, **4GB RAM minimum**, 50GB disk)
- [ ] Static IP: 10.10.20.60/24
- [ ] Docker CE from official repo
- [ ] `.env` file configured with generated tokens and `ELASTIC_MEMORY_SIZE=2g`
- [ ] **STAGED STARTUP used:** infra first (`redis elasticsearch minio rabbitmq`) → wait 90s → then app (`opencti worker`)
- [ ] Elasticsearch healthy before app started: `docker ps` shows all 4 Up
- [ ] OpenCTI UI accessible: `http://10.10.20.60:8080` (first boot 5-10 min)
- [ ] MITRE ATT&CK connector enabled
- [ ] AlienVault OTX connector enabled (free key from otx.alienvault.com)
- [ ] Initial sync completed
- [ ] systemd service created with 30s `ExecStartPre=/bin/sleep 30`
- [ ] Boot order: Order 2, **Up Delay 90s**, Start at Boot YES

---

## vm202 — AI Agent VM (Node 2) — Pre-stage

- [ ] VM created (ID 202, Ubuntu 24.04, 8GB RAM, 80GB disk)
- [ ] Static IP: 10.10.20.80/24
- [ ] Ollama installed: `curl -fsSL https://ollama.com/install.sh | sh`
- [ ] `ollama pull llama3.2:3b` (test model)
- [ ] `ollama pull qwen2.5:7b` (production model)
- [ ] Open WebUI running via Docker: `http://10.10.20.80:3000`
- [ ] Boot order: Order 3, Up Delay 30s, Start at Boot YES

---

## vm203 — Kali Linux (Node 2) — On-demand

- [ ] VM created (ID 203, Kali latest, 4GB RAM, 60GB disk)
- [ ] **Network: vmbr2 ONLY** — no vmbr1 NIC ever
- [ ] Static IP: 10.10.50.10/24
- [ ] Start at Boot: NO
- [ ] Test VLAN isolation: Kali CANNOT ping 10.10.20.1 (confirm block rule working)

---

## vm204 — Caldera (Node 2) — On-demand

- [ ] VM created (ID 204, Ubuntu 24.04, 3GB RAM, 30GB disk)
- [ ] Static IP: 10.10.20.70/24
- [ ] Python venv created
- [ ] **Caldera cloned with `--branch 5.0.0`** (not main branch)
- [ ] Dependencies installed inside venv: `pip install -r requirements.txt`
- [ ] First run: `python3 server.py --insecure --build`
- [ ] GUI accessible: `http://10.10.20.70:8888`
- [ ] Start at Boot: NO

---

## vm205 — Target VMs (Node 2) — On-demand

- [ ] VM created (ID 205, vulnerable OS/distro, 2GB RAM)
- [ ] Network: vmbr2 (10.10.50.20/24)
- [ ] Start at Boot: NO

---

## Purple Team Cycle (must complete at least one full cycle)

- [ ] Caldera DISCOVERY operation run against win11
- [ ] Before-state: count Wazuh alerts for win11 before operation
- [ ] Operation runs: Caldera deploys Sandcat agent to win11, runs techniques
- [ ] After-state: count new Wazuh alerts triggered by techniques
- [ ] Detection rate calculated: (detected techniques / total techniques) × 100%
- [ ] Velociraptor hunt run post-operation: process artifacts collected
- [ ] OpenCTI: at least one observed TTP correlated to ATT&CK technique
- [ ] Results documented in `screenshots/phase3/`

---

## Phase 3 Done When

- [ ] Velociraptor returns process data from all Windows VMs
- [ ] OpenCTI shows ATT&CK framework data and OTX indicators
- [ ] One complete Caldera purple team cycle documented with detection rate
- [ ] Kali confirmed isolated from VLAN 20
- [ ] PBS backup taken for all VMs (Phase 1–3)
- [ ] Screenshot evidence saved to `screenshots/phase3/`
