#!/usr/bin/env bash
# Liga o servidor ao Google Drive (uma vez). Precisa do Mac por perto para autorizar.
#
# Respostas a dar no assistente:
#   n                (novo remote)
#   gdrive           (nome — tem de ser exatamente este)
#   drive            (tipo: Google Drive)
#   [Enter] [Enter]  (client_id e client_secret vazios)
#   3                (scope "drive.file": o servidor só vê as pastas que ele próprio cria)
#   [Enter] [Enter]  (service_account_file vazio; root_folder vazio)
#   n                (não editar configuração avançada)
#   n                (sem browser no servidor) -> aparece um comando "rclone authorize ..."
#   -> no Mac, no Terminal:  brew install rclone   (ou: curl https://rclone.org/install.sh | sudo bash)
#   -> no Mac, correr o comando "rclone authorize ..." mostrado, autorizar no browser
#      com a conta Google do liteacademy.eu, e colar aqui o código que aparecer
#   n                (não é um Shared Drive)
#   y  e  q          (confirmar e sair)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p rclone backups exportacoes
docker compose run --rm rclone config
echo
echo "» Teste: a criar a pasta no Drive…"
set -a; . ./.env; set +a
docker compose run --rm -T rclone mkdir "$BACKUP_DRIVE"
docker compose run --rm -T rclone lsd "${BACKUP_DRIVE%%:*}:"
echo "✔ Google Drive ligado. Os backups passam a ser copiados para $BACKUP_DRIVE"
