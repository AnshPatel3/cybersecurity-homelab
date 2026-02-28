#!/bin/bash
# healthcheck.sh — Post-reboot health check for all CyberLab services
# 
# Setup:  chmod +x /root/healthcheck.sh
# Run:    /root/healthcheck.sh
# Place on: Node 1 Proxmox host at /root/healthcheck.sh
#
# Replace NODE3_TS_IP with your actual Node 3 Tailscale IP before using

NODE3_TS_IP="100.x.x.x"   # <- replace with real value

check() {
  local label="$1"
  local cmd="$2"
  printf "%-30s" "$label"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "✅ OK"
  else
    echo "❌ FAIL"
  fi
}

echo ""
echo "═══════════════════════════════════════════"
echo "  CyberLab Health Check — $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════"
echo ""

echo "── NETWORK ─────────────────────────────────"
check "OPNsense gateway"       "ping -c1 -W2 10.10.20.1"
check "Tailscale to Node 3"    "tailscale ping -c1 $NODE3_TS_IP 2>/dev/null | grep -q pong"

echo ""
echo "── NODE 1 SERVICES ─────────────────────────"
check "Wazuh Dashboard"        "curl -sk https://10.10.20.10 -o /dev/null -w '%{http_code}' | grep -q 200"
check "DC01 DNS"               "nslookup lab.local 10.10.20.20 2>/dev/null | grep -q 'Name:'"
check "Shuffle SOAR"           "curl -s http://10.10.20.40:3001 -o /dev/null -w '%{http_code}' | grep -q 200"
check "Authentik IdP"          "curl -s http://10.10.20.45:9000 -o /dev/null -w '%{http_code}' | grep -q 200"

echo ""
echo "── NODE 2 SERVICES ─────────────────────────"
check "Velociraptor DFIR"      "curl -sk https://10.10.20.50:8889 -o /dev/null -w '%{http_code}' | grep -q 200"
check "OpenCTI Threat Intel"   "curl -s http://10.10.20.60:8080 -o /dev/null -w '%{http_code}' | grep -q 200"
check "AI Agent (Open WebUI)"  "curl -s http://10.10.20.80:3000 -o /dev/null -w '%{http_code}' | grep -q 200"

echo ""
echo "── WAZUH AGENTS ────────────────────────────"
ACTIVE=$(ssh ubuntu@10.10.20.10 'sudo /var/ossec/bin/agent_control -l 2>/dev/null | grep -c Active' 2>/dev/null)
echo "Active agents: ${ACTIVE:-unknown}"

echo ""
echo "═══════════════════════════════════════════"
echo "  Check Wazuh Dashboard for full agent list"
echo "  Check https://PBS_TS_IP:8007 for backup status"
echo "═══════════════════════════════════════════"
echo ""
