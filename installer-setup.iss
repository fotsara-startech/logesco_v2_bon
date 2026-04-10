; ============================================================
; LOGESCO v2 - Script InnoSetup
; Installeur Windows tout-en-un.
;
; Installation:
;   - logesco_v2.exe + DLLs Flutter -> Program Files\LOGESCO
;   - logesco-backend.exe + prisma-engines -> AppData\Local\LOGESCO\backend
;   - Dossiers database/, uploads/, logs/ crees une seule fois
;
; Mise a jour (client existant):
;   - Les binaires sont ecrases (app + backend)
;   - database/ et uploads/ ne sont JAMAIS touches
;   - Les migrations Prisma s'appliquent au 1er demarrage
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

; Dossier d'installation
DefaultDirName={autopf}\LOGESCO
DefaultGroupName={#MyAppName}

PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Sortie
OutputDir=release
#ifdef SetupName
OutputBaseFilename={#SetupName}
#else
OutputBaseFilename=LOGESCO-v2-Setup
#endif
Compression=lzma2/ultra64
SolidCompression=yes

; Interface
WizardStyle=modern
DisableProgramGroupPage=yes
DisableWelcomePage=no
ShowLanguageDialog=no

; Icone
SetupIconFile=app_icon.ico

; Architecture 64-bit
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; Desinstallation
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

RestartIfNeededByRun=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Creer un raccourci sur le Bureau"; GroupDescription: "Raccourcis:"

[Dirs]
; Dossiers de donnees persistantes - crees une seule fois
Name: "{localappdata}\LOGESCO\backend\database"
Name: "{localappdata}\LOGESCO\backend\uploads"
Name: "{localappdata}\LOGESCO\backend\logs"
Name: "{localappdata}\LOGESCO\backend\prisma"

[Files]
; Application Flutter (exe + DLLs + data/)
Source: "{#FlutterRelease}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; node.exe portable (Node.js embarque, pas besoin d'installation)
Source: "{#BackendExeDir}\node.exe"; DestDir: "{localappdata}\LOGESCO\backend"; Flags: ignoreversion

; Code source backend
Source: "{#BackendExeDir}\src\*"; DestDir: "{localappdata}\LOGESCO\backend\src"; Flags: ignoreversion recursesubdirs createallsubdirs

; node_modules complet (Prisma natif inclus)
Source: "{#BackendExeDir}\node_modules\*"; DestDir: "{localappdata}\LOGESCO\backend\node_modules"; Flags: ignoreversion recursesubdirs createallsubdirs

; Schema Prisma et package.json
Source: "{#BackendExeDir}\schema.prisma"; DestDir: "{localappdata}\LOGESCO\backend"; Flags: ignoreversion
Source: "{#BackendExeDir}\schema.prisma"; DestDir: "{localappdata}\LOGESCO\backend\prisma"; Flags: ignoreversion
Source: "{#BackendExeDir}\package.json";  DestDir: "{localappdata}\LOGESCO\backend"; Flags: ignoreversion

; .env copie SEULEMENT si absent (1ere installation, conserve a la MAJ)
Source: "{#BackendExeDir}\.env.example"; DestDir: "{localappdata}\LOGESCO\backend"; DestName: ".env"; Flags: onlyifdoesntexist

[Icons]
Name: "{group}\{#MyAppName}";              Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstaller {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";        Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Lancer {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Supprimer les logs a la desinstallation (pas les donnees)
Type: filesandordirs; Name: "{localappdata}\LOGESCO\backend\logs"

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  if CheckForMutexes('LOGESCO_V2_RUNNING') then
  begin
    if MsgBox(
      'LOGESCO v2 est en cours d''execution.' + #13#10 +
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

function IsUpgrade(): Boolean;
begin
  Result := RegKeyExists(HKCU,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{B7C4D5E6-F7A8-4901-BCDE-F01234567890}_is1');
end;

procedure InitializeWizard();
begin
  if IsUpgrade() then
    WizardForm.WelcomeLabel2.Caption :=
      'Cette installation va mettre a jour LOGESCO v2.' + #13#10 + #13#10 +
      'Vos donnees (produits, ventes, clients) seront conservees.' + #13#10 + #13#10 +
      'Cliquez sur Suivant pour continuer.'
  else
    WizardForm.WelcomeLabel2.Caption :=
      'Ce programme va installer LOGESCO v2 sur votre ordinateur.' + #13#10 + #13#10 +
      'LOGESCO v2 inclut:' + #13#10 +
      '  - Gestion des stocks et produits' + #13#10 +
      '  - Gestion des ventes et caisse' + #13#10 +
      '  - Gestion des clients et fournisseurs' + #13#10 +
      '  - Rapports et statistiques' + #13#10 + #13#10 +
      'Aucune configuration technique requise.' + #13#10 +
      'Le serveur demarre automatiquement avec l''application.';
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    if IsUpgrade() then
      WizardForm.FinishedLabel.Caption :=
        'LOGESCO v2 a ete mis a jour avec succes!' + #13#10 + #13#10 +
        'Vos donnees ont ete conservees.' + #13#10 + #13#10 +
        'Cliquez sur Terminer pour lancer l''application.'
    else
      WizardForm.FinishedLabel.Caption :=
        'LOGESCO v2 a ete installe avec succes!' + #13#10 + #13#10 +
        'Au premier demarrage:' + #13#10 +
        '  - La base de donnees sera initialisee automatiquement' + #13#10 +
        '  - Identifiants par defaut: admin / admin123' + #13#10 + #13#10 +
        'Cliquez sur Terminer pour lancer l''application.';
  end;
end;

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
