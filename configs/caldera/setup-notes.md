# Caldera v5.0.0 Setup Notes

**Why v5.0.0 is pinned:** The `main` branch breaks on Python 3.12 (Ubuntu 24.04 default).
Using a Python venv isolates dependencies and prevents version conflicts with Phase 4's LangChain setup.

---

## Install Commands

```bash
# Prerequisites
sudo apt install -y python3 python3-pip python3-venv git golang-go
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Clone pinned tag
git clone https://github.com/mitre/caldera.git --recursive --branch 5.0.0 ~/caldera
cd ~/caldera

# Create isolated venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# First run (builds UI)
python3 server.py --insecure --build
# Takes 3-5 minutes. Access: http://10.10.20.70:8888

# Get red team password
cat conf/local.yml | grep red
```

---

## Subsequent Runs

```bash
cd ~/caldera
source venv/bin/activate
python3 server.py --insecure
```

---

## Purple Team Cycle — How to Run

1. Start Caldera on vm204 (manual start — not auto-boot)
2. Start target win11 is already running
3. In Caldera GUI: create a new operation, select DISCOVERY adversary profile
4. Deploy Sandcat agent to win11 via PowerShell one-liner from Caldera GUI
5. Run operation
6. Note which techniques executed
7. In Wazuh: filter alerts for win11 during operation window
8. Calculate detection rate: detected / total × 100%
9. Document gaps — techniques that ran but produced no alert

---

## Stopping Caldera

```bash
# In the terminal running server.py: Ctrl+C
# Or via systemd if service is set up:
sudo systemctl stop caldera
```
