@echo off
echo ========================================
echo LOGESCO v2 - Build API Standalone
echo ========================================

cd /d "%~dp0\..\backend"

echo Installing pkg globally if not present...
npm list -g pkg >nul 2>&1 || npm install -g pkg

echo Installing dependencies...
npm install --production

echo Generating Prisma client...
npm run generate

echo Building standalone executable...
pkg . --target node18-win-x64 --output ../dist/logesco-api.exe

echo Creating config directory...
if not exist "..\dist\config" mkdir "..\dist\config"

echo Copying configuration files...
copy ".env.example" "..\dist\config\local.env"
copy "prisma\schema.prisma" "..\dist\config\"

echo API build completed!
echo Output: dist\logesco-api.exe

pause