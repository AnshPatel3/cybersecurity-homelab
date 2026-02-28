# Proxmox Backup Server Setup Guide

PBS runs on Node 3 (Jeenitesh's house) inside LXC 351. All backup traffic travels over Tailscale — no port forwarding needed on Jeenitesh's router.

---

## Why PBS is on Node 3

Node 3 is physically at a different location. This makes lxc351 a genuine offsite backup:
- A fire, flood, or theft at Ansh's home cannot destroy both the lab and its backups
- Node 3 runs independently even if Nodes 1 and 2 are completely offline

---

## PBS LXC Setup (lxc351)

```bash
# Inside LXC 351 console:
apt update && apt upgrade -y

# Install Tailscale (gives PBS its own stable 100.x.x.x IP)
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up  # authenticate with SAME Tailscale account as the three nodes
tailscale ip -4  # record this as PBS_TS_IP

# Install PBS
echo 'deb http://download.proxmox.com/debian/pbs bookworm pve-no-subscription' \
  > /etc/apt/sources.list.d/pbs.list
wget -qO /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg \
  https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg
apt update && apt install -y proxmox-backup-server

# Create backup storage
mkdir -p /mnt/lab-backup

# Get TLS fingerprint — SAVE THIS
proxmox-backup-manager cert info | grep Fingerprint
```

---

## Adding PBS to Node 1 and Node 2

In Proxmox GUI on each node: **Datacenter → Storage → Add → Proxmox Backup Server**

| Field | Value |
|-------|-------|
| ID | `pbs-offsite` |
| Server | `PBS_TS_IP` (the 100.x.x.x Tailscale IP — NOT 10.0.0.50) |
| Username | `admin@pbs` |
| Password | LXC 351 root password |
| Datastore | `lab-backup` |
| Fingerprint | (paste SHA256 from above) |

---

## Backup Job Configuration

**Datacenter → Backup → Add (on each node):**

| Setting | Node 1 Value | Node 2 Value |
|---------|-------------|-------------|
| Storage | pbs-offsite | pbs-offsite |
| Schedule | `sun 02:00` | `sun 03:00` |
| Selection | Exclude | Exclude |
| Excluded VMs | `100` | `101` |
| Mode | Snapshot | Snapshot |
| Compression | ZSTD | ZSTD |
| Keep Last | 3 | 3 |
| Keep Weekly | 4 | 4 |

> Snapshot mode requires `qemu-guest-agent` running inside each VM. This is installed as part of each VM's setup in the build checklists.

---

## Troubleshooting

**Connection fails when adding storage:**
1. `tailscale ip -4` inside LXC 351 — confirm PBS_TS_IP is correct
2. `systemctl status tailscaled` inside LXC 351 — must be active
3. `curl -k https://PBS_TS_IP:8007` from Node 1 shell — should return HTML
4. Check fingerprint has no leading/trailing spaces

**Backup job shows failed:**
- Most common cause: Tailscale tunnel was down at scheduled backup time
- Fix: Run the job manually in Proxmox GUI → it will succeed once Tailscale is up

**Restore a VM from PBS:**
- Proxmox GUI → select the node → Storage: pbs-offsite → Content
- Find the VM backup → Restore → choose target node and storage
