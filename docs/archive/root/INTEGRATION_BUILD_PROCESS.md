# Intégration dans le Processus de Build

## 🎯 Objectif

Intégrer les corrections de démarrage du backend dans votre processus de build et de déploiement pour que tous les futurs clients bénéficient de la solution.

## 📋 Étapes d'Intégration

### 1. Mise à Jour du Code Source

```bash
# 1. Vérifier les modifications
git status

# 2. Committer les changements
git add logesco_v2/lib/core/services/backend_service.dart
git commit -m "fix: amélioration démarrage automatique backend

- Ajout vérification et génération automatique client Prisma
- Ajout création automatique dossiers database/ et logs/
- Ajout copie automatique template base de données
- Ajout lecture logs en cas d'échec démarrage
- Amélioration fichier .env avec chemins absolus
- Ajout variable LOGESCO_DATA_DIR dans .env"

# 3. Ajouter les scripts de support
git add fix-backend-startup.bat
git add diagnose-backend-startup.bat
git add prepare-portable-backend.bat
git add GUIDE_FIX_DEMARRAGE_BACKEND.md
git add LIRE_MOI_PROBLEME_DEMARRAGE.txt
git commit -m "feat: ajout scripts diagnostic et correction backend"

# 4. Pousser vers le repository
git push origin main
```

### 2. Modification du Script de Build

Créez ou modifiez votre script de build pour inclure la préparation du backend.

#### Option A : Script Batch (`build-release.bat`)

```batch
@echo off
echo ========================================
echo BUILD LOGESCO - VERSION PRODUCTION
echo ========================================
echo.

echo [1/6] Nettoyage...
if exist "build\" rmdir /s /q build
if exist "release\" rmdir /s /q release

echo [2/6] Build Flutter...
cd logesco_v2
call flutter pub get
call flutter build windows --release
cd ..

echo [3/6] Preparation backend...
cd backend
call ..\prepare-portable-backend.bat
if errorlevel 1 (
    echo [ERREUR] Echec preparation backend
    pause
    exit /b 1
)
cd ..

echo [4/6] Copie des fichiers...
mkdir release\LOGESCO
xcopy /E /I logesco_v2\build\windows\runner\Release release\LOGESCO\
mkdir release\LOGESCO\backend
xcopy /E /I backend release\LOGESCO\backend\

echo [5/6] Copie scripts support...
copy fix-backend-startup.bat release\LOGESCO\
copy diagnose-backend-startup.bat release\LOGESCO\
copy LIRE_MOI_PROBLEME_DEMARRAGE.txt release\LOGESCO\
mkdir release\LOGESCO\Documentation
copy GUIDE_FIX_DEMARRAGE_BACKEND.md release\LOGESCO\Documentation\

echo [6/6] Creation installeur...
REM Appeler votre script de creation d'installeur ici
REM makensis.exe installer.nsi
REM ou
REM iscc.exe installer.iss

echo.
echo ========================================
echo BUILD TERMINE AVEC SUCCES!
echo ========================================
pause
```

#### Option B : Script PowerShell (`build-release.ps1`)

```powershell
Write-Host "========================================"
Write-Host "BUILD LOGESCO - VERSION PRODUCTION"
Write-Host "========================================"
Write-Host ""

# 1. Nettoyage
Write-Host "[1/6] Nettoyage..."
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "release" -Recurse -Force -ErrorAction SilentlyContinue

# 2. Build Flutter
Write-Host "[2/6] Build Flutter..."
Set-Location logesco_v2
flutter pub get
flutter build windows --release
Set-Location ..

# 3. Préparation backend
Write-Host "[3/6] Preparation backend..."
Set-Location backend
& ..\prepare-portable-backend.bat
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Echec preparation backend"
    exit 1
}
Set-Location ..

# 4. Copie des fichiers
Write-Host "[4/6] Copie des fichiers..."
New-Item -ItemType Directory -Path "release\LOGESCO" -Force
Copy-Item -Path "logesco_v2\build\windows\runner\Release\*" -Destination "release\LOGESCO\" -Recurse
New-Item -ItemType Directory -Path "release\LOGESCO\backend" -Force
Copy-Item -Path "backend\*" -Destination "release\LOGESCO\backend\" -Recurse

# 5. Copie scripts support
Write-Host "[5/6] Copie scripts support..."
Copy-Item "fix-backend-startup.bat" "release\LOGESCO\"
Copy-Item "diagnose-backend-startup.bat" "release\LOGESCO\"
Copy-Item "LIRE_MOI_PROBLEME_DEMARRAGE.txt" "release\LOGESCO\"
New-Item -ItemType Directory -Path "release\LOGESCO\Documentation" -Force
Copy-Item "GUIDE_FIX_DEMARRAGE_BACKEND.md" "release\LOGESCO\Documentation\"

# 6. Création installeur
Write-Host "[6/6] Creation installeur..."
# Votre commande de création d'installeur ici

Write-Host ""
Write-Host "========================================"
Write-Host "BUILD TERMINE AVEC SUCCES!"
Write-Host "========================================"
```

