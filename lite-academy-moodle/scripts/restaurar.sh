#!/usr/bin/env bash
# Restaurar um backup:  bash scripts/restaurar.sh 2026-10-01_0300
# ATENÇÃO: substitui a base de dados e os ficheiros atuais.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
STAMP="${1:?Indicar a data do backup, ex.: 2026-10-01_0300}"
DEST="$PWD/backups"
[ -f "$DEST/db_$STAMP.dump" ] && [ -f "$DEST/moodledata_$STAMP.tar.gz" ] || { echo "Backup $STAMP não encontrado"; exit 1; }

read -r -p "Isto apaga os dados atuais e repõe o backup $STAMP. Escrever SIM para continuar: " ok
[ "$ok" = "SIM" ] || exit 1

docker compose stop moodle cron
docker compose exec -T db pg_restore -U "$DB_USER" -d "$DB_NAME" --clean --if-exists --no-owner < "$DEST/db_$STAMP.dump"
docker compose run --rm --no-deps -T --user root -v "$DEST":/backups --entrypoint "" cron \
  sh -c "find /var/moodledata -mindepth 1 -delete && tar -xzf /backups/moodledata_$STAMP.tar.gz -C /var/moodledata && chown -R www-data:www-data /var/moodledata"
docker compose start moodle cron
docker compose exec -T --user www-data moodle php admin/cli/purge_caches.php
echo "✔ Backup $STAMP reposto"
