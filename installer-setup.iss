; ============================================================
; LOGESCO v2 - Script InnoSetup
; Crée un installeur Windows professionnel tout-en-un.
;
; Ce que fait cet installeur:
;   1. Copie logesco_v2.exe + DLLs Flutter dans Program Files
;   2. Copie logesco-backend.exe + prisma-engines dans AppData\Local\LOGESCO\backend
;   3. Crée les dossiers database/, uploads/, logs/ (données persistantes)
;   4. Crée un raccourci bureau + menu Démarrer
;   5. Enregistre l'application pour Ajout/Suppression de programmes
;
; Mise à jour (client existant):
;   - Les binaires sont écrasés (app + backend)
;   - database/, uploads/ ne sont JAMAIS touchés (flag onlyifdoesntexist)
;   - Les migrations Prisma sont exécutées automatiquement au 1er démarrage
; ============================================================

#define MyAppName      "LOGESCO v2"
#define MyAppVersion   "2.0.0"
#define MyAppPublisher "LOGESCO"
#define MyAppExeName   "logesco_v2.exe"
#define MyAppURL       "https://logesco.app"

; Chemins des sources (relatifs au script .iss)
#define FlutterRelease "logesco_v2\build\windows\x64\runner\Release"
#define BackendExeDir  "dist-exe"

[Setup]
AppId={{B7C4D5E6-F7A8-4901-BCDE-F01234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Dossier d'installation de l'application Flutter
DefaultDirName={autopf}\LOGESCO
DefaultGroupName={#MyAppName}

; Pas besoin d'admin grâce à autopf + localappdata pour les données
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Sortie
OutputDir=release
OutputBaseFilename=LOGESCO-v2-Setup
Compression=lzma2/ultra64
SolidCompression=yes

; Interface
WizardStyle=modern
DisableProgramGroupPage=yes
DisableWelcomePage=no
ShowLanguageDialog=no

; Icône
SetupIconFile=app_icon.ico

; Architecture 64-bit uniquement
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; Désinstallation
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

; Redémarrage non requis
RestartIfNeededByRun=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis:"; Flags: checked

[Dirs]
; Dossiers de données persistantes — créés une seule fois, jamais supprimés à la MAJ
Name: "{localappdata}\LOGESCO\backend\database"; Flags: uninsneveruninstall
Name: "{localappdata}\LOGESCO\backend\uploads";  Flags: uninsneveruninstall
Name: "{localappdata}\LOGESCO\backend\logs";     Flags: uninsneveruninstall

[Files]
; ── Application Flutter ──────────────────────────────────────────────────
; Tous les fichiers du build Flutter (exe + DLLs + data/)
Source: "{#FlutterRelease}\*"; \
  DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

; ── Backend exécutable ───────────────────────────────────────────────────
; L'exe compilé par pkg (Node.js embarqué)
Source: "{#BackendExeDir}\logesco-backend.exe"; \
  DestDir: "{localappdata}\LOGESCO\backend"; \
  Flags: ignoreversion

; Binaires Prisma query-engine (requis à côté de l'exe)
Source: "{#BackendExeDir}\prisma-engines\*"; \
  DestDir: "{localappdata}\LOGESCO\backend\prisma-engines"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

; Schéma Prisma (pour les migrations au runtime)
Source: "{#BackendExeDir}\schema.prisma"; \
  DestDir: "{localappdata}\LOGESCO\backend"; \
  Flags: ignoreversion

; .env.example → copié comme .env SEULEMENT si absent (1ère installation)
; À la MAJ, le .env existant est conservé (mot de passe JWT, etc.)
Source: "{#BackendExeDir}\.env.example"; \
  DestDir: "{localappdata}\LOGESCO\backend"; \
  DestName: ".env"; \
  Flags: onlyifdoesntexist

[Icons]
; Menu Démarrer
Name: "{group}\{#MyAppName}";                    Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Désinstaller {#MyAppName}";       Filename: "{uninstallexe}"

; Bureau (optionnel)
Name: "{autodesktop}\{#MyAppName}";              Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Lancer l'application après installation
Filename: "{app}\{#MyAppExeName}"; \
  Description: "Lancer {#MyAppName}"; \
  Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Supprimer les logs à la désinstallation (pas les données)
Type: filesandordirs; Name: "{localappdata}\LOGESCO\backend\logs"

; NE PAS supprimer database/ et uploads/ — données client précieuses

[Code]
// ── Vérifications avant installation ──────────────────────────────────────

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;

  // Si LOGESCO tourne, proposer de le fermer
  if CheckForMutexes('LOGESCO_V2_RUNNING') then
  begin
    if MsgBox(
      'LOGESCO v2 est en cours d''exécution.' + #13#10 +
      'Voulez-vous le fermer pour continuer l''installation?',
      mbConfirmation, MB_YESNO) = IDYES then
    begin
      Exec('taskkill', '/F /IM logesco_v2.exe /IM logesco-backend.exe',
           '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Sleep(2000);
    end
    else
    begin
      Result := False;
      Exit;
    end;
  end;
end;

// ── Détection d'une installation existante (mise à jour) ──────────────────

function IsUpgrade(): Boolean;
begin
  Result := RegKeyExists(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{B7C4D5E6-F7A8-4901-BCDE-F01234567890}_is1');
end;

// ── Page de bienvenue personnalisée ───────────────────────────────────────

procedure InitializeWizard();
begin
  if IsUpgrade() then
    WizardForm.WelcomeLabel2.Caption :=
      'Cette installation va mettre à jour LOGESCO v2 sur votre ordinateur.' + #13#10 + #13#10 +
      'Vos données (produits, ventes, clients) seront conservées.' + #13#10 + #13#10 +
      'Cliquez sur Suivant pour continuer.'
  else
    WizardForm.WelcomeLabel2.Caption :=
      'Ce programme va installer LOGESCO v2 sur votre ordinateur.' + #13#10 + #13#10 +
      'LOGESCO v2 inclut:' + #13#10 +
      '  • Gestion des stocks et produits' + #13#10 +
      '  • Gestion des ventes et caisse' + #13#10 +
      '  • Gestion des clients et fournisseurs' + #13#10 +
      '  • Rapports et statistiques' + #13#10 + #13#10 +
      'Aucune configuration technique requise.' + #13#10 +
      'Le serveur démarre automatiquement avec l''application.';
end;

// ── Message de fin ─────────────────────────────────────────────────────────

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    if IsUpgrade() then
      WizardForm.FinishedLabel.Caption :=
        'LOGESCO v2 a été mis à jour avec succès!' + #13#10 + #13#10 +
        'Vos données ont été conservées.' + #13#10 + #13#10 +
        'Cliquez sur Terminer pour lancer l''application.'
    else
      WizardForm.FinishedLabel.Caption :=
        'LOGESCO v2 a été installé avec succès!' + #13#10 + #13#10 +
        'Au premier démarrage:' + #13#10 +
        '  • La base de données sera initialisée automatiquement' + #13#10 +
        '  • Identifiants par défaut: admin / admin123' + #13#10 + #13#10 +
        'Cliquez sur Terminer pour lancer l''application.';
  end;
end;

// ── Arrêter le backend à la désinstallation ────────────────────────────────

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Exec('taskkill', '/F /IM logesco_v2.exe /IM logesco-backend.exe',
         '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(1000);
  end;
end;
