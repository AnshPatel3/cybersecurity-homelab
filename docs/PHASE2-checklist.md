# Phase 2 Build Checklist — SOAR + Identity
**Weeks 5–8 · Prerequisite: All Phase 1 checkboxes complete**

---

## vm106 — Shuffle SOAR

- [ ] VM created (ID 106, Ubuntu 24.04 LTS, 4GB RAM, 50GB disk)
- [ ] Static IP: 10.10.20.40/24
- [ ] Docker CE installed from official repo (NOT `apt install docker.io`)
- [ ] `docker run hello-world` succeeds before continuing
- [ ] Shuffle repo cloned to `~/shuffle`
- [ ] `OUTER_HOSTNAME=10.10.20.40` added to docker-compose.yml frontend env
- [ ] `OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m` set in docker-compose.yml
- [ ] `docker compose up -d` — all 4 containers show Up
- [ ] Shuffle UI accessible: `http://10.10.20.40:3001`
- [ ] Admin account created
- [ ] systemd service created and enabled (auto-start)
- [ ] Boot order: Order 4, Up Delay 30s, Start at Boot YES

### Wazuh → Shuffle Integration
- [ ] Webhook trigger created in Shuffle, hook URI copied
- [ ] `<integration>` block added to Wazuh ossec.conf with correct hook URL
- [ ] `systemctl restart wazuh-manager`
- [ ] Test: trigger a level 5+ alert, confirm Shuffle receives it

### OPNsense API Auto-Block Playbook
- [ ] OPNsense API key + secret created (System → Access → Users → admin)
- [ ] `soar_blocklist` alias created (Firewall → Aliases, type: Host(s))
- [ ] Firewall rule created: Block, Source: soar_blocklist
- [ ] Shuffle workflow built: webhook → extract srcip → POST addEntry → POST reloadFilter → Discord
- [ ] Test: manually add IP to soar_blocklist via API, verify it's blocked

---

## lxc150 — Authentik Identity Provider

- [ ] LXC created (ID 150, ubuntu-22.04, 2GB RAM, 20GB disk)
- [ ] Static IP: 10.10.20.45/24
- [ ] **Features: `keyctl` ON and `nesting` ON** (both required for Docker inside LXC)
- [ ] Docker installed inside LXC
- [ ] Authentik Docker Compose deployed with generated secrets
- [ ] First-boot setup completed at `/if/flow/initial-setup/`
- [ ] LDAP source configured: ldap://10.10.20.20, lab.local
- [ ] AD sync completed — alice and bob appear in Directory → Users
- [ ] MFA stage created and bound to IT_Admins group
- [ ] Test: login as alice triggers TOTP setup
- [ ] systemd service created and enabled
- [ ] Boot order: Order 5, Up Delay 30s, Start at Boot YES

---

## Phase 2 Done When

- [ ] Shuffle auto-receives Wazuh alerts (level 5+)
- [ ] Brute force detection triggers IP auto-block in OPNsense soar_blocklist
- [ ] Authentik syncs AD users from dc01
- [ ] alice login triggers MFA prompt
- [ ] All containers survive full reboot (test by rebooting Node 1)
- [ ] PBS manual backup taken for Phase 1+2 VMs
- [ ] Screenshot evidence saved to `screenshots/phase2/`
