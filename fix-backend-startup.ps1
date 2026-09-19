# ========================================
# FIX BACKEND STARTUP - LOGESCO (PowerShell)
# Alternative PowerShell au script Batch
# ========================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "CORRECTION DEMARRAGE BACKEND - LOGESCO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Determiner le chemin AppData\Local
$BackendDir = "$env:LOCALAPPDATA\LOGESCO\backend"
Write-Host "Repertoire backend: $BackendDir" -ForegroundColor White
Write-Host ""

if (-not (Test-Path $BackendDir)) {
    Write-Host "[ERREUR] Repertoire backend introuvable!" -ForegroundColor Red
    Write-Host "Le logiciel doit etre installe en premier." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}

Set-Location $BackendDir

# Arreter tous les processus node.exe en cours
Write-Host "[1] Arret des processus Node.js en cours..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "    [OK] Processus arretes" -ForegroundColor Green
Write-Host ""

# Verifier Node.js
Write-Host "[2] Verification de Node.js..." -ForegroundColor Yellow
$NodeExe = "$BackendDir\node.exe"
if (-not (Test-Path $NodeExe)) {
    Write-Host "    [WARN] Node.js portable absent, utilisation systeme..." -ForegroundColor Yellow
    $NodeExe = "node"
}
Write-Host "    Node.js: $NodeExe" -ForegroundColor White

try {
    $NodeVersion = & $NodeExe --version
    Write-Host "    Version: $NodeVersion" -ForegroundColor Green
} catch {
    Write-Host "    [ERREUR] Node.js introuvable!" -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}
Write-Host ""

# Creer le dossier database
Write-Host "[3] Verification du dossier database..." -ForegroundColor Yellow
if (-not (Test-Path "database")) {
    Write-Host "    Creation du dossier database..." -ForegroundColor White
    New-Item -ItemType Directory -Path "database" -Force | Out-Null
}
Write-Host "    [OK] Dossier database pret" -ForegroundColor Green
Write-Host ""

# Generer le client Prisma
Write-Host "[4] Generation du client Prisma..." -ForegroundColor Yellow
$PrismaClient = "node_modules\.prisma\client\index.js"
if (-not (Test-Path $PrismaClient)) {
    Write-Host "    Client Prisma absent, generation en cours..." -ForegroundColor White
    try {
        & $NodeExe "node_modules\prisma\build\index.js" generate 2>&1 | Out-Null
        Write-Host "    [OK] Client Prisma genere" -ForegroundColor Green
    } catch {
        Write-Host "    [ERREUR] Echec generation Prisma: $_" -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour quitter"
        exit 1
    }
} else {
    Write-Host "    [INFO] Client Prisma deja present, regeneration..." -ForegroundColor White
    & $NodeExe "node_modules\prisma\build\index.js" generate 2>&1 | Out-Null
    Write-Host "    [OK] Client Prisma regenere" -ForegroundColor Green
}
Write-Host ""

# Verifier/creer la base de donnees
Write-Host "[5] Verification de la base de donnees..." -ForegroundColor Yellow
$DbFile = "database\logesco.db"
if (-not (Test-Path $DbFile)) {
    Write-Host "    Base de donnees absente" -ForegroundColor White
    $TemplateDb = "database\logesco_template.db"
    if (Test-Path $TemplateDb) {
        Write-Host "    Copie du template..." -ForegroundColor White
        Copy-Item $TemplateDb $DbFile
        Write-Host "    [OK] Base de donnees copiee depuis template" -ForegroundColor Green
    } else {
        Write-Host "    [INFO] Template absent, creation au demarrage..." -ForegroundColor Yellow
    }
} else {
    Write-Host "    [OK] Base de donnees existe" -ForegroundColor Green
}
Write-Host ""

# Creer/corriger le fichier .env
Write-Host "[6] Correction du fichier .env..." -ForegroundColor Yellow
$DbPathFixed = "$BackendDir\database\logesco.db" -replace '\\', '/'
$Random = Get-Random -Minimum 100000 -Maximum 999999

