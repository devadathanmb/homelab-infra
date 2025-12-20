# Homelab Infrastructure

My personal [homelab](https://www.reddit.com/r/homelab/) infrastructure automation for Raspberry Pi nodes. Uses [Ansible](https://www.ansible.com/) for provisioning and [dotbot](https://github.com/anishathalye/dotbot) for dotfile management.

<img width="3024" height="1964" alt="image" src="https://github.com/user-attachments/assets/2bcf8388-ffb4-4b24-b522-2a744fa51704" />


## What's in here

- **[`ansible/`](ansible/)** - Ansible playbooks and configuration for homelab automation
- **[`dotfiles/`](dotfiles/)** - Personal dotfiles managed with dotbot

## Quick Start

### Setup vault password
```bash
echo 'your-vault-password' > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```

### Bootstrap a fresh Pi
```bash
cd ansible
ansible-playbook playbooks/bootstrap.yaml
```

### Common playbooks
```bash
# Update all packages
ansible-playbook playbooks/update.yaml

# Setup Tailscale VPN
ansible-playbook playbooks/tailscale.yaml --vault-password-file ~/.ansible_vault_pass

# Setup Cloudflare tunnel
ansible-playbook playbooks/cloudflared.yaml --vault-password-file ~/.ansible_vault_pass

# Deploy dotfiles
ansible-playbook playbooks/dotfiles.yaml
```

### Edit vault secrets
```bash
# Edit group-level vault (Tailscale auth key)
ansible-vault edit group_vars/vault.yaml --vault-password-file ~/.ansible_vault_pass

# Edit host-specific vault (Cloudflare tunnel token)
ansible-vault edit host_vars/pi/vault.yaml --vault-password-file ~/.ansible_vault_pass
```

## Playbooks

- [`bootstrap.yaml`](ansible/playbooks/bootstrap.yaml) - Initial setup: packages, [Docker](https://www.docker.com/), timezone, locale
- [`update.yaml`](ansible/playbooks/update.yaml) - System updates and upgrades
- [`tailscale.yaml`](ansible/playbooks/tailscale.yaml) - Install and configure [Tailscale](https://tailscale.com/) VPN
- [`cloudflared.yaml`](ansible/playbooks/cloudflared.yaml) - Install and configure [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/)
- [`dotfiles.yaml`](ansible/playbooks/dotfiles.yaml) - Sync repo and run [dotbot](https://github.com/anishathalye/dotbot) to link dotfiles
