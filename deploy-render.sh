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

# Deploy migrations
echo "🗄️ Deploying migrations..."
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma

echo "✅ Deployment preparation complete!"
