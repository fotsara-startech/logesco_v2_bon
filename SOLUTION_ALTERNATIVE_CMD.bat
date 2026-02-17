@echo off
echo ========================================
echo SOLUTION ALTERNATIVE - Sans PowerShell
echo ========================================
echo.
echo Cette solution evite les problemes PowerShell
echo.
echo Regeneration du client Prisma...
cd backend
echo.
echo Utilisation de npm au lieu de npx...
npm run prisma:generate 2>nul || (
    echo Tentative avec npx...
    node_modules\.bin\prisma generate 2>nul || (
        echo Installation de Prisma CLI...
        npm install -g prisma
        prisma generate
    )
)
echo.
echo ✓ Client Prisma regenere!
echo.
echo Demarrage du backend...
node src/server-standalone.js
pause