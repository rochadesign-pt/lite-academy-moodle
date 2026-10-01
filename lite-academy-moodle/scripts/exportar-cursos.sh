#!/usr/bin/env bash
# Exporta TODAS as disciplinas como cópias de segurança Moodle (.mbz), uma por disciplina.
# Úteis para: guardar o conteúdo fora da plataforma, restaurar noutro Moodle,
# ou extrair os ficheiros (PDF, vídeos, imagens) para o website.
#   bash scripts/exportar-cursos.sh      -> ficam em exportacoes/AAAA-MM-DD/
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

STAMP="$(date +%Y-%m-%d)"
INNER="/var/moodledata/exports/$STAMP"
docker compose exec -T --user www-data moodle mkdir -p "$INNER"

IDS="$(docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT id FROM mdl_course WHERE id > 1 ORDER BY id")"
for id in $IDS; do
  echo "» Disciplina $id…"
  docker compose exec -T --user www-data moodle php admin/cli/backup.php --courseid="$id" --destination="$INNER" >/dev/null
done

mkdir -p exportacoes
docker compose cp "moodle:$INNER" "exportacoes/"
docker compose exec -T moodle rm -rf "$INNER"
if [ -n "${BACKUP_DRIVE:-}" ] && [ -f rclone/rclone.conf ]; then
  docker compose run --rm -T rclone copy "/exportacoes/$STAMP" "$BACKUP_DRIVE/disciplinas/$STAMP"
  echo "  ↳ copiado para o Google Drive ($BACKUP_DRIVE/disciplinas/$STAMP)"
fi
echo "✔ $(ls "exportacoes/$STAMP" | wc -l) disciplinas exportadas para exportacoes/$STAMP/"
