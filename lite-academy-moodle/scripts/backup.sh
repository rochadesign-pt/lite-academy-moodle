#!/usr/bin/env bash
# Backup completo: base de dados + ficheiros (moodledata).
# Agendar diariamente com cron (ver README). Mantém BACKUP_KEEP_DAYS dias.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

DEST="$PWD/backups"
STAMP="$(date +%Y-%m-%d_%H%M)"
mkdir -p "$DEST"

docker compose exec -T db pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc > "$DEST/db_$STAMP.dump"
docker compose run --rm --no-deps -T --user root -v "$DEST":/backups --entrypoint "" cron \
  tar --exclude=./cache --exclude=./localcache --exclude=./sessions --exclude=./temp --exclude=./trashdir \
      -czf "/backups/moodledata_$STAMP.tar.gz" -C /var/moodledata .

find "$DEST" -type f -mtime +"${BACKUP_KEEP_DAYS:-7}" -delete

# Cópia para o Google Drive:
#  - base de dados: um ficheiro por dia, mantém BACKUP_DRIVE_KEEP_DAYS dias
#  - ficheiros: espelho do moodledata (só envia o que mudou — ocupa ~o tamanho dos conteúdos)
if [ -n "${BACKUP_DRIVE:-}" ] && [ -f rclone/rclone.conf ]; then
  docker compose run --rm -T rclone copy /backups "$BACKUP_DRIVE/base-de-dados" --include "db_*.dump"
  docker compose run --rm -T rclone delete "$BACKUP_DRIVE/base-de-dados" --min-age "${BACKUP_DRIVE_KEEP_DAYS:-14}d"
  docker compose run --rm -T rclone sync /moodledata "$BACKUP_DRIVE/ficheiros" \
    --exclude "cache/**" --exclude "localcache/**" --exclude "sessions/**" --exclude "temp/**" \
    --exclude "trashdir/**" --exclude "lock/**" --exclude "exports/**" --exclude "muc/**"
  echo "  ↳ copiado para o Google Drive ($BACKUP_DRIVE)"
fi

if [ -n "${BACKUP_REMOTE:-}" ]; then
  rsync -a --delete -e "ssh -p 23" "$DEST/" "$BACKUP_REMOTE/"
fi
echo "✔ Backup $STAMP concluído ($(du -sh "$DEST" | cut -f1) no total)"
