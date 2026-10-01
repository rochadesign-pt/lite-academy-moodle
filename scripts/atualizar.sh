#!/usr/bin/env bash
# Atualizar o Moodle para a versão indicada em MOODLE_VERSION no .env
#   1) editar .env  (ex.: MOODLE_VERSION=v5.2.4)
#   2) bash scripts/atualizar.sh
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

echo "» Backup antes de atualizar…"
bash scripts/backup.sh

echo "» A construir o Moodle $MOODLE_VERSION…"
docker compose build moodle

echo "» Modo de manutenção ON"
docker compose exec -T --user www-data moodle php admin/cli/maintenance.php --enable

echo "» A trocar para a nova versão e atualizar a base de dados…"
docker compose up -d moodle cron
docker compose exec -T --user www-data moodle php admin/cli/upgrade.php --non-interactive
docker compose exec -T --user www-data moodle php admin/cli/purge_caches.php

docker compose exec -T --user www-data moodle php admin/cli/maintenance.php --disable
echo "✔ Moodle atualizado para $MOODLE_VERSION"
