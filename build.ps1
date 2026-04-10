# =============================================================================
# LOGESCO v2 - Script de build interactif
# Remplace: build-installer.bat et build-client-network-installer.bat
# Usage: .\build.ps1  (depuis la racine du projet)
# =============================================================================

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Step($num, $total, $msg) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  ETAPE $num/$total : $msg" -ForegroundColor White
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Fail($msg) {
    Write-Host ""
    Write-Host "ERREUR: $msg" -ForegroundColor Red
    Write-Host ""
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}

# =============================================================================
# VERIFICATION DES PREREQUIS
# =============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   LOGESCO v2 - Build interactif" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[Prerequis] Verification..." -ForegroundColor Yellow
Write-Host ""

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Fail "Node.js non trouve. Installez Node.js 18+: https://nodejs.org/"
}
Write-Host "OK Node.js: $(node --version)" -ForegroundColor Green

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Fail "Flutter non trouve. Installez Flutter: https://flutter.dev/"
}
Write-Host "OK Flutter" -ForegroundColor Green

$isccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)
$ISCC = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ISCC) {
    Fail "InnoSetup 6 non trouve. Telechargez: https://jrsoftware.org/isdl.php"
}
Write-Host "OK InnoSetup: $ISCC" -ForegroundColor Green
Write-Host ""

# =============================================================================
# PARAMETRES DE BUILD
# =============================================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Configuration du build" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. MODE ---
Write-Host "1. Mode de deploiement" -ForegroundColor Yellow
Write-Host "   [1] Serveur local  - setup complet (frontend + backend) - defaut"
Write-Host "   [2] Client reseau  - setup leger (frontend uniquement, se connecte a un serveur)"
$modeInput = Read-Host "   Choix"
$isClientMode = ($modeInput -eq "2")
if ($isClientMode) {
    Write-Host "   -> Mode CLIENT RESEAU" -ForegroundColor Green
} else {
    Write-Host "   -> Mode SERVEUR LOCAL" -ForegroundColor Green
}
Write-Host ""

# --- 2. IP (mode client uniquement) ---
if ($isClientMode) {
    Write-Host "2. Adresse IP du serveur backend" -ForegroundColor Yellow
    Write-Host "   Exemple: 192.168.1.50"
    $ipInput = Read-Host "   IP du serveur"
    if ([string]::IsNullOrWhiteSpace($ipInput)) {
        Fail "L'adresse IP est obligatoire en mode client reseau."
    }
    $baseUrl = "http://${ipInput}:8080/api/v1"
    Write-Host "   -> $baseUrl" -ForegroundColor Green
    Write-Host ""
} else {
    $ipInput  = "local"
    $baseUrl  = "http://localhost:8080/api/v1"
}

# --- 3. LICENCE ---
Write-Host "3. Activer le controle de licence" -ForegroundColor Yellow
Write-Host "   [o] = active  |  [n] = desactive (defaut)"
$licenseInput = Read-Host "   ENABLE_LICENSE_CONTROL (o/n)"
$enableLicense = ($licenseInput -eq "o" -or $licenseInput -eq "O" -or $licenseInput -eq "y" -or $licenseInput -eq "Y")
Write-Host "   -> $enableLicense" -ForegroundColor Green
Write-Host ""

# --- Nommage ---
$clientSuffix  = if ($isClientMode) { "client" } else { "local" }
$licenseSuffix = if ($enableLicense) { "license-on" } else { "license-off" }
$ipSlug        = $ipInput -replace "\.", "-"
$setupName     = "LOGESCO-v2-${clientSuffix}-${licenseSuffix}-${ipSlug}-Setup"

$issFile  = if ($isClientMode) { "installer-setup-client-network.iss" } else { "installer-setup.iss" }

# --- Resume ---
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Resume" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Mode                   : $clientSuffix"
if ($isClientMode) {
    Write-Host "   BASE_URL               : $baseUrl"
}
Write-Host "   ENABLE_LICENSE_CONTROL : $enableLicense"
Write-Host "   Script InnoSetup       : $issFile"
Write-Host "   Setup final            : release\${setupName}.exe"
Write-Host ""

$confirm = Read-Host "Lancer le build ? (o/n)"
if ($confirm -ne "o" -and $confirm -ne "O" -and $confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Build annule." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter"
    exit 0
}

$dartDefines = "--dart-define=BASE_URL=$baseUrl " +
               "--dart-define=IS_CLIENT_MODE=$($isClientMode.ToString().ToLower()) " +
               "--dart-define=ENABLE_LICENSE_CONTROL=$($enableLicense.ToString().ToLower())"

$totalSteps = if ($isClientMode) { 3 } else { 4 }

# =============================================================================
# ETAPE 1 (mode local uniquement) : BUILD BACKEND
# =============================================================================

