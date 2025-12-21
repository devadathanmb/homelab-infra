# Homelab Infrastructure

This is how I run my homelab. It keeps a small fleet of Raspberry Pis tidy, consistent, and reproducible — using [Ansible](https://www.ansible.com/) for provisioning and [Dotbot](https://github.com/anishathalye/dotbot) for dotfiles.

<img width="3024" height="1964" alt="image" src="https://github.com/user-attachments/assets/2bcf8388-ffb4-4b24-b522-2a744fa51704" />

## What This Is
Practical automation for my personal servers: package installs, services, tunnels, VPN, and shell setup. Opinionated enough for me, simple enough to copy.

## Repo Layout
- [ansible/](ansible/) — Ansible config, inventory, group/host vars, and playbooks
- [dotfiles/](dotfiles/) — Dotbot-based dotfiles and configs
- [scripts/](scripts/) — helper scripts used around the homelab

## Architecture
- **Tailscale VPN:** Creates a private mesh network across nodes. Each device gets a stable Tailscale IP so SSH and Ansible traffic stay inside the secure network — no exposed ports or complex firewall rules.
- **Cloudflare Tunnel:** Exposes selected local services to the public internet via outbound-only tunnels. Cloudflared connects to Cloudflare’s edge, and DNS points there, so you don’t open inbound ports on your network.
- **How they fit:** Admin access uses Tailscale for secure management; public-facing apps use Cloudflare Tunnel for HTTPS. Ansible keeps both configured with inventories and vaulted secrets.

## Setup
1) Vault password (for encrypted vars):
```bash
echo 'your-vault-password' > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```
2) Inventory: edit [ansible/inventory.ini](ansible/inventory.ini) with your hosts.

## Usage
From the `ansible/` directory:
```bash
# Bootstrap a fresh Pi
ansible-playbook playbooks/bootstrap.yaml

# Update packages
ansible-playbook playbooks/update.yaml

# Tailscale (requires Vault)
ansible-playbook playbooks/tailscale.yaml --vault-password-file ~/.ansible_vault_pass

# Cloudflare Tunnel (requires Vault)
ansible-playbook playbooks/cloudflared.yaml --vault-password-file ~/.ansible_vault_pass

# Dotfiles (shell tooling via Dotbot)
ansible-playbook playbooks/dotfiles.yaml
```

## Secrets
Sensitive values live in Vaulted vars under [ansible/group_vars/vault.yaml](ansible/group_vars/vault.yaml) and per-host under [ansible/host_vars/](ansible/host_vars/). Run playbooks with `--vault-password-file` as shown above.


