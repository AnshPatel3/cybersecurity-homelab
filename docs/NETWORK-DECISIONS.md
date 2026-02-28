# Network Design Decisions

This document explains the reasoning behind every non-obvious choice in the network design.

---

## Why 10.10.20.x and not 10.0.20.x for the lab VLAN

Node 3 (Jeenitesh's machine) is on a `10.0.0.x` physical network. Using `10.0.20.x` for the internal lab VLAN would create routing table conflicts through the Tailscale tunnel. When the sensor on vm300 tries to reach Wazuh, packets with destination `10.0.20.10` could be confused with routes to `10.0.0.x` on the physical network and dropped or misrouted.

Using `10.10.20.x` (a completely different /16 block) eliminates this conflict entirely. Neither `192.168.1.x` (home network) nor `10.0.0.x` (Jeenitesh's network) overlap with `10.10.x.x`.

---

## Why the remote sensor uses NODE1_TS_IP:1514 and not 10.10.20.10:1514

`10.10.20.10` is the Wazuh VM's address on the internal lab VLAN (`vmbr1`). This VLAN only exists inside the Proxmox hypervisor on Node 1 and Node 2. `vm300` on Node 3 has no physical or virtual connection to `vmbr1` — it only has `vmbr0` (Jeenitesh's physical network).

The only path from vm300 to Wazuh is through the Tailscale tunnel. Node 1's Proxmox host has a Tailscale IP (`NODE1_TS_IP`) and routes traffic to the lab VMs it hosts, including Wazuh on `10.10.20.10`. By pointing the agent at `NODE1_TS_IP:1514`, the traffic travels encrypted over Tailscale, arrives at Node 1's host, and is routed to `vmbr1` → Wazuh.

---

## Why PBS gets its own Tailscale IP inside the LXC

The Node 3 Proxmox host already has a Tailscale IP. However, PBS runs inside LXC 351 — a container with its own network namespace. If backup traffic had to go through the host's Tailscale, it would require additional routing configuration inside Proxmox that is fragile.

By installing Tailscale inside LXC 351 itself, PBS gets a direct stable `100.x.x.x` IP that Nodes 1 and 2 register as the backup server address. The path is: Node 1 → Tailscale → PBS LXC 351's own Tailscale interface → PBS port 8007. No host-level routing required.

---

## Why Authentik runs in a dedicated LXC and not alongside Shuffle

Early planning co-located Authentik in the same Docker environment as Shuffle. This caused two problems:
1. Port conflicts between Authentik (9000, 9443) and Shuffle's OpenSearch container (9200, 9300)
2. Combined memory pressure caused both services to fail health checks intermittently on 4GB RAM

Dedicated LXC 150 for Authentik (2GB RAM) keeps the services isolated and prevents either from impacting the other. The LXC requires `nesting: ON` and `keyctl: ON` in Proxmox options for Docker to work correctly inside it.

---

## Why vm100 and vm101 are excluded from all backup jobs

`vm100` is a personal Windows 11 VM used for college. Backing it up with Proxmox snapshot mode would include potentially sensitive data in the `lab-backup` datastore on Node 3 (hosted by Jeenitesh). It should be backed up separately if at all.

`vm101` is a TrueNAS NAS server using the 1TB HDD as a ZFS pool. Snapshotting a ZFS-based VM via Proxmox (which operates at the block device level below ZFS) can corrupt the pool by creating an inconsistent snapshot mid-write. TrueNAS has its own internal replication and snapshot system that should be used for its backups.

---

## Why Caldera is pinned to v5.0.0

MITRE Caldera's `main` branch frequently introduces breaking changes to the Python dependency tree. Ubuntu 24.04 ships Python 3.12, which has stricter import rules and deprecated several APIs that Caldera's main branch still uses as of early 2026. `v5.0.0` is the last tested-stable tag that works cleanly with Python 3.12 and the current version of the Sandcat agent.

A Python `venv` is required to isolate Caldera's dependencies from system Python and from any other project (such as the LangChain agent in Phase 4).

---

## Why OPNsense uses i440fx and not q35

OPNsense runs FreeBSD under the hood. FreeBSD's AHCI driver has compatibility issues with q35's PCIe topology simulation, which can cause intermittent disk I/O errors. i440fx + SeaBIOS provides the most stable environment for OPNsense in Proxmox. Windows VMs (dc01, win11) use q35 + OVMF UEFI because Windows requires TPM 2.0 support which is only available in q35.

---

## Why OpenCTI requires a staged startup

OpenCTI depends on 4 backend services: Redis (cache), Elasticsearch (data store), MinIO (object storage), and RabbitMQ (message queue). When all 5 services start simultaneously (e.g. via systemd after boot), Elasticsearch takes 60-90 seconds to become fully ready. During this time, the OpenCTI application connects to Elasticsearch, finds it not ready, and enters a crash/restart loop.

The fix is a staged start: bring up the 4 infrastructure services first, wait until all are healthy (check `docker ps`), then start `opencti` and `worker`. The systemd service has a 30-second `ExecStartPre=/bin/sleep 30` and the Proxmox boot Up Delay is set to 90 seconds to give infrastructure time before the systemd service fires.