if (-not $isClientMode) {

    Write-Step 1 4 "Compilation du backend (node.exe portable)"

    Set-Location backend

    Write-Host "Arret des processus Node.js en cours..."
    taskkill /f /im node.exe 2>$null | Out-Null
    taskkill /f /im logesco-backend.exe 2>$null | Out-Null
    Start-Sleep -Seconds 2

    Write-Host "Installation des dependances backend..."
    & npm install
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "npm install echoue" }

    Write-Host ""
    Write-Host "Generation du client Prisma..."
    & npx prisma generate
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "prisma generate echoue" }

    Write-Host ""
    Write-Host "Preparation du backend portable (node.exe + node_modules)..."
    & node build-exe.js
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "build-exe.js echoue" }

    Set-Location ..

    if (-not (Test-Path "dist-exe\node.exe"))      { Fail "dist-exe\node.exe introuvable apres build backend" }
    if (-not (Test-Path "dist-exe\src\server.js")) { Fail "dist-exe\src\server.js introuvable apres build backend" }

    Write-Host ""
    Write-Host "OK Backend pret: dist-exe\node.exe + dist-exe\src\server.js" -ForegroundColor Green
}

# =============================================================================
# ETAPE 2 (local) / ETAPE 1 (client) : BUILD FLUTTER
# =============================================================================

$flutterStep = if ($isClientMode) { 1 } else { 2 }
Write-Step $flutterStep $totalSteps "Build Flutter Windows"

Set-Location logesco_v2

Write-Host "Nettoyage Flutter..."
& flutter clean 2>$null | Out-Null

Write-Host "Recuperation des dependances..."
& flutter pub get
if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter pub get echoue" }

Write-Host "Build Windows release..."
Write-Host "  flutter build windows --release $dartDefines" -ForegroundColor DarkGray
Invoke-Expression "flutter build windows --release $dartDefines"
if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter build windows echoue" }

Set-Location ..

$flutterExe = "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe"
if (-not (Test-Path $flutterExe)) {
    Fail "logesco_v2.exe introuvable apres build Flutter. Verifiez: logesco_v2\build\windows\x64\runner\Release\"
}
Write-Host ""
Write-Host "OK Flutter build: $flutterExe" -ForegroundColor Green

# =============================================================================
# ETAPE 3 (local) / ETAPE 2 (client) : INNOSETUP
# =============================================================================

$innoStep = if ($isClientMode) { 2 } else { 3 }
Write-Step $innoStep $totalSteps "Compilation de l'installeur InnoSetup"

if (-not (Test-Path "release")) { New-Item -ItemType Directory -Path "release" | Out-Null }

if (-not (Test-Path $issFile)) { Fail "Fichier $issFile introuvable" }

Write-Host "Compilation: $issFile -> release\${setupName}.exe"
& $ISCC "/DSetupName=$setupName" $issFile
if ($LASTEXITCODE -ne 0) { Fail "InnoSetup a echoue. Verifiez $issFile" }

# =============================================================================
# ETAPE 4 (local) / ETAPE 3 (client) : VERIFICATION + RENOMMAGE
# =============================================================================

$finalStep = if ($isClientMode) { 3 } else { 4 }
Write-Step $finalStep $totalSteps "Verification du setup final"

# InnoSetup utilise {#SetupName} donc le fichier devrait deja avoir le bon nom.
# Si ce n'est pas le cas (ancien .iss sans #ifdef), on renomme le dernier .exe genere.
$targetPath = "release\${setupName}.exe"
if (-not (Test-Path $targetPath)) {
    $latest = Get-ChildItem "release\*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        Rename-Item -Path $latest.FullName -NewName "${setupName}.exe"
        Write-Host "Renomme: $($latest.Name) -> ${setupName}.exe" -ForegroundColor DarkGray
    } else {
        Fail "Aucun setup .exe trouve dans release\ apres InnoSetup"
    }
}

if (-not (Test-Path $targetPath)) {
    Fail "Setup introuvable: $targetPath"
}

# =============================================================================
# RESULTAT
# =============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   BUILD TERMINE AVEC SUCCES" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "   Installeur : release\${setupName}.exe" -ForegroundColor Green
Write-Host ""

if (-not $isClientMode) {
    Write-Host "   Ce setup installe chez le client :" -ForegroundColor DarkGray
    Write-Host "     - logesco_v2.exe dans Program Files\LOGESCO" -ForegroundColor DarkGray
    Write-Host "     - Backend Node.js dans AppData\Local\LOGESCO\backend" -ForegroundColor DarkGray
    Write-Host "     - Base de donnees locale (SQLite)" -ForegroundColor DarkGray
    Write-Host "     - Raccourci bureau + menu Demarrer" -ForegroundColor DarkGray
    Write-Host "     - Identifiants par defaut: admin / admin123" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Mise a jour d'un client existant :" -ForegroundColor DarkGray
    Write-Host "     - Relancer le setup sur la machine client" -ForegroundColor DarkGray
    Write-Host "     - Les donnees (logesco.db, uploads) sont conservees" -ForegroundColor DarkGray
    Write-Host "     - Les migrations Prisma s'appliquent automatiquement" -ForegroundColor DarkGray
} else {
    Write-Host "   Ce setup installe chez le client :" -ForegroundColor DarkGray
    Write-Host "     - logesco_v2.exe configure pour: $baseUrl" -ForegroundColor DarkGray
    Write-Host "     - Aucun backend, aucune base de donnees locale" -ForegroundColor DarkGray
    Write-Host "     - Raccourci bureau + menu Demarrer" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Pour distribuer :" -ForegroundColor DarkGray
    Write-Host "     1. Copiez release\${setupName}.exe" -ForegroundColor DarkGray
    Write-Host "     2. Fournissez les identifiants de connexion" -ForegroundColor DarkGray
}

Write-Host ""
Read-Host "Appuyez sur Entree pour quitter"