### 3. Modification du Script d'Installation (NSIS)

Si vous utilisez NSIS pour créer l'installeur :

```nsis
; installer.nsi
!define APPNAME "LOGESCO"
!define APPVERSION "2.0"
!define PUBLISHER "Votre Entreprise"

Name "${APPNAME} ${APPVERSION}"
OutFile "LOGESCO-Setup-${APPVERSION}.exe"
InstallDir "$LOCALAPPDATA\${APPNAME}"
RequestExecutionLevel user

; Pages
Page directory
Page instfiles

Section "Installation Principale"
  SetOutPath "$INSTDIR"
  
  ; Copier l'application Flutter
  File /r "release\LOGESCO\*.*"
  
  ; Créer les dossiers backend
  CreateDirectory "$INSTDIR\backend\database"
  CreateDirectory "$INSTDIR\backend\logs"
  
  ; Copier le backend
  SetOutPath "$INSTDIR\backend"
  File /r "release\LOGESCO\backend\*.*"
  
  ; Générer le client Prisma
  DetailPrint "Generation du client Prisma..."
  nsExec::ExecToLog '"$INSTDIR\backend\node.exe" "$INSTDIR\backend\node_modules\prisma\build\index.js" generate'
  Pop $0 ; code de retour
  ${If} $0 != 0
    MessageBox MB_ICONEXCLAMATION "Avertissement: La generation du client Prisma a echoue. Le backend le generera automatiquement au premier demarrage."
  ${EndIf}
  
  ; Copier le template de base de données
  ${If} ${FileExists} "$INSTDIR\backend\database\logesco_template.db"
    DetailPrint "Copie du template de base de donnees..."
    CopyFiles "$INSTDIR\backend\database\logesco_template.db" "$INSTDIR\backend\database\logesco.db"
  ${EndIf}
  
  ; Créer le fichier .env
  DetailPrint "Creation du fichier .env..."
  FileOpen $0 "$INSTDIR\backend\.env" w
  FileWrite $0 "NODE_ENV=production$\r$\n"
  FileWrite $0 "PORT=8080$\r$\n"
  
  ; Convertir les backslashes en slashes pour DATABASE_URL
  ${StrRep} $1 "$INSTDIR\backend\database\logesco.db" "\" "/"
  FileWrite $0 "DATABASE_URL=file:$1$\r$\n"
  
  FileWrite $0 "JWT_SECRET=logesco-secret-$RANDOM$\r$\n"
  FileWrite $0 "JWT_EXPIRES_IN=365d$\r$\n"
  FileWrite $0 "CORS_ORIGIN=*$\r$\n"
  FileWrite $0 "LOG_LEVEL=info$\r$\n"
  FileWrite $0 "LOGESCO_DATA_DIR=$INSTDIR\backend$\r$\n"
  FileClose $0
  
  ; Créer les raccourcis
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\logesco_v2.exe"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Corriger Backend.lnk" "$INSTDIR\fix-backend-startup.bat"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Diagnostic Backend.lnk" "$INSTDIR\diagnose-backend-startup.bat"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Desinstaller.lnk" "$INSTDIR\uninstall.exe"
  CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\logesco_v2.exe"
  
  ; Créer le désinstalleur
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Enregistrer dans Ajout/Suppression de programmes
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${APPVERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${PUBLISHER}"
  
  DetailPrint "Installation terminee avec succes!"
  
SectionEnd

Section "Uninstall"
  ; Arrêter le backend
  nsExec::Exec 'taskkill /F /IM node.exe'
  
  ; Supprimer les fichiers
  RMDir /r "$INSTDIR"
  
  ; Supprimer les raccourcis
  Delete "$SMPROGRAMS\${APPNAME}\*.*"
  RMDir "$SMPROGRAMS\${APPNAME}"
  Delete "$DESKTOP\${APPNAME}.lnk"
  
  ; Supprimer du registre
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd
```

