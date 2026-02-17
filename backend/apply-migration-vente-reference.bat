@echo off
echo ========================================
echo Migration: Ajout venteId et venteReference
echo ========================================
echo.

echo Etape 1: Creation de la migration...
npx prisma migrate dev --name add-vente-reference-to-transactions --create-only

echo.
echo Etape 2: Application de la migration...
npx prisma migrate deploy

echo.
echo Etape 3: Generation du client Prisma...
npx prisma generate

echo.
echo ========================================
echo Migration terminee avec succes!
echo ========================================
echo.
echo IMPORTANT: Redemarrez le backend pour charger le nouveau client Prisma
echo.
pause
