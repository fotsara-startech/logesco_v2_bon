#!/bin/bash

echo "========================================"
echo "LOGESCO v2 - Build API Standalone"
echo "========================================"

cd "$(dirname "$0")/../backend"

echo "Installing pkg globally if not present..."
npm list -g pkg >/dev/null 2>&1 || npm install -g pkg

echo "Installing dependencies..."
npm install --production

echo "Generating Prisma client..."
npm run generate

echo "Building standalone executable..."
pkg . --target node18-win-x64 --output ../dist/logesco-api.exe

echo "Creating config directory..."
mkdir -p ../dist/config

echo "Copying configuration files..."
cp .env.example ../dist/config/local.env
cp prisma/schema.prisma ../dist/config/

echo "API build completed!"
echo "Output: dist/logesco-api.exe"