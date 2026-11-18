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
# InnoSetup n'est requis que pour les installeurs Windows (modes 1 et 2) : la
# verification bloquante est faite plus bas, une fois le mode choisi.
if ($ISCC) {
    Write-Host "OK InnoSetup: $ISCC" -ForegroundColor Green
} else {
    Write-Host "-- InnoSetup 6 non trouve (necessaire uniquement pour les installeurs Windows)" -ForegroundColor DarkYellow
}
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
Write-Host "   [3] Web (Flutter)  - compile pour le web avec API Render"
Write-Host "   [4] Mobile Android - APK / AAB (client leger, se connecte a un serveur)"
$modeInput = Read-Host "   Choix"
$isClientMode = ($modeInput -eq "2")
$isWebMode = ($modeInput -eq "3")
$isMobileMode = ($modeInput -eq "4")
if ($isWebMode) {
    Write-Host "   -> Mode WEB (Flutter Web)" -ForegroundColor Green
} elseif ($isMobileMode) {
    Write-Host "   -> Mode MOBILE ANDROID" -ForegroundColor Green
} elseif ($isClientMode) {
    Write-Host "   -> Mode CLIENT RESEAU" -ForegroundColor Green
} else {
    Write-Host "   -> Mode SERVEUR LOCAL" -ForegroundColor Green
}
Write-Host ""

if (-not $isWebMode -and -not $isMobileMode -and -not $ISCC) {
    Fail "InnoSetup 6 non trouve. Telechargez: https://jrsoftware.org/isdl.php"
}

