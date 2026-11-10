# bastion

Ansible playbook that turns a fresh Ubuntu/Debian server into a hardened, self-updating host in one run.
Every machine in my homelab starts here before anything else gets installed.

```mermaid
flowchart LR
    A[fresh Ubuntu server] --> B(common)
    B --> C(users)
    C --> D(ssh)
    D --> E(firewall)
    E --> F(fail2ban)
    F --> G[hardened host]
```

## What it does

| Role | Result |
|---|---|
| `common` | base packages, timezone, unattended security upgrades with scheduled reboot, kernel sysctl hardening |
| `users` | admin users with key-only login, exclusive `authorized_keys`, sudo via validated drop-in |
| `ssh` | `sshd_config.d` drop-in: no root, no passwords, `AllowGroups`, verbose logging, validated with `sshd -t` before it is applied |
| `firewall` | ufw default-deny, SSH rate-limited, per-host extra ports and trusted networks |
| `fail2ban` | `sshd` jail using the systemd journal, bans through ufw, increasing ban time for repeat offenders |

## Usage

```bash
make deps                                   # install required collections
cp inventory/hosts.example.yml inventory/hosts.yml
$EDITOR group_vars/all.yml                  # add your public SSH key
make check                                  # dry run with diff
make apply
```

Per-host ports go into `host_vars/<host>.yml`, for example a game server:

```yaml
baseline_firewall_allowed_tcp: [25565]
```

Run a single part with tags: `ansible-playbook site.yml --tags ssh`.

## Testing

- `make test-vm` runs the playbook against a throwaway Vagrant VM (`vagrant up` first).
- CI runs `yamllint`, `ansible-lint` (production profile) and a syntax check on every push.
- Running the playbook twice must report `changed=0` the second time (idempotency).

## Design decisions

- **Can't lock you out.** The SSH role refuses to run without at least one admin key, the connecting user is added to the allowed group, the firewall opens SSH before switching to default-deny, and `sshd -t` validates the config before it is written.
- **Drop-ins instead of editing vendor files.** `sshd_config.d/` and `jail.local` survive package upgrades and keep the diff to the distro default obvious.
- **Key-only, exclusive keys.** `authorized_keys` is managed exclusively, so removing a key from the inventory really removes access.
- **Safe defaults, explicit overrides.** Everything lives in `group_vars/all.yml`; nothing host-specific is hard-coded in roles.

---

Part of my homelab series → [safekeep](https://github.com/antony-bdc/safekeep) · [dwellers-galaxy](https://github.com/antony-bdc/dwellers-galaxy) · [observatory](https://github.com/antony-bdc/observatory)
