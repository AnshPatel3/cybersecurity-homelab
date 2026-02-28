# Phase 4 Build Checklist — Agentic AI SOC
**Weeks 13–16 · Prerequisite: All Phase 3 checkboxes complete**

---

## vm202 — AI Agent (Full Build)

- [ ] Ollama responding: `curl http://localhost:11434` returns "Ollama is running"
- [ ] `qwen2.5:7b` model loaded: `ollama list`
- [ ] Open WebUI chat working with Ollama backend

---

## Wazuh MCP Server

- [ ] Python venv created: `python3 -m venv ~/mcp-env`
- [ ] Wazuh MCP Server repo cloned
- [ ] `.env` created with Wazuh host 10.10.20.10, port 55000, wazuh-wui credentials
- [ ] `pip install -r requirements.txt` in venv
- [ ] MCP server starts without error
- [ ] Test query returns real Wazuh alert data
- [ ] systemd service created and enabled

---

## LangChain Agent

- [ ] **Exact pinned versions installed:**
  - `langchain==0.3.7`
  - `langchain-ollama==0.2.0`
  - `langchain-community==0.3.7`
  - `flask==3.0.3`
  - `requests==2.31.0`
- [ ] `wazuh_auth.py` — JWT token auto-refresh every 800s (before 900s expiry)
- [ ] `soc_agent.py` — 3 tools defined:
  - Tool 1: WazuhAlerts (GET /api/alerts via REST)
  - Tool 2: VirusTotal (GET /vtotal/v3/ip_addresses/{ip})
  - Tool 3: OpenCTI (GraphQL query to 10.10.20.60:8080)
- [ ] `triage_api.py` — Flask app on port 5000, wraps agent
- [ ] Test: POST to Flask :5000 with a sample alert returns AI summary
- [ ] Agent calls all 3 tools and assembles a coherent investigation summary

---

## Full Automation Loop Test

- [ ] Shuffle workflow updated: add HTTP POST to Flask :5000 after brute force trigger
- [ ] End-to-end test:
  - [ ] Trigger brute force rule 100001
  - [ ] Shuffle receives webhook
  - [ ] Shuffle POSTs to Flask :5000
  - [ ] LangChain agent runs all 3 tools
  - [ ] AI summary returned to Shuffle
  - [ ] Discord notification includes AI summary text
- [ ] Full loop completes without manual intervention

---

## Phase 4 Done When

- [ ] Ollama responds to security questions in Open WebUI
- [ ] MCP queries return real alert data from Wazuh
- [ ] LangChain agent calls all 3 tools for every investigation
- [ ] Full loop (Wazuh → Shuffle → Flask → AI → Discord) working
- [ ] PBS final backup taken for all VMs
- [ ] Screenshot evidence saved to `screenshots/phase4/`
- [ ] Progress log updated in README.md
