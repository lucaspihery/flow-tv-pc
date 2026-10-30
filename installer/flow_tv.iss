; Installateur Windows de Flow TV (Inno Setup 6).
;
; Compilé par GitHub Actions après « flutter build windows --release » :
;   iscc /DAppVersion=1.0.0 installer\flow_tv.iss
; Le setup est écrit dans build\installer\.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define AppName "Flow TV"
#define AppExe "flow_tv.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
; Identifiant stable : ne pas le changer, il permet aux mises à jour de remplacer l'installation existante.
AppId={{1A57EECC-B622-47C4-816F-A62B06D979C6}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Flow TV
AppPublisherURL=https://github.com/lucaspihery/flow-tv-pc
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Installation pour l'utilisateur courant par défaut (pas de droits administrateur),
; avec le choix de l'installer pour tous les utilisateurs.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\build\installer
OutputBaseFilename=FlowTV-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Tout le dossier Release : l'exécutable a besoin des DLL (Flutter, libmpv…) et du dossier data à côté de lui.
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
