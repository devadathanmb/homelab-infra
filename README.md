# Homelab Infrastructure

This is how I run my homelab. It keeps a small fleet of Raspberry Pis tidy, consistent, and reproducible — using [Ansible](https://www.ansible.com/) for provisioning and [Dotbot](https://github.com/anishathalye/dotbot) for dotfiles.

<img width="3024" height="1964" alt="image" src="https://github.com/user-attachments/assets/2bcf8388-ffb4-4b24-b522-2a744fa51704" />
<img width="3024" height="1964" alt="image" src="https://github.com/user-attachments/assets/aed9dcb6-6b32-49b7-9621-599c66f24328" />


## What This Is
Practical automation for my personal servers: package installs, services, VPN, and shell setup. Opinionated enough for me, simple enough to copy.

## Repo Layout
- [ansible/](ansible/) — Ansible config, inventory, group/host vars, roles, and playbooks
- [dotfiles/](dotfiles/) — Dotbot-based dotfiles and configs
- [docker-compose/](docker-compose/) — Docker Compose files for self-hosted services

## Services

| Service | Port | Description |
|---|---|---|
| AdGuard Home | 80, 53 | DNS-level ad blocking |
| Portainer | 9443 | Docker management UI |
| Jellyfin | 8096 | Media server |
| FreshRSS | 8086 | RSS reader |
| Miniflux | 8085 | Minimal RSS reader |
| Stirling PDF | 8080 | PDF tools |

## Architecture
- **Automation scope:** This repo focuses on base machine setup, Docker, Git access, and dotfiles. Product-specific networking and exposure layers are intentionally kept out unless they are clearly justified and maintained.

## Setup
1) Vault password (for encrypted vars):
```bash
echo 'your-vault-password' > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```
2) Inventory: edit [ansible/inventory.ini](ansible/inventory.ini) with your hosts.
3) Install required Ansible collections:
```bash
cd ansible
ansible-galaxy collection install -r collections/requirements.yml
```

## Usage
From the `ansible/` directory:
```bash
# Full provision (all roles in order)
ansible-playbook playbooks/site.yaml

# Fresh system bootstrap (packages + system + docker)
ansible-playbook playbooks/bootstrap.yaml

# Run a specific playbook
ansible-playbook playbooks/packages.yaml
ansible-playbook playbooks/system.yaml
ansible-playbook playbooks/docker.yaml
ansible-playbook playbooks/git.yaml
ansible-playbook playbooks/dotfiles.yaml

# Update packages only
ansible-playbook playbooks/update.yaml

# Run tasks matching a tag (works with site.yaml or any playbook)
ansible-playbook playbooks/site.yaml --tags "docker"
ansible-playbook playbooks/site.yaml --tags "git,ssh"
```
