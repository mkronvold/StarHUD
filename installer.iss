; StarHUD Inno Setup Installer
; Installs StarHUD to Documents\AutoHotkey\StarHUD and creates a desktop shortcut.
; The Documents folder is resolved via Windows shell folders, which handles OneDrive
; redirection automatically.

#define MyAppName "StarHUD"
#define MyAppVersion "1.0"
#define MyAppPublisher "mkronvold"
#define MyAppURL "https://github.com/mkronvold/StarHUD"

[Setup]
AppId={{E7A3B8C1-4F2D-4A9E-B6D8-1C3F5E7A9B2D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={userdocs}\AutoHotkey\StarHUD
DisableProgramGroupPage=yes
OutputBaseFilename=StarHUD-Setup
SetupIconFile=StarHUD-center-logo.ico
UninstallDisplayIcon={app}\StarHUD-center-logo.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DefaultGroupName={#MyAppName}
CreateUninstallRegKey=yes
; No admin required - installs to user Documents

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "StarHUD.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "StarHUD-config.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "StarHUD-config-horizontal.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "StarHUD-config-vertical.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "StarHUD-config-round.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "StarHUD-config-x.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "StarHUD-center-logo.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "images\*"; DestDir: "{app}\images"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{userdesktop}\StarHUD"; Filename: "{app}\StarHUD.ahk"; IconFilename: "{app}\StarHUD-center-logo.ico"; Comment: "Launch StarHUD"

[Run]
Filename: "{app}\StarHUD.ahk"; Description: "Launch StarHUD now"; Flags: nowait postinstall skipifsilent shellexec

[Code]
// Check if AutoHotkey v2 is installed by looking for the exe
function IsAutoHotkeyInstalled(): Boolean;
var
  AhkPath: String;
begin
  AhkPath := ExpandConstant('{pf}\AutoHotkey\v2\AutoHotkey64.exe');
  Result := FileExists(AhkPath);
  if not Result then
  begin
    AhkPath := ExpandConstant('{pf32}\AutoHotkey\v2\AutoHotkey64.exe');
    Result := FileExists(AhkPath);
  end;
  if not Result then
  begin
    AhkPath := ExpandConstant('{localappdata}\Programs\AutoHotkey\v2\AutoHotkey64.exe');
    Result := FileExists(AhkPath);
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not IsAutoHotkeyInstalled() then
  begin
    if MsgBox('AutoHotkey v2 does not appear to be installed.' + #13#10 + #13#10 +
              'StarHUD requires AutoHotkey v2 to run. Would you like to continue anyway?' + #13#10 +
              '(You can install AutoHotkey v2 from https://www.autohotkey.com/)',
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
  end;
end;
