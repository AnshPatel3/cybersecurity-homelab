#!/bin/bash
# tailscale-verify.sh — Verify all 5 CyberLab Tailscale endpoints are connected
#
# Run on any of the three Proxmox hosts after initial Tailscale setup
# or after any suspected outage.
#
# Update the IP variables below with your actual Tailscale IPs.

NODE1_TS_IP="100.x.x.x"    # <- Node 1 Proxmox host Tailscale IP
NODE2_TS_IP="100.x.x.x"    # <- Node 2 Proxmox host Tailscale IP
NODE3_TS_IP="100.x.x.x"    # <- Node 3 Proxmox host Tailscale IP
PBS_TS_IP="100.x.x.x"      # <- PBS LXC 351 Tailscale IP
SENSOR_TS_IP="100.x.x.x"   # <- Sensor vm300 Tailscale IP

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Tailscale Endpoint Verification"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════"
echo ""

echo "Current Tailscale status:"
tailscale status
echo ""

echo "── Ping Tests ──────────────────────────────────────"

ping_check() {
  local label="$1"
  local ip="$2"
  printf "%-30s %s ... " "$label" "$ip"
  result=$(tailscale ping -c1 "$ip" 2>/dev/null)
  if echo "$result" | grep -q "pong"; then
    latency=$(echo "$result" | grep -oP '\d+ms' | head -1)
    echo "✅ OK ($latency)"
  else
    echo "❌ UNREACHABLE"
  fi
}

ping_check "Node 1 host"   "$NODE1_TS_IP"
ping_check "Node 2 host"   "$NODE2_TS_IP"
ping_check "Node 3 host"   "$NODE3_TS_IP"
ping_check "PBS (lxc351)"  "$PBS_TS_IP"
ping_check "Sensor (vm300)" "$SENSOR_TS_IP"

echo ""
echo "── Troubleshooting ─────────────────────────────────"
echo "If any endpoint shows UNREACHABLE:"
echo "  1. Check Tailscale on that machine: tailscale status"
echo "  2. Bring up if disconnected: tailscale up"
echo "  3. Restart daemon if stuck: systemctl restart tailscaled"
echo "  4. For Node 3: ask Jeenitesh to check the machine"
echo ""