### 4. Modification du Script d'Installation (Inno Setup)

Si vous utilisez Inno Setup :

```ini
; installer.iss
[Setup]
AppName=LOGESCO
AppVersion=2.0
DefaultDirName={localappdata}\LOGESCO
DefaultGroupName=LOGESCO
OutputBaseFilename=LOGESCO-Setup-2.0
OutputDir=output
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest

[Files]
; Application principale
Source: "release\LOGESCO\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\LOGESCO"; Filename: "{app}\logesco_v2.exe"
Name: "{group}\Corriger Backend"; Filename: "{app}\fix-backend-startup.bat"
Name: "{group}\Diagnostic Backend"; Filename: "{app}\diagnose-backend-startup.bat"
Name: "{group}\Desinstaller"; Filename: "{uninstallexe}"
Name: "{commondesktop}\LOGESCO"; Filename: "{app}\logesco_v2.exe"

[Run]
; Générer le client Prisma
Filename: "{app}\backend\node.exe"; \
  Parameters: """{app}\backend\node_modules\prisma\build\index.js"" generate"; \
  WorkingDir: "{app}\backend"; \
  StatusMsg: "Generation du client Prisma..."; \
  Flags: runhidden

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  DBPath, DBUrl, EnvContent: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Copier le template de base de données
    if FileExists(ExpandConstant('{app}\backend\database\logesco_template.db')) then
    begin
      if not FileExists(ExpandConstant('{app}\backend\database\logesco.db')) then
      begin
        FileCopy(
          ExpandConstant('{app}\backend\database\logesco_template.db'),
          ExpandConstant('{app}\backend\database\logesco.db'),
          False
        );
      end;
    end;
    
    // Créer le fichier .env
    DBPath := ExpandConstant('{app}\backend\database\logesco.db');
    StringChangeEx(DBPath, '\', '/', True);
    DBUrl := 'file:' + DBPath;
    
    EnvContent := 
      'NODE_ENV=production' + #13#10 +
      'PORT=8080' + #13#10 +
      'DATABASE_URL=' + DBUrl + #13#10 +
      'JWT_SECRET=logesco-secret-' + IntToStr(Random(999999)) + #13#10 +
      'JWT_EXPIRES_IN=365d' + #13#10 +
      'CORS_ORIGIN=*' + #13#10 +
      'LOG_LEVEL=info' + #13#10 +
      'LOGESCO_DATA_DIR=' + ExpandConstant('{app}\backend') + #13#10;
    
    SaveStringToFile(
      ExpandConstant('{app}\backend\.env'),
      EnvContent,
      False
    );
  end;
end;
```

### 5. CI/CD (GitHub Actions / GitLab CI)

#### GitHub Actions (`.github/workflows/build.yml`)

```yaml
name: Build LOGESCO

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: Install Flutter dependencies
      working-directory: logesco_v2
      run: flutter pub get
    
    - name: Build Flutter Windows
      working-directory: logesco_v2
      run: flutter build windows --release
    
    - name: Prepare Backend
      working-directory: backend
      run: |
        npm install --production
        npx prisma generate
        npx prisma db push --accept-data-loss --skip-generate
        if (Test-Path "database\logesco.db") {
          Copy-Item "database\logesco.db" "database\logesco_template.db"
        }
    
    - name: Create Release Structure
      run: |
        New-Item -ItemType Directory -Path "release\LOGESCO" -Force
        Copy-Item -Path "logesco_v2\build\windows\runner\Release\*" -Destination "release\LOGESCO\" -Recurse
        Copy-Item -Path "backend" -Destination "release\LOGESCO\backend\" -Recurse
        Copy-Item "fix-backend-startup.bat" "release\LOGESCO\"
        Copy-Item "diagnose-backend-startup.bat" "release\LOGESCO\"
        Copy-Item "LIRE_MOI_PROBLEME_DEMARRAGE.txt" "release\LOGESCO\"
        New-Item -ItemType Directory -Path "release\LOGESCO\Documentation" -Force
        Copy-Item "GUIDE_FIX_DEMARRAGE_BACKEND.md" "release\LOGESCO\Documentation\"
    
    - name: Upload Artifact
      uses: actions/upload-artifact@v3
      with:
        name: LOGESCO-Windows
        path: release/LOGESCO
```

