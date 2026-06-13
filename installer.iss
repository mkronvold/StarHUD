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
Source: "StarHUD-config.ahk"; DestDir: "{app}"; Flags: ignoreversion confirmoverwrite
Source: "StarHUD-config-horizontal.ahk"; DestDir: "{app}"; Flags: ignoreversion confirmoverwrite
Source: "StarHUD-config-vertical.ahk"; DestDir: "{app}"; Flags: ignoreversion confirmoverwrite
Source: "StarHUD-config-round.ahk"; DestDir: "{app}"; Flags: ignoreversion confirmoverwrite
Source: "StarHUD-config-x.ahk"; DestDir: "{app}"; Flags: ignoreversion confirmoverwrite
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

var
  HotkeyPage: TWizardPage;
  HotkeyEdit: TNewEdit;
  ChosenHotkey: String;

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

// Read the current hotkey from an existing config file (for reinstalls)
function ReadCurrentHotkey(): String;
var
  ConfigPath: String;
  Lines: TArrayOfString;
  I: Integer;
  Line, Value: String;
  P: Integer;
begin
  Result := 'F20';
  ConfigPath := ExpandConstant('{userdocs}\AutoHotkey\StarHUD\StarHUD-config.ahk');
  if not FileExists(ConfigPath) then
    Exit;

  if LoadStringsFromFile(ConfigPath, Lines) then
  begin
    for I := 0 to GetArrayLength(Lines) - 1 do
    begin
      Line := Trim(Lines[I]);
      if Pos('ToggleHotkey', Line) = 1 then
      begin
        P := Pos(':=', Line);
        if P > 0 then
        begin
          Value := Trim(Copy(Line, P + 2, Length(Line)));
          // Strip quotes
          if (Length(Value) >= 2) and (Value[1] = '"') then
            Value := Copy(Value, 2, Length(Value) - 2);
          if Value <> '' then
            Result := Value;
        end;
        Break;
      end;
    end;
  end;
end;

procedure OpenAhkKeyListPage(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'https://www.autohotkey.com/docs/v2/KeyList.htm', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure InitializeWizard();
var
  InfoLabel: TNewStaticText;
  ExamplesLabel: TNewStaticText;
  LinkLabel: TNewStaticText;
begin
  HotkeyPage := CreateCustomPage(wpSelectDir,
    'Toggle Key',
    'Choose the key that shows and hides the StarHUD overlay.');

  InfoLabel := TNewStaticText.Create(HotkeyPage);
  InfoLabel.Parent := HotkeyPage.Surface;
  InfoLabel.Top := 0;
  InfoLabel.Left := 0;
  InfoLabel.Width := HotkeyPage.SurfaceWidth;
  InfoLabel.WordWrap := True;
  InfoLabel.Caption :=
    'Enter an AutoHotkey key name or combination below. This is the key you' + #13#10 +
    'will press to show/hide the HUD. Press RAlt + this key to toggle edit mode.';

  HotkeyEdit := TNewEdit.Create(HotkeyPage);
  HotkeyEdit.Parent := HotkeyPage.Surface;
  HotkeyEdit.Top := InfoLabel.Top + InfoLabel.Height + 16;
  HotkeyEdit.Left := 0;
  HotkeyEdit.Width := 200;
  HotkeyEdit.Font.Size := 11;
  HotkeyEdit.Text := ReadCurrentHotkey();

  ExamplesLabel := TNewStaticText.Create(HotkeyPage);
  ExamplesLabel.Parent := HotkeyPage.Surface;
  ExamplesLabel.Top := HotkeyEdit.Top + HotkeyEdit.Height + 20;
  ExamplesLabel.Left := 0;
  ExamplesLabel.Width := HotkeyPage.SurfaceWidth;
  ExamplesLabel.WordWrap := True;
  ExamplesLabel.Caption :=
    'Examples of valid key names:' + #13#10 +
    #13#10 +
    '  F20              Extended function key (default)' + #13#10 +
    '  F13              Another extended function key' + #13#10 +
    '  ScrollLock       Scroll Lock key' + #13#10 +
    '  Pause            Pause/Break key' + #13#10 +
    '  PrintScreen      Print Screen key' + #13#10 +
    '  CapsLock         Caps Lock key' + #13#10 +
    #13#10 +
    'Key combinations (modifier + key):' + #13#10 +
    #13#10 +
    '  <!c              Left Alt + C' + #13#10 +
    '  >^Delete         Right Ctrl + Delete' + #13#10 +
    '  ^F1              Ctrl + F1' + #13#10 +
    '  +F5              Shift + F5' + #13#10 +
    '  !Pause           Alt + Pause' + #13#10 +
    #13#10 +
    'Modifiers:  ^ = Ctrl   ! = Alt   + = Shift   # = Win' + #13#10 +
    'Prefix < or > for left/right specific (e.g. <! = Left Alt)' + #13#10 +
    #13#10 +
    'Tip: If you want a mouse button to open the HUD,' + #13#10 +
    'map that button to your chosen key in mouse software (e.g. Logitech G HUB).';

  LinkLabel := TNewStaticText.Create(HotkeyPage);
  LinkLabel.Parent := HotkeyPage.Surface;
  LinkLabel.Top := ExamplesLabel.Top + ExamplesLabel.Height + 12;
  LinkLabel.Left := 0;
  LinkLabel.Caption := 'View full list of valid key names (AutoHotkey docs)';
  LinkLabel.Font.Color := clBlue;
  LinkLabel.Font.Style := [fsUnderline];
  LinkLabel.Cursor := crHand;
  LinkLabel.OnClick := @OpenAhkKeyListPage;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = HotkeyPage.ID then
  begin
    ChosenHotkey := Trim(HotkeyEdit.Text);
    if ChosenHotkey = '' then
    begin
      MsgBox('Please enter a toggle key name.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

// Update the ToggleHotkey line in a config file
procedure PatchHotkeyInFile(FilePath: String);
var
  Lines: TArrayOfString;
  I: Integer;
  Line: String;
  P: Integer;
begin
  if not FileExists(FilePath) then
    Exit;

  if LoadStringsFromFile(FilePath, Lines) then
  begin
    for I := 0 to GetArrayLength(Lines) - 1 do
    begin
      Line := Lines[I];
      if Pos('ToggleHotkey', Line) = 1 then
      begin
        P := Pos(':=', Line);
        if P > 0 then
        begin
          Lines[I] := 'ToggleHotkey := "' + ChosenHotkey + '"';
          Break;
        end;
      end;
    end;
    SaveStringsToFile(FilePath, Lines, False);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  AppDir: String;
  ConfigFiles: array of String;
  I: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    AppDir := ExpandConstant('{app}');

    SetArrayLength(ConfigFiles, 5);
    ConfigFiles[0] := AppDir + '\StarHUD-config.ahk';
    ConfigFiles[1] := AppDir + '\StarHUD-config-horizontal.ahk';
    ConfigFiles[2] := AppDir + '\StarHUD-config-vertical.ahk';
    ConfigFiles[3] := AppDir + '\StarHUD-config-round.ahk';
    ConfigFiles[4] := AppDir + '\StarHUD-config-x.ahk';

    for I := 0 to GetArrayLength(ConfigFiles) - 1 do
      PatchHotkeyInFile(ConfigFiles[I]);
  end;
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
