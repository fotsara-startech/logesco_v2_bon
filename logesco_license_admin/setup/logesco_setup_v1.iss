; Script InnoSetup pour LOGESCO v2
; Crée un installeur Windows simple et professionnel

#define MyAppName "LOGESCO v2"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "LOGESCO"
#define MyAppExeName "logesco_v2.exe"
#define MyAppAssocName "LOGESCO Document"
#define MyAppAssocExt ".logesco"

[Setup]
; Informations de base
AppId={A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\LOGESCO
DefaultGroupName=LOGESCO v2
AllowNoIcons=yes
OutputDir=release
OutputBaseFilename=LOGESCO-v2-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Icônes et images (optionnel)
; SetupIconFile=assets\icon.ico
; WizardImageFile=assets\wizard.bmp

; Privilèges
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Architecture
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; Interface
DisableProgramGroupPage=yes
DisableWelcomePage=no

; Langue
ShowLanguageDialog=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Application principale et tous ses fichiers
Source: "release\LOGESCO\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Ne pas utiliser "Flags: ignoreversion" sur les fichiers système

[Icons]
; Raccourci dans le menu Démarrer
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

; Raccourci sur le bureau (optionnel)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Lancer l'application après installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Code Pascal pour personnalisation avancée

// Vérifier si l'application est en cours d'exécution
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  
  // Vérifier si LOGESCO est déjà en cours d'exécution
  if CheckForMutexes('LOGESCO_V2_RUNNING') then
  begin
    if MsgBox('LOGESCO v2 est actuellement en cours d''exécution. Voulez-vous le fermer et continuer l''installation?', 
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Tenter de fermer l'application
      Exec('taskkill', '/F /IM logesco_v2.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Sleep(2000);
      Result := True;
    end
    else
      Result := False;
  end;
end;

// Message de bienvenue personnalisé
procedure InitializeWizard();
var
  WelcomeLabel: TNewStaticText;
begin
  // Personnaliser la page de bienvenue
  WelcomeLabel := TNewStaticText.Create(WizardForm);
  WelcomeLabel.Parent := WizardForm.WelcomePage;
  WelcomeLabel.Caption := 
    'Bienvenue dans l''installation de LOGESCO v2!' + #13#10 + #13#10 +
    'Ce programme va installer LOGESCO v2 sur votre ordinateur.' + #13#10 + #13#10 +
    'LOGESCO v2 est un système de gestion commerciale complet qui inclut:' + #13#10 +
    '  • Gestion des stocks' + #13#10 +
    '  • Gestion des ventes' + #13#10 +
    '  • Gestion des clients et fournisseurs' + #13#10 +
    '  • Rapports et statistiques' + #13#10 + #13#10 +
    'Aucune configuration technique requise!' + #13#10 +
    'L''application est prête à l''emploi après installation.';
  WelcomeLabel.AutoSize := True;
  WelcomeLabel.WordWrap := True;
  WelcomeLabel.Top := 100;
  WelcomeLabel.Left := 0;
  WelcomeLabel.Width := WizardForm.WelcomePage.Width;
end;

// Créer les dossiers nécessaires après installation
procedure CurStepChanged(CurStep: TSetupStep);
var
  BackendPath: String;
  DatabasePath: String;
  LogsPath: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Créer les dossiers nécessaires
    BackendPath := ExpandConstant('{app}\data\flutter_assets\backend');
    DatabasePath := BackendPath + '\database';
    LogsPath := BackendPath + '\logs';
    
    // Créer le dossier database s'il n'existe pas
    if not DirExists(DatabasePath) then
      CreateDir(DatabasePath);
      
    // Créer le dossier logs s'il n'existe pas
    if not DirExists(LogsPath) then
      CreateDir(LogsPath);
      
    // Copier .env.example vers .env s'il n'existe pas
    if not FileExists(BackendPath + '\.env') then
    begin
      if FileExists(BackendPath + '\.env.example') then
        FileCopy(BackendPath + '\.env.example', BackendPath + '\.env', False);
    end;
  end;
end;

// Message de fin personnalisé
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedLabel.Caption := 
      'LOGESCO v2 a été installé avec succès!' + #13#10 + #13#10 +
      'Vous pouvez maintenant lancer l''application.' + #13#10 + #13#10 +
      'Au premier démarrage:' + #13#10 +
      '  1. L''application va initialiser la base de données' + #13#10 +
      '  2. Un compte administrateur sera créé automatiquement' + #13#10 +
      '  3. Vous pourrez commencer à utiliser LOGESCO immédiatement' + #13#10 + #13#10 +
      'Aucune configuration supplémentaire n''est nécessaire!';
  end;
end;

[UninstallDelete]
; Nettoyer les fichiers créés par l'application
Type: filesandordirs; Name: "{app}\data\flutter_assets\backend\database"
Type: filesandordirs; Name: "{app}\data\flutter_assets\backend\logs"
Type: files; Name: "{app}\data\flutter_assets\backend\.env"
