#!/usr/bin/env bash
# Primeira instalação do Moodle. Correr na pasta do kit:  bash scripts/instalar.sh
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "Falta o ficheiro .env (cp .env.example .env e preencher)"; exit 1; }
grep -q MUDAR_ISTO .env && { echo "Ainda há valores MUDAR_ISTO no .env"; exit 1; }
set -a; . ./.env; set +a

echo "» A construir a imagem do Moodle $MOODLE_VERSION (demora alguns minutos)…"
docker compose build moodle

echo "» A arrancar os serviços…"
docker compose up -d

echo "» A instalar a base de dados do Moodle…"
docker compose exec -T --user www-data moodle php admin/cli/install_database.php \
  --agree-license \
  --lang=en \
  --fullname="$SITE_FULLNAME" \
  --shortname="$SITE_SHORTNAME" \
  --adminuser="$ADMIN_USER" \
  --adminpass="$ADMIN_PASSWORD" \
  --adminemail="$ADMIN_EMAIL"

echo "» A instalar o pacote de língua portuguesa…"
LANGVER="$(echo "$MOODLE_VERSION" | sed -E 's/^v([0-9]+)\.([0-9]+).*/\1.\2/')"
if docker compose exec -T --user www-data moodle sh -c "
  mkdir -p /var/moodledata/lang && cd /var/moodledata/lang &&
  curl -fsSL -o pt.zip https://download.moodle.org/download.php/direct/langpack/$LANGVER/pt.zip &&
  php -r '\$z=new ZipArchive; \$z->open(\"pt.zip\"); \$z->extractTo(\".\"); \$z->close();' && rm pt.zip"; then
  docker compose exec -T --user www-data moodle php admin/cli/cfg.php --name=lang --set=pt
else
  echo "  ! Não foi possível descarregar o português. Instalar depois em:"
  echo "    Administração do site > Geral > Idioma > Pacotes de idioma > Português (pt)"
fi
docker compose exec -T --user www-data moodle php admin/cli/cfg.php --name=timezone --set=Europe/Lisbon
docker compose exec -T --user www-data moodle php admin/cli/cfg.php --name=country --set=PT
# Permitir descarregar o conteúdo de cada disciplina num ZIP (ficheiros + páginas)
docker compose exec -T --user www-data moodle php admin/cli/cfg.php --name=downloadcoursecontentallowed --set=1
docker compose exec -T --user www-data moodle php admin/cli/purge_caches.php

echo
echo "✔ Moodle instalado: https://$MOODLE_DOMAIN  (utilizador: $ADMIN_USER)"
echo "  Falta ativar os backups diários: ver README, passo 6."