$EnvContent = @"
NODE_ENV=production
PORT=8080
DATABASE_URL=file:$DbPathFixed
JWT_SECRET=logesco-secret-$Random
JWT_EXPIRES_IN=365d
CORS_ORIGIN=*
LOG_LEVEL=info
LOGESCO_DATA_DIR=$BackendDir
"@

Set-Content -Path ".env" -Value $EnvContent -Encoding UTF8
Write-Host "    [OK] Fichier .env cree/corrige" -ForegroundColor Green
Write-Host ""

# Nettoyer les anciens scripts
Write-Host "[7] Nettoyage des anciens scripts..." -ForegroundColor Yellow
Remove-Item "_logesco_start.cmd" -Force -ErrorAction SilentlyContinue
Remove-Item "_logesco_start.vbs" -Force -ErrorAction SilentlyContinue
Write-Host "    [OK] Scripts nettoyes" -ForegroundColor Green
Write-Host ""

# Creer un script de demarrage ameliore
Write-Host "[8] Creation des scripts de demarrage..." -ForegroundColor Yellow

# Script CMD
$CmdContent = @"
@echo off
cd /d "$BackendDir"
SET LOGESCO_DATA_DIR=$BackendDir
SET PORT=8080
SET NODE_ENV=production
SET DATABASE_URL=file:$DbPathFixed
"$NodeExe" "$BackendDir\src\server.js"
"@
Set-Content -Path "_logesco_start.cmd" -Value $CmdContent -Encoding ASCII

# Script VBS
$VbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
Dim cmd
cmd = "cmd.exe /C " & Chr(34) & "$BackendDir\_logesco_start.cmd" & Chr(34)
WshShell.Run cmd, 0, False
"@
Set-Content -Path "_logesco_start.vbs" -Value $VbsContent -Encoding ASCII

Write-Host "    [OK] Scripts crees" -ForegroundColor Green
Write-Host ""

# Tester le demarrage
Write-Host "[9] Test de demarrage du backend..." -ForegroundColor Yellow
Write-Host "    Demarrage en cours (patientez 15 secondes)..." -ForegroundColor White

Start-Process -FilePath $NodeExe -ArgumentList "src\server.js" -WorkingDirectory $BackendDir -WindowStyle Minimized
Start-Sleep -Seconds 15

Write-Host "    Test de connexion..." -ForegroundColor White
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    if ($Response.StatusCode -eq 200) {
        Write-Host "    [OK] Backend demarre avec succes!" -ForegroundColor Green
    } else {
        throw "Status code: $($Response.StatusCode)"
    }
} catch {
    Write-Host "    [ERREUR] Backend ne repond pas!" -ForegroundColor Red
    Write-Host "" 
    Write-Host "    Lecture des logs..." -ForegroundColor Yellow
    if (Test-Path "logs\backend-startup.log") {
        Write-Host "    --- DEBUT LOGS ---" -ForegroundColor Cyan
        Get-Content "logs\backend-startup.log" -Tail 40 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        Write-Host "    --- FIN LOGS ---" -ForegroundColor Cyan
    }
    Write-Host ""
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}
Write-Host ""

# Afficher les infos
Write-Host "[10] Test de l'API..." -ForegroundColor Yellow
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
    $Response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Cyan
} catch {
    Write-Host "    [WARN] Impossible de lire les infos de l'API" -ForegroundColor Yellow
}
Write-Host ""
Write-Host ""

# Arreter
Write-Host "[11] Arret du backend de test..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "    [OK] Backend arrete" -ForegroundColor Green
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "CORRECTION TERMINEE AVEC SUCCES!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Le backend peut maintenant demarrer correctement." -ForegroundColor White
Write-Host ""
Write-Host "Pour tester le demarrage automatique depuis Flutter:" -ForegroundColor Yellow
Write-Host "1. Fermez l'application LOGESCO si elle est ouverte" -ForegroundColor White
Write-Host "2. Relancez l'application" -ForegroundColor White
Write-Host "3. Le backend devrait demarrer automatiquement" -ForegroundColor White
Write-Host ""
Write-Host "Si le probleme persiste, executez:" -ForegroundColor Yellow
Write-Host "   diagnose-backend-startup.bat" -ForegroundColor Cyan
Write-Host ""
Read-Host "Appuyez sur Entree pour quitter"
