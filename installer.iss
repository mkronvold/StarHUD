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
const
  AHK_DOWNLOAD_URL = 'https://github.com/AutoHotkey/AutoHotkey/releases/latest/download/AutoHotkey_2.0_setup.exe';
  AHK_INSTALLER_NAME = 'AutoHotkey_2.0_setup.exe';

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

function DownloadAndInstallAutoHotkey(): Boolean;
var
  TempFile: String;
  ResultCode: Integer;
  DownloadCmd: String;
begin
  Result := False;
  TempFile := ExpandConstant('{tmp}\') + AHK_INSTALLER_NAME;

  // Download AutoHotkey installer using PowerShell
  DownloadCmd := Format('-NoProfile -Command "Invoke-WebRequest -Uri ''%s'' -OutFile ''%s''"',
                        [AHK_DOWNLOAD_URL, TempFile]);
  if not Exec('powershell.exe', DownloadCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    MsgBox('Failed to download AutoHotkey v2. Please install it manually from https://www.autohotkey.com/',
           mbError, MB_OK);
    Exit;
  end;

  if not FileExists(TempFile) then
  begin
    MsgBox('Download failed. Please install AutoHotkey v2 manually from https://www.autohotkey.com/',
           mbError, MB_OK);
    Exit;
  end;

  // Run AutoHotkey installer silently
  if Exec(TempFile, '/silent', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 0 then
      Result := True
    else
      MsgBox('AutoHotkey installer exited with code ' + IntToStr(ResultCode) + '.' + #13#10 +
             'Please install AutoHotkey v2 manually from https://www.autohotkey.com/',
             mbError, MB_OK);
  end
  else
    MsgBox('Failed to run the AutoHotkey installer. Please install it manually from https://www.autohotkey.com/',
           mbError, MB_OK);

  DeleteFile(TempFile);
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not IsAutoHotkeyInstalled() then
  begin
    case MsgBox('AutoHotkey v2 is required but does not appear to be installed.' + #13#10 + #13#10 +
                'Would you like the installer to download and install it for you?',
                mbConfirmation, MB_YESNOCANCEL) of
      IDYES:
        begin
          if not DownloadAndInstallAutoHotkey() then
          begin
            if MsgBox('AutoHotkey v2 installation failed. Continue with StarHUD setup anyway?',
                      mbConfirmation, MB_YESNO) = IDNO then
              Result := False;
          end;
        end;
      IDNO:
        ; User chose to skip - continue without AHK
      IDCANCEL:
        Result := False;
    end;
  end;
end;
