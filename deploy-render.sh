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
      RESOLVE_OUT=$(npx prisma migrate resolve --applied "$migration_name" --schema=prisma/schema.postgresql.prisma 2>&1) && echo "$RESOLVE_OUT" || {
        echo "$RESOLVE_OUT"
        # P3008 = deja marquee appliquee : rien a faire, ce n'est pas une erreur.
        echo "$RESOLVE_OUT" | grep -q "P3008" || { echo "❌ Echec du baseline sur $migration_name"; exit 1; }
      }
    fi
  done
  echo "🔄 Retrying migration deploy after baseline..."
  npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
elif grep -q "P3009" "$DEPLOY_LOG"; then
  # Un essai precedent (ex. avant correction d'un bug dans le SQL) a laisse
  # une migration enregistree en echec — Prisma bloque tout tant qu'elle
  # n'est pas explicitement resolue. On la marque "rolled-back" (pas
  # "applied" : on ne sait pas ce qui a reellement ete execute) puis on la
  # rejoue en entier — sans risque tant que le SQL de chaque migration est
  # idempotent (IF NOT EXISTS / EXCEPTION WHEN duplicate_object...).
  FAILED_NAME=$(sed -n "s/.*\`\([0-9A-Za-z_]*\)\`.*migration started.*/\1/p" "$DEPLOY_LOG" | head -1)
  if [ -z "$FAILED_NAME" ]; then
    echo "❌ P3009 detecte mais impossible d'identifier la migration en echec — abandon."
    rm -f "$DEPLOY_LOG"
    exit 1
  fi
  echo "⚠️ P3009 : migration '$FAILED_NAME' bloquee en echec depuis une tentative precedente — rollback puis nouvelle tentative."
  npx prisma migrate resolve --rolled-back "$FAILED_NAME" --schema=prisma/schema.postgresql.prisma
  echo "🔄 Retrying migration deploy after rollback..."
  npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
else
  echo "❌ Migration deploy failed pour une raison inattendue — abandon du deploiement (voir le log ci-dessus)."
  rm -f "$DEPLOY_LOG"
  exit 1
fi
rm -f "$DEPLOY_LOG"

echo "✅ Deployment complete!"
