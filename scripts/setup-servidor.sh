#!/usr/bin/env bash
# Prepara um servidor Ubuntu 24.04 novo. Correr UMA vez, como root:
#   bash scripts/setup-servidor.sh
set -euo pipefail

apt-get update
apt-get -y upgrade
apt-get install -y ca-certificates curl git rsync ufw fail2ban unattended-upgrades

# Docker (script oficial)
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

# Firewall: só SSH, HTTP e HTTPS
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Atualizações de segurança automáticas do sistema
dpkg-reconfigure -f noninteractive unattended-upgrades

# Swap de 4 GB (margem de segurança para a memória)
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

timedatectl set-timezone Europe/Lisbon
echo "Servidor pronto. Próximo passo: preencher .env e correr scripts/instalar.sh"
