# OPNsense Key Firewall Rules

## Critical Rule — VLAN 50 Cannot Reach VLAN 20

This is the most important security rule in the entire lab. Without it, Kali and Caldera agents
on the attack range (10.10.50.x) can directly reach Wazuh, Active Directory, and every other
security tool on the SOC fabric (10.10.20.x).

**Location:** Firewall → Rules → ATTACK tab → **Add at TOP of rule list**

| Setting | Value |
|---------|-------|
| Action | Block |
| Interface | ATTACK |
| Direction | in |
| Protocol | any |
| Source | ATTACK net (10.10.50.0/24) |
| Destination | LAN net (10.10.20.0/24) |
| Description | CRITICAL — Block attack range from reaching SOC fabric |

Add this rule before creating any attack VM.

---

## soar_blocklist Alias (Phase 2)

**Location:** Firewall → Aliases → Add

| Setting | Value |
|---------|-------|
| Name | soar_blocklist |
| Type | Host(s) |
| Description | SOAR auto-blocked IPs |

After creating the alias, create a firewall rule on WAN that blocks traffic from `soar_blocklist`.

**API endpoints used by Shuffle:**
```
# Add IP to blocklist:
POST https://10.10.20.1/api/firewall/alias/addEntry/soar_blocklist
Authorization: Basic base64(key:secret)
Body: {"address": "1.2.3.4"}

# Reload firewall (required after adding entries):
POST https://10.10.20.1/api/firewall/filter/reloadFilter
Authorization: Basic base64(key:secret)
```

Reference: https://docs.opnsense.org/development/api/core/firewall.html

---

## Syslog Target (Phase 1)

**Location:** System → Logging / Targets → Add

| Setting | Value |
|---------|-------|
| Transport | UDP(4) |
| Hostname/IP | 10.10.20.10 |
| Port | 514 |
| Description | Wazuh SIEM |
| Facilities | select all |
