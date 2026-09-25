#!/bin/bash
set -e
set -o pipefail

echo "🚀 Preparing PostgreSQL migrations for Render deployment..."

# Use PostgreSQL migrations (le dossier prisma/migrations/ du repo est celui
# de SQLite, utilise par les postes clients — Render doit utiliser la copie
# Postgres dediee).
if [ -d "prisma/migrations" ]; then
  echo "📦 Backing up SQLite migrations..."
  mv prisma/migrations prisma/migrations_sqlite_backup
fi
echo "📥 Using PostgreSQL migrations..."
cp -r prisma/migrations_pg prisma/migrations

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate --schema=prisma/schema.postgresql.prisma

# Deploy migrations.
#
# IMPORTANT : ne JAMAIS baseliner (marquer "applique" sans executer le SQL)
# sur un simple echec generique — c'est exactement le bug qui a empeche les
# migrations commerciaux/parametres de s'appliquer chez les clients desktop
# (un outil qui rapporte un succes sans avoir reellement agi). Le baseline
# n'est legitime que dans deux cas reconnus :
#   - P3005 : la base existe deja AVEC des tables mais SANS historique
#     Prisma (premier deploiement sur une base geree manuellement).
#   - "already exists" / "duplicate" : les objets vises existent deja (ex.
#     colonnes creees par le self-heal runtime de sync-service.js depuis un
#     poste client) — l'effet voulu est deja en place, seul l'historique
#     Prisma est en retard.
# Toute autre erreur doit faire echouer le deploiement pour de vrai, afin
# que Render l'affiche comme en echec au lieu de le masquer.
echo "🗄️ Deploying migrations..."
DEPLOY_LOG=$(mktemp)
if npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma 2>&1 | tee "$DEPLOY_LOG"; then
  echo "✅ Migrations deployed."
elif grep -qiE "P3005|already exists|duplicate" "$DEPLOY_LOG"; then
  echo "⚠️ Base deja a jour ou sans historique Prisma — baseline des migrations connues (une seule fois)."
  for migration_dir in prisma/migrations/*/; do
    if [ -d "$migration_dir" ]; then
      migration_name=$(basename "$migration_dir")
      echo "📌 Marking migration as applied: $migration_name"
      npx prisma migrate resolve --applied "$migration_name" --schema=prisma/schema.postgresql.prisma
    fi
  done
  echo "🔄 Retrying migration deploy after baseline..."
  npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
else
  echo "❌ Migration deploy failed pour une raison inattendue — abandon du deploiement (voir le log ci-dessus)."
  rm -f "$DEPLOY_LOG"
  exit 1
fi
rm -f "$DEPLOY_LOG"

echo "✅ Deployment complete!"
