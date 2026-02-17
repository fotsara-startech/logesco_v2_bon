#!/bin/bash

echo "🚀 Configuration automatique du backend LOGESCO..."

cd backend

echo "📦 Installation des dépendances..."
npm install

echo "🔧 Génération du client Prisma..."
npx prisma generate

echo "🗄️ Configuration de la base de données..."
node scripts/setup-database.js

echo "✅ Configuration terminée!"
echo ""
echo "🌐 Démarrage du serveur..."
node start-with-setup.js