# --- 2. IP (mode client uniquement) ---
if ($isMobileMode) {
    Write-Host "2. Adresse du serveur backend (mode Mobile)" -ForegroundColor Yellow
    Write-Host "   L'app mobile n'embarque pas de backend : elle se connecte a un serveur."
    Write-Host "   Exemple reseau local : http://192.168.1.50:8080"
    Write-Host "   Exemple en ligne     : https://logesco-smart-energy.onrender.com"
    $apiUrlInput = Read-Host "   URL du serveur"
    if ([string]::IsNullOrWhiteSpace($apiUrlInput)) {
        Fail "L'URL du serveur est obligatoire en mode mobile."
    }
    $apiUrlInput = $apiUrlInput.Trim().TrimEnd('/')
    # Sans schema, on suppose du HTTP (serveur sur le reseau local)
    if ($apiUrlInput -notmatch '^https?://') {
        $apiUrlInput = "http://$apiUrlInput"
    }
    # Sans port ni domaine en ligne, le backend ecoute sur 8080
    if ($apiUrlInput -match '^http://[^/:]+$') {
        $apiUrlInput = "${apiUrlInput}:8080"
    }
    if (-not $apiUrlInput.EndsWith('/api/v1')) {
        $baseUrl = "$apiUrlInput/api/v1"
    } else {
        $baseUrl = $apiUrlInput
    }
    $ipInput = "mobile"
    Write-Host "   -> $baseUrl" -ForegroundColor Green
    Write-Host ""
} elseif ($isWebMode) {
    Write-Host "2. URL de l'API backend (mode Web)" -ForegroundColor Yellow
    Write-Host "   Exemple: https://logesco-smart-energy.onrender.com"
    Write-Host "   Exemple: https://api.mondomaine.com"
    $apiUrlInput = Read-Host "   URL de l'API"
    if ([string]::IsNullOrWhiteSpace($apiUrlInput)) {
        Fail "L'URL de l'API est obligatoire en mode web."
    }
    # Nettoyer l'URL (enlever le trailing slash si présent)
    $apiUrlInput = $apiUrlInput.TrimEnd('/')
    # Ajouter /api/v1 si pas déjà présent
    if (-not $apiUrlInput.EndsWith('/api/v1')) {
        $baseUrl = "$apiUrlInput/api/v1"
    } else {
        $baseUrl = $apiUrlInput
    }
    $ipInput = "web"
    Write-Host "   -> $baseUrl" -ForegroundColor Green
    Write-Host ""
} elseif ($isClientMode) {
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
if (-not $isWebMode) {
    Write-Host "3. Activer le controle de licence" -ForegroundColor Yellow
    Write-Host "   [o] = active  |  [n] = desactive (defaut)"
    $licenseInput = Read-Host "   ENABLE_LICENSE_CONTROL (o/n)"
    $enableLicense = ($licenseInput -eq "o" -or $licenseInput -eq "O" -or $licenseInput -eq "y" -or $licenseInput -eq "Y")
    Write-Host "   -> $enableLicense" -ForegroundColor Green
    Write-Host ""
} else {
    # Pas de contrôle de licence pour le web
    $enableLicense = $false
}

# --- 4. FORMAT + VERSION (mode mobile uniquement) ---
$buildApk = $true
$buildAab = $false
$buildNameArgs = ""
if ($isMobileMode) {
    Write-Host "4. Format de sortie Android" -ForegroundColor Yellow
    Write-Host "   [1] APK - installation directe sur les telephones - defaut"
    Write-Host "   [2] AAB - publication sur le Google Play Store"
    Write-Host "   [3] Les deux"
    $formatInput = Read-Host "   Choix"
    $buildApk = ($formatInput -ne "2")
    $buildAab = ($formatInput -eq "2" -or $formatInput -eq "3")
    Write-Host ""

    Write-Host "5. Version de l'app (optionnel)" -ForegroundColor Yellow
    $pubspecVersion = (Select-String -Path "logesco_v2\pubspec.yaml" -Pattern '^version:\s*(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    Write-Host "   Version actuelle (pubspec.yaml) : $pubspecVersion"
    Write-Host "   Laissez vide pour la conserver. Le numero de build doit augmenter a chaque publication Play Store."
    $buildNameInput = Read-Host "   Nom de version (ex: 1.2.0)"
    $buildNumberInput = Read-Host "   Numero de build (entier, ex: 12)"
    if (-not [string]::IsNullOrWhiteSpace($buildNameInput))   { $buildNameArgs += " --build-name=$($buildNameInput.Trim())" }
    if (-not [string]::IsNullOrWhiteSpace($buildNumberInput)) { $buildNameArgs += " --build-number=$($buildNumberInput.Trim())" }
    Write-Host ""
}

# --- Nommage ---
if ($isMobileMode) {
    $clientSuffix = "mobile"
    $licenseSuffix = if ($enableLicense) { "license-on" } else { "license-off" }
    $domainSlug = ($baseUrl -replace 'https?://', '' -replace '/api/v1$', '' -replace '[^A-Za-z0-9]+', '-').Trim('-')
    $ipSlug = $domainSlug
    $setupName = "LOGESCO-v2-mobile-android-${licenseSuffix}-${domainSlug}"
} elseif ($isWebMode) {
    $clientSuffix = "web"
    $licenseSuffix = ""
    # Extraire un slug du domaine pour le nom du build
    $domainSlug = ($baseUrl -replace 'https?://', '' -replace '/.*', '' -replace '\.', '-')
    $ipSlug = $domainSlug
    $setupName = "LOGESCO-v2-web-${domainSlug}"
} else {
    $clientSuffix  = if ($isClientMode) { "client" } else { "local" }
    $licenseSuffix = if ($enableLicense) { "license-on" } else { "license-off" }
    $ipSlug        = $ipInput -replace "\.", "-"
    $setupName     = "LOGESCO-v2-${clientSuffix}-${licenseSuffix}-${ipSlug}-Setup"
}

$issFile  = if ($isClientMode) { "installer-setup-client-network.iss" } else { "installer-setup.iss" }

# --- Resume ---
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Resume" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
if ($isMobileMode) {
    $formats = @(); if ($buildApk) { $formats += "APK" }; if ($buildAab) { $formats += "AAB" }
    Write-Host "   Mode                   : MOBILE ANDROID ($($formats -join ' + '))"
    Write-Host "   BASE_URL               : $baseUrl"
    Write-Host "   ENABLE_LICENSE_CONTROL : $enableLicense"
    Write-Host "   Version                : $(if ($buildNameArgs) { $buildNameArgs.Trim() } else { 'celle de pubspec.yaml' })"
    Write-Host "   Sortie                 : release\${setupName}.apk / .aab"
} elseif ($isWebMode) {
    Write-Host "   Mode                   : WEB (Flutter Web)"
    Write-Host "   BASE_URL               : $baseUrl"
    Write-Host "   Output                 : logesco_v2\build\web\"
} else {
    Write-Host "   Mode                   : $clientSuffix"
    if ($isClientMode) {
        Write-Host "   BASE_URL               : $baseUrl"
    }
    Write-Host "   ENABLE_LICENSE_CONTROL : $enableLicense"
    Write-Host "   Script InnoSetup       : $issFile"
    Write-Host "   Setup final            : release\${setupName}.exe"
}
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

$totalSteps = if ($isWebMode) { 1 } elseif ($isClientMode) { 3 } else { 4 }

# =============================================================================
# MODE MOBILE ANDROID : BUILD FLUTTER APK / AAB (client leger, pas de backend)
# =============================================================================

function Find-Keytool {
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += (Join-Path $env:JAVA_HOME "bin\keytool.exe") }
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { $candidates += $cmd.Source }
    $candidates += @(
        "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
        "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe"
    )
    $candidates += (Get-ChildItem "C:\Program Files\Eclipse Adoptium\*\bin\keytool.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $candidates += (Get-ChildItem "C:\Program Files\Java\*\bin\keytool.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    return $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

if ($isMobileMode) {
    Write-Step 1 1 "Build Flutter Android"

    # --- Cle de signature (android\key.properties) ---
    $keyProps = "logesco_v2\android\key.properties"
    if (-not (Test-Path $keyProps)) {
        Write-Host "Aucune cle de signature trouvee (logesco_v2\android\key.properties)." -ForegroundColor Yellow
        Write-Host "  Sans cle, l'APK est signe avec la cle de debug : suffisant pour l'installer a la main,"
        Write-Host "  mais impossible a publier sur le Play Store ni a mettre a jour avec une autre cle."
        $genKey = Read-Host "Creer une cle de signature maintenant ? (o/n)"
        if ($genKey -eq "o" -or $genKey -eq "O" -or $genKey -eq "y" -or $genKey -eq "Y") {
            $keytool = Find-Keytool
            if (-not $keytool) {
                Write-Host "keytool introuvable (installez Android Studio ou un JDK). Build signe avec la cle de debug." -ForegroundColor Yellow
            } else {
                $secure = Read-Host "Mot de passe de la cle (6 caracteres minimum)" -AsSecureString
                $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
                if ($plain.Length -lt 6) { Fail "Mot de passe trop court (6 caracteres minimum)." }
                $jksPath = "logesco_v2\android\logesco-release.jks"
                & $keytool -genkeypair -v -keystore $jksPath -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 `
                    -alias logesco -storepass $plain -keypass $plain -dname "CN=LOGESCO, O=LOGESCO"
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jksPath)) { Fail "Creation de la cle echouee" }
                @(
                    "storePassword=$plain",
                    "keyPassword=$plain",
                    "keyAlias=logesco",
                    "storeFile=logesco-release.jks"
                ) | Set-Content -Path $keyProps -Encoding ASCII
                Write-Host ""
                Write-Host "OK Cle creee : logesco_v2\android\logesco-release.jks" -ForegroundColor Green
                Write-Host "   IMPORTANT : sauvegardez logesco-release.jks et key.properties hors du projet." -ForegroundColor Yellow
                Write-Host "   Si vous les perdez, vous ne pourrez plus mettre a jour l'app deja installee / publiee." -ForegroundColor Yellow
                Write-Host ""
            }
        }
    }
    $signedWithRelease = Test-Path $keyProps

    Set-Location logesco_v2

    Write-Host "Nettoyage Flutter..."
    & flutter clean 2>$null | Out-Null

    Write-Host "Recuperation des dependances..."
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter pub get echoue" }

    # Le SDK Android dans un chemin avec espaces (ex: C:\Users\Prenom Nom\...) fait echouer
    # certains outils (NDK). Avertissement seulement : le build peut quand meme passer.
    $sdkDir = $null
    if (Test-Path "android\local.properties") {
        $sdkLine = Select-String -Path "android\local.properties" -Pattern '^sdk\.dir=(.+)$' | Select-Object -First 1
        if ($sdkLine) { $sdkDir = $sdkLine.Matches.Groups[1].Value -replace '\\\\', '\' }
    }
    if (-not $sdkDir) { $sdkDir = $env:ANDROID_HOME }
    if (-not $sdkDir) { $sdkDir = $env:ANDROID_SDK_ROOT }
    if (-not $sdkDir) {
        Set-Location ..
        Fail "SDK Android introuvable. Installez Android Studio puis lancez: flutter doctor --android-licenses"
    }
    if ($sdkDir -match ' ') {
        Write-Host "ATTENTION: le SDK Android est dans un chemin avec espaces ($sdkDir)." -ForegroundColor Yellow
        Write-Host "  Si le build echoue, deplacez-le (ex: C:\Android\sdk) puis: flutter config --android-sdk C:\Android\sdk" -ForegroundColor Yellow
        Write-Host ""
    }

    # IS_CLIENT_MODE=true : pas de backend embarque sur le telephone.
    $mobileDefines = "--dart-define=BASE_URL=$baseUrl " +
                     "--dart-define=IS_CLIENT_MODE=true " +
                     "--dart-define=ENABLE_LICENSE_CONTROL=$($enableLicense.ToString().ToLower())"

    if ($buildApk) {
        Write-Host "Build APK release..."
        Write-Host "  flutter build apk --release $mobileDefines$buildNameArgs" -ForegroundColor DarkGray
        Invoke-Expression "flutter build apk --release $mobileDefines$buildNameArgs"
        if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter build apk echoue" }
    }
    if ($buildAab) {
        Write-Host "Build AAB release (Play Store)..."
        Write-Host "  flutter build appbundle --release $mobileDefines$buildNameArgs" -ForegroundColor DarkGray
        Invoke-Expression "flutter build appbundle --release $mobileDefines$buildNameArgs"
        if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter build appbundle echoue" }
    }

    Set-Location ..

    if (-not (Test-Path "release")) { New-Item -ItemType Directory -Path "release" | Out-Null }
    $apkSrc = "logesco_v2\build\app\outputs\flutter-apk\app-release.apk"
    $aabSrc = "logesco_v2\build\app\outputs\bundle\release\app-release.aab"
    $outputs = @()
    if ($buildApk) {
        if (-not (Test-Path $apkSrc)) { Fail "APK introuvable apres build. Verifiez: $apkSrc" }
        Copy-Item $apkSrc "release\${setupName}.apk" -Force
        $outputs += "release\${setupName}.apk"
    }
    if ($buildAab) {
        if (-not (Test-Path $aabSrc)) { Fail "AAB introuvable apres build. Verifiez: $aabSrc" }
        Copy-Item $aabSrc "release\${setupName}.aab" -Force
        $outputs += "release\${setupName}.aab"
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "   BUILD MOBILE TERMINE AVEC SUCCES" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    foreach ($o in $outputs) { Write-Host "   Fichier : $o" -ForegroundColor Green }
    Write-Host ""
    Write-Host "   L'app se connecte a : $baseUrl" -ForegroundColor DarkGray
    if (-not $signedWithRelease) {
        Write-Host "   Signature : cle de debug (installation manuelle uniquement, pas de Play Store)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "   Installer l'APK sur un telephone :" -ForegroundColor DarkGray
    Write-Host "     - copiez le .apk sur le telephone (cable, WhatsApp, Drive) et ouvrez-le" -ForegroundColor DarkGray
    Write-Host "       (autoriser les sources inconnues si Android le demande)" -ForegroundColor DarkGray
    Write-Host "     - ou en USB : adb install -r <fichier.apk>" -ForegroundColor DarkGray
    Write-Host "   Le telephone doit pouvoir joindre le serveur (meme Wi-Fi pour une IP locale)." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   iOS : le dossier logesco_v2\ios est pret, mais la compilation iOS (flutter build ipa)" -ForegroundColor DarkGray
    Write-Host "   n'est possible que sur un Mac avec Xcode." -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur Entree pour quitter"
    exit 0
}

# =============================================================================
# ETAPE 1 (mode local uniquement) : BUILD BACKEND
# =============================================================================

if (-not $isClientMode -and -not $isWebMode) {

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
# ETAPE 2 (local) / ETAPE 1 (client/web) : BUILD FLUTTER
# =============================================================================

if ($isWebMode) {
    Write-Step 1 1 "Build Flutter Web"
    
    Set-Location logesco_v2
    
    Write-Host "Nettoyage Flutter..."
    & flutter clean 2>$null | Out-Null
    
    Write-Host "Recuperation des dependances..."
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter pub get echoue" }
    
    Write-Host "Build Web release..."
    Write-Host "  flutter build web --release $dartDefines" -ForegroundColor DarkGray
    Invoke-Expression "flutter build web --release $dartDefines"
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter build web echoue" }
    
    Set-Location ..
    
    $webOutput = "logesco_v2\build\web"
    if (-not (Test-Path "$webOutput\index.html")) {
        Fail "index.html introuvable apres build web. Verifiez: $webOutput"
    }
    
    Write-Host ""
    Write-Host "OK Flutter Web build: $webOutput" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "   BUILD WEB TERMINE AVEC SUCCES" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Dossier de sortie : $webOutput" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Pour deployer :" -ForegroundColor DarkGray
    Write-Host "     1. Uploadez le contenu de $webOutput sur votre hebergeur web" -ForegroundColor DarkGray
    Write-Host "     2. Configurez votre serveur web (Nginx, Apache, etc.)" -ForegroundColor DarkGray
    Write-Host "     3. L'app se connectera automatiquement a: $baseUrl" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Appuyez sur Entree pour quitter"
    exit 0
}

$flutterStep = if ($isClientMode) { 1 } else { 2 }
Write-Step $flutterStep $totalSteps "Build Flutter Windows"

Set-Location logesco_v2

# Le plugin "printing" telecharge pdfium depuis GitHub a chaque build apres
# un "flutter clean". Sur une connexion lente ce telechargement echoue
# ("Build step for pdfium failed"), on garde donc pdfium en cache hors de build\.
$pdfiumBuildDir = "build\windows\x64"
$pdfiumCacheDir = Join-Path $env:LOCALAPPDATA "LogescoBuildCache\pdfium"
function Save-PdfiumCache {
    if (Test-Path "$pdfiumBuildDir\pdfium-src\PDFiumConfig.cmake") {
        Remove-Item -Recurse -Force $pdfiumCacheDir -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force $pdfiumCacheDir | Out-Null
        Copy-Item -Recurse "$pdfiumBuildDir\pdfium-download", "$pdfiumBuildDir\pdfium-src" $pdfiumCacheDir
    }
}
Save-PdfiumCache

Write-Host "Nettoyage Flutter..."
& flutter clean 2>$null | Out-Null

if (Test-Path "$pdfiumCacheDir\pdfium-src\PDFiumConfig.cmake") {
    Write-Host "Restauration de pdfium depuis le cache local..."
    New-Item -ItemType Directory -Force $pdfiumBuildDir | Out-Null
    Copy-Item -Recurse "$pdfiumCacheDir\pdfium-download", "$pdfiumCacheDir\pdfium-src" $pdfiumBuildDir
}

Write-Host "Recuperation des dependances..."
& flutter pub get
if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter pub get echoue" }

Write-Host "Build Windows release..."
Write-Host "  flutter build windows --release $dartDefines" -ForegroundColor DarkGray
$maxBuildAttempts = 3
for ($attempt = 1; $attempt -le $maxBuildAttempts; $attempt++) {
    Invoke-Expression "flutter build windows --release $dartDefines"
    if ($LASTEXITCODE -eq 0) { break }
    if ($attempt -lt $maxBuildAttempts) {
        Write-Host "Build echoue (tentative $attempt/$maxBuildAttempts), nouvel essai..." -ForegroundColor Yellow
    }
}
if ($LASTEXITCODE -ne 0) { Set-Location ..; Fail "flutter build windows echoue" }
Save-PdfiumCache

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
