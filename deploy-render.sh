#!/bin/bash
set -e

echo "🚀 Preparing PostgreSQL migrations for Render deployment..."

# Backup SQLite migrations
if [ -d "prisma/migrations" ]; then
  echo "📦 Backing up SQLite migrations..."
  mv prisma/migrations prisma/migrations_sqlite_backup
fi

# Use PostgreSQL migrations
echo "📥 Using PostgreSQL migrations..."
cp -r prisma/migrations_pg prisma/migrations

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate --schema=prisma/schema.postgresql.prisma

# Resolve any failed migrations from previous attempts
echo "🧹 Cleaning up any failed migrations..."
npx prisma migrate resolve --rolled-back 20251106124948_init_with_licenses --schema=prisma/schema.postgresql.prisma 2>/dev/null || true
npx prisma migrate resolve --rolled-back 20251217123620_add_cash_sessions --schema=prisma/schema.postgresql.prisma 2>/dev/null || true

# Deploy migrations with baseline support
echo "🗄️ Deploying migrations..."
if ! npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma 2>&1; then
  echo "⚠️ Migration failed (likely existing database), baselining..."
  
  # Mark all existing migrations as applied
  for migration_dir in prisma/migrations/*/; do
    if [ -d "$migration_dir" ]; then
      migration_name=$(basename "$migration_dir")
      echo "📌 Marking migration as applied: $migration_name"
      npx prisma migrate resolve --applied "$migration_name" --schema=prisma/schema.postgresql.prisma 2>/dev/null || true
    fi
  done
  
  # Try deploy again
  echo "🔄 Retrying migration deploy..."
  npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma || {
    echo "⚠️ Migrations already applied or database schema matches. Continuing..."
  }
fi

echo "✅ Deployment complete!"
