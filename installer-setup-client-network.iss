; ============================================================
; LOGESCO v2 - Client Réseau Local (Frontend uniquement)
; Script InnoSetup pour clients connectés à un serveur
;
; Installation:
;   - logesco_v2.exe + DLLs Flutter -> Program Files\LOGESCO
;   - Configuration serveur stockée localement
;   - Pas de backend, pas de base de données locale
;
; Mise à jour (client existant):
;   - Les binaires sont écrasés
;   - Configuration serveur conservée
; ============================================================

#define MyAppName      "LOGESCO v2 - Client Réseau"
#define MyAppVersion   "2.0.0"
#define MyAppPublisher "LOGESCO"
#define MyAppExeName   "logesco_v2.exe"
#define MyAppURL       "https://logesco.app"

; Chemins des sources (relatifs au script .iss)
#define FlutterRelease "logesco_v2\build\windows\x64\runner\Release"

[Setup]
AppId={{C8D5E6F7-A8B9-4902-CDEF-F01234567891}
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
OutputBaseFilename=LOGESCO-v2-Client-Network-Setup
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
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
;Name: "english"; MessagesFile: "compiler:Languages\English.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunch"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; OnlyBelowVersion: 6.1

[Dirs]
; Dossier de configuration client - créé une seule fois
Name: "{localappdata}\LOGESCO\client"

[Files]
; Application Flutter (exe + DLLs + data/)
Source: "{#FlutterRelease}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Fichier de configuration serveur - conservé à la mise à jour
Source: "config\client-network-config.json"; DestDir: "{localappdata}\LOGESCO\client"; Flags: onlyifdoesntexist

[Icons]
Name: "{group}\{#MyAppName}";              Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstaller {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";        Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunch

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  if CheckForMutexes('LOGESCO_V2_RUNNING') then
  begin
    if MsgBox(
      'LOGESCO v2 est en cours d''exécution.' + #13#10 +
      'Voulez-vous le fermer pour continuer l''installation?',
      mbConfirmation, MB_YESNO) = IDYES then
    begin
      Exec('taskkill', '/F /IM logesco_v2.exe',
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
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{C8D5E6F7-A8B9-4902-CDEF-F01234567891}_is1');
end;

procedure InitializeWizard();
begin
  if IsUpgrade() then
    WizardForm.WelcomeLabel2.Caption :=
      'Cette installation va mettre à jour LOGESCO v2 - Client Réseau.' + #13#10 + #13#10 +
      'Votre configuration serveur sera conservée.' + #13#10 + #13#10 +
      'Cliquez sur Suivant pour continuer.'
  else
    WizardForm.WelcomeLabel2.Caption :=
      'Ce programme va installer LOGESCO v2 - Client Réseau sur votre ordinateur.' + #13#10 + #13#10 +
      'LOGESCO v2 Client Réseau inclut:' + #13#10 +
      '  - Interface de gestion des stocks et produits' + #13#10 +
      '  - Gestion des ventes et caisse' + #13#10 +
      '  - Gestion des clients et fournisseurs' + #13#10 +
      '  - Rapports et statistiques' + #13#10 + #13#10 +
      'Connexion à un serveur LOGESCO requis.' + #13#10 +
      'Aucune base de données locale.' + #13#10 +
      'Aucune configuration technique requise.';
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    if IsUpgrade() then
      WizardForm.FinishedLabel.Caption :=
        'LOGESCO v2 - Client Réseau a été mis à jour avec succès!' + #13#10 + #13#10 +
        'Votre configuration serveur a été conservée.' + #13#10 + #13#10 +
        'Cliquez sur Terminer pour lancer l''application.'
    else
      WizardForm.FinishedLabel.Caption :=
        'LOGESCO v2 - Client Réseau a été installé avec succès!' + #13#10 + #13#10 +
        'Au premier démarrage:' + #13#10 +
        '  - Vous devrez configurer l''adresse du serveur' + #13#10 +
        '  - Utilisez les identifiants fournis par votre administrateur' + #13#10 + #13#10 +
        'Cliquez sur Terminer pour lancer l''application.';
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Exec('taskkill', '/F /IM logesco_v2.exe',
         '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(1000);
  end;
end;

