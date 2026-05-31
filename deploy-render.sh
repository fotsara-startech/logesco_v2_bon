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

# Deploy migrations
echo "🗄️ Deploying migrations..."
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma || {
  echo "⚠️ Migration failed, trying to baseline existing database..."
  npx prisma migrate resolve --applied 20260423221732_init_postgresql --schema=prisma/schema.postgresql.prisma
  npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
}

echo "✅ Deployment complete!"