### 6. Checklist de Vérification Post-Build

Avant de distribuer la version finale, vérifiez :

```bash
# Checklist automatique
cd release\LOGESCO

# 1. Vérifier client Prisma
if exist "backend\node_modules\.prisma\client\index.js" (
    echo [OK] Client Prisma present
) else (
    echo [ERREUR] Client Prisma manquant!
)

# 2. Vérifier template base de données
if exist "backend\database\logesco_template.db" (
    echo [OK] Template base de donnees present
) else (
    echo [ERREUR] Template base de donnees manquant!
)

# 3. Vérifier scripts support
if exist "fix-backend-startup.bat" (
    echo [OK] Script fix present
) else (
    echo [ERREUR] Script fix manquant!
)

if exist "diagnose-backend-startup.bat" (
    echo [OK] Script diagnostic present
) else (
    echo [ERREUR] Script diagnostic manquant!
)

# 4. Vérifier documentation
if exist "Documentation\GUIDE_FIX_DEMARRAGE_BACKEND.md" (
    echo [OK] Guide present
) else (
    echo [ERREUR] Guide manquant!
)

# 5. Test de démarrage
cd backend
node src\server.js
REM Attendre 10s puis tester http://localhost:8080/health
```

### 7. Documentation pour l'Équipe

Créez un document interne (`PROCESS_BUILD_INTERNE.md`) :

```markdown
# Processus de Build LOGESCO - Documentation Interne

## Prérequis

- Flutter SDK 3.x
- Node.js 18+
- Git
- NSIS ou Inno Setup (pour l'installeur)

## Étapes de Build

1. **Préparer l'environnement**
   ```bash
   git pull origin main
   flutter doctor
   node --version
   ```

2. **Exécuter le script de build**
   ```bash
   build-release.bat
   ```

3. **Vérifier la sortie**
   - Client Prisma généré : `release\LOGESCO\backend\node_modules\.prisma\client\`
   - Template BDD : `release\LOGESCO\backend\database\logesco_template.db`
   - Scripts support : `release\LOGESCO\fix-backend-startup.bat`

4. **Créer l'installeur**
   ```bash
   makensis installer.nsi
   # ou
   iscc installer.iss
   ```

5. **Tester sur machine vierge**
   - Installer l'application
   - Lancer LOGESCO
   - Vérifier que le backend démarre
   - Tester la connexion admin/admin123

## En cas de problème

- Logs Flutter : Console de debug
- Logs Backend : `%LOCALAPPDATA%\LOGESCO\backend\logs\backend-startup.log`
- Scripts : `diagnose-backend-startup.bat`
```

## 🧪 Tests Finaux

### Test 1 : Build Local
```bash
build-release.bat
# Vérifier que tout se passe bien
```

### Test 2 : Installation sur VM Vierge
1. Créer une VM Windows 10/11
2. Installer l'application
3. Lancer et vérifier le démarrage du backend
4. Tester les fonctionnalités principales

### Test 3 : Scripts de Support
1. Supprimer intentionnellement le client Prisma
2. Exécuter `fix-backend-startup.bat`
3. Vérifier que tout est corrigé
4. Relancer l'application

### Test 4 : Désinstallation
1. Désinstaller l'application
2. Vérifier que tous les fichiers sont supprimés
3. Vérifier qu'aucun processus node.exe ne reste

## 📝 Notes Importantes

- **Toujours exécuter `prepare-portable-backend.bat` avant de créer l'installeur**
- **Inclure les scripts de support dans chaque release**
- **Tester sur machine vierge avant de distribuer**
- **Documenter tout problème rencontré et sa solution**

## 🔄 Mises à Jour Futures

Quand modifier le processus :
- ✅ Nouvelle migration Prisma → Régénérer template
- ✅ Mise à jour Node.js → Remplacer node.exe
- ✅ Changement schéma BDD → Recréer template
- ✅ Nouvelles dépendances npm → Retester le build complet

---

**Version** : 1.0
**Dernière mise à jour** : 2024
