; AnonymousKL, im sorry its still buggy.. but works.
; Akkshath, Executable Approved. proceed by changing downloading in the github repo & website.
;
; Nightfall Client Installer Version 1.1
#define MyAppName "Nightfall Modpack Installer"
#define MyAppVersion "1.1"
#define MyAppPublisher "Akkshath & AnonymousKL"

[Setup]
AppId={{73746F702077617374696E672074696D65}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
UsePreviousAppDir=no
DefaultDirName=C:\NightfallClientTest
AppendDefaultDirName=no
DisableProgramGroupPage=yes
UsePreviousSetupType=no
; This disables default destination page so our custom page displays in order (dont touch)
DisableDirPage=yes
OutputBaseFilename=NightfallInstallerSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=Nologo.ico
UninstallDisplayIcon={app}\uninstall\Nologo.ico
WizardImageFile=nightfall_banner.bmp
WizardSmallImageFile=nightfall_small.bmp

; Keep uninstaller files organized inside a subfolder rather than root (important, can be toggled. main code below, DON'T EDIT.)
Uninstallable=yes
UninstallFilesDir={app}\uninstall
CreateUninstallRegKey=yes

[Files]
Source: "Nologo.ico"; DestDir: "{app}\uninstall"; Flags: ignoreversion

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "custom"; Description: "Select Modpack Variant"; Flags: iscustom

[Components]
Name: "high"; Description: "High-End Modpack (TLauncher Only)"; Types: custom; Flags: exclusive
Name: "low"; Description: "Low-End Modpack (TLauncher Only)"; Types: custom; Flags: exclusive
Name: "other"; Description: "Other Launchers (Official / Non-TLauncher)"; Types: custom; Flags: exclusive

[Code]
var
  CustomDirPage: TInputDirWizardPage;
  MinecraftCheckbox: TNewCheckBox;
  DownloadPage: TDownloadWizardPage;
  ModePage: TWizardPage;
  InstallRadio, UpdateRadio: TNewRadioButton;
  IsUpdateMode: Boolean;
  DirPageModeApplied: Boolean;

{ Returns the exact name matching the user's selected component }
function GetSelectedZipName(): string;
begin
  if WizardIsComponentSelected('high') then
    Result := 'Nightfall_1.21.1_Client_H'
  else if WizardIsComponentSelected('low') then
    Result := 'Nightfall_1.21.1_Client_L'
  else if WizardIsComponentSelected('other') then
    Result := 'Nightfall_1.21.1_Client_NormalDistribution'
  else
    Result := 'Nightfall_1.21.1_Client';
end;

procedure UpdateDirText();
begin
  if MinecraftCheckbox.Checked then
  begin
    CustomDirPage.Values[0] := ExpandConstant('{userappdata}\.minecraft\versions\') + GetSelectedZipName();
    CustomDirPage.Edits[0].Enabled := False;
    CustomDirPage.Buttons[0].Enabled := False;
  end
  else
  begin
    CustomDirPage.Values[0] := ExpandConstant('C:\NightfallClientTest\') + GetSelectedZipName();
    CustomDirPage.Edits[0].Enabled := True;
    CustomDirPage.Buttons[0].Enabled := True;
  end;
end;

procedure MinecraftCheckboxClick(Sender: TObject);
begin
  UpdateDirText();
end;

{ Tracks which radio button is active whenever either is clicked }
procedure ModeRadioClick(Sender: TObject);
begin
  IsUpdateMode := UpdateRadio.Checked;
end;

{ Runs a quiet, recursive mirror copy via Windows' built-in robocopy.
  Exit codes 0-7 all mean "success" in some form (files copied / no
  changes needed); 8+ indicates a real failure. }
function RunRobocopy(const Src, Dst: String): Boolean;
var
  Cmd: String;
  ResultCode: Integer;
begin
  Cmd := '/c robocopy "' + Src + '" "' + Dst + '" /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP';
  Exec(ExpandConstant('{cmd}'), Cmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := ResultCode < 8;
end;

{ Preserves ONLY player progress and connections: world saves, screenshots,
  and the multiplayer server list. Settings and configs are deliberately
  NOT backed up here — options.txt, optionsof.txt, options.json, and the
  config\ folder are left for the fresh zip to overwrite, so updated
  keybind defaults and mod configs always extract cleanly without
  conflicting with stale user settings from a previous pack version. }
procedure BackupPlayerData(const SourceDir, BackupDir: String);
begin
  if DirExists(SourceDir + '\saves') then
  begin
    ForceDirectories(BackupDir + '\saves');
    RunRobocopy(SourceDir + '\saves', BackupDir + '\saves');
  end;

  if DirExists(SourceDir + '\screenshots') then
  begin
    ForceDirectories(BackupDir + '\screenshots');
    RunRobocopy(SourceDir + '\screenshots', BackupDir + '\screenshots');
  end;

  if FileExists(SourceDir + '\servers.dat') then
    CopyFile(SourceDir + '\servers.dat', BackupDir + '\servers.dat', False);
end;

procedure RestorePlayerData(const BackupDir, DestDir: String);
begin
  if DirExists(BackupDir + '\saves') then
  begin
    ForceDirectories(DestDir + '\saves');
    RunRobocopy(BackupDir + '\saves', DestDir + '\saves');
  end;

  if DirExists(BackupDir + '\screenshots') then
  begin
    ForceDirectories(DestDir + '\screenshots');
    RunRobocopy(BackupDir + '\screenshots', DestDir + '\screenshots');
  end;

  if FileExists(BackupDir + '\servers.dat') then
    CopyFile(BackupDir + '\servers.dat', DestDir + '\servers.dat', False);
end;

procedure InitializeWizard();
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);

  { Mode selection page: Install vs Update, placed right after Welcome }
  ModePage := CreateCustomPage(wpWelcome, 'Setup Mode', 'Choose what you would like to do.');

  InstallRadio := TNewRadioButton.Create(WizardForm);
  InstallRadio.Parent := ModePage.Surface;
  InstallRadio.Caption := 'Install the Nightfall modpack';
  InstallRadio.Left := 0;
  InstallRadio.Top := 0;
  InstallRadio.Width := ModePage.SurfaceWidth;
  InstallRadio.Checked := True;
  InstallRadio.OnClick := @ModeRadioClick;

  UpdateRadio := TNewRadioButton.Create(WizardForm);
  UpdateRadio.Parent := ModePage.Surface;
  UpdateRadio.Caption := 'Update the existing modpack';
  UpdateRadio.Left := 0;
  UpdateRadio.Top := InstallRadio.Top + InstallRadio.Height + ScaleY(12);
  UpdateRadio.Width := ModePage.SurfaceWidth;
  UpdateRadio.OnClick := @ModeRadioClick;

  IsUpdateMode := False;
  DirPageModeApplied := False;

  { Create custom directory page matching TInputDirWizardPage }
  CustomDirPage := CreateInputDirPage(
    wpSelectComponents,
    'Select Destination Location',
    'Where should Nightfall modpack be installed?',
    'Select the folder where Setup should install Nightfall modpack, then click Next.',
    False, ''
  );
  CustomDirPage.Add('');

  { Add checkbox directly to custom page surface }
  MinecraftCheckbox := TNewCheckBox.Create(WizardForm);
  MinecraftCheckbox.Parent := CustomDirPage.Surface;
  MinecraftCheckbox.Caption := 'Install in existing %appdata%\.minecraft\versions';
  MinecraftCheckbox.Checked := False;

  MinecraftCheckbox.Left := CustomDirPage.Edits[0].Left;
  MinecraftCheckbox.Top := CustomDirPage.Edits[0].Top + CustomDirPage.Edits[0].Height + ScaleY(15);
  MinecraftCheckbox.Width := CustomDirPage.SurfaceWidth - MinecraftCheckbox.Left;
  MinecraftCheckbox.Height := ScaleY(20);

  MinecraftCheckbox.OnClick := @MinecraftCheckboxClick;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  { Dynamically set folder name as soon as user leaves the selection screen and arrives at Destination screen }
  if (CustomDirPage <> nil) and (CurPageID = CustomDirPage.ID) then
  begin
    if IsUpdateMode and not DirPageModeApplied then
    begin
      MinecraftCheckbox.Checked := True;
      DirPageModeApplied := True;
    end;
    UpdateDirText();

    if IsUpdateMode then
      CustomDirPage.SubCaptionLabel.Caption := 'Select the folder in which your official Nightfall modpack was installed.'
    else
      CustomDirPage.SubCaptionLabel.Caption := 'Select the folder where Setup should install Nightfall modpack, then click Next.';
  end;

  if CurPageID = wpSelectComponents then
  begin
    if IsUpdateMode then
      WizardForm.SelectComponentsLabel.Caption := 'Which modpack variant do you currently have installed? It will be updated. Saves and and server data is 100% safe. Just in game settings will reset to defaults'
    else
      WizardForm.SelectComponentsLabel.Caption := 'Select the modpack variant to install.';
  end;

  if CurPageID = wpFinished then
  begin
    if IsUpdateMode then
      WizardForm.FinishedLabel.Caption := 'Nightfall Modpack has been updated.'
    else
      WizardForm.FinishedLabel.Caption := 'Nightfall modpack has been installed successfully.';
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  URL, ZipName: string;
begin
  Result := True;

  if CurPageID = wpReady then
  begin
    ZipName := GetSelectedZipName();
    URL := '';
    
    if WizardIsComponentSelected('high') then
      URL := 'https://github.com/AkkshathKL/MC-1.21.1-Fabric-Java-Client/releases/download/High_End_Devices_Win11/Nightfall_1.21.1_Client_H.zip'
    else if WizardIsComponentSelected('low') then
      URL := 'https://github.com/AkkshathKL/MC-1.21.1-Fabric-Java-Client/releases/download/Low_End_Devices_Win11/Nightfall_1.21.1_Client_L.zip'
    else if WizardIsComponentSelected('other') then
      URL := 'https://github.com/AkkshathKL/MC-1.21.1-Fabric-Java-Client/releases/download/Multi_Distribution_Win11/Nightfall_1.21.1_Client_NormalDistribution.zip';

    if URL = '' then
    begin
      MsgBox('No modpack variant was selected. Installation cannot continue.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    DownloadPage.Clear;
    DownloadPage.Add(URL, ZipName + '.zip', '');
    DownloadPage.Show;
    
    try
      try
        DownloadPage.Download;
        Result := True;
      except
        if DownloadPage.AbortedByUser then
          Log('Download aborted by user.')
        else
          MsgBox('The download failed. Check your internet connection.', mbError, MB_OK);
        Result := False;
      end;
    finally
      DownloadPage.Hide;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  DestDir, TmpZip, ZipName, TarCommand, BackupDir, MoveCmd, NestedFolder: String;
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    ZipName := GetSelectedZipName();
    TmpZip := ExpandConstant('{tmp}\') + ZipName + '.zip';
    DestDir := CustomDirPage.Values[0];

    { Ensure target path always ends with the variant folder name }
    if CompareText(ExtractFileName(RemoveBackslashUnlessRoot(DestDir)), ZipName) <> 0 then
      DestDir := AddBackslash(DestDir) + ZipName;

    BackupDir := ExpandConstant('{tmp}\NightfallBackup');

    if not FileExists(TmpZip) then
      Exit;

    { Step 1: Back up player data }
    if DirExists(BackupDir) then
      DelTree(BackupDir, True, True, True);
    ForceDirectories(BackupDir);
    BackupPlayerData(DestDir, BackupDir);

    { Step 2: Clear old installation folder }
    if DirExists(DestDir) then
    begin
      if not DelTree(DestDir, True, True, True) then
      begin
        MsgBox('Failed to remove existing installation folder: ' + DestDir, mbError, MB_OK);
        Exit;
      end;
    end;

    if not ForceDirectories(DestDir) then
    begin
      MsgBox('Failed to create destination folder: ' + DestDir, mbError, MB_OK);
      Exit;
    end;

    { Step 3: Extract archive }
    WizardForm.StatusLabel.Caption := 'Extracting modpack...';
    WizardForm.Refresh;

    TarCommand := '/c tar -xf "' + TmpZip + '" -C "' + DestDir + '"';

    if not Exec(ExpandConstant('{cmd}'), TarCommand, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      MsgBox('Failed to launch tar.exe for extraction.', mbError, MB_OK);
      Exit;
    end;

    if ResultCode <> 0 then
    begin
      MsgBox('Extraction failed (tar exit code: ' + IntToStr(ResultCode) + ').', mbError, MB_OK);
      Exit;
    end;

    { Step 4: Flatten extra subfolder if zip contained a nested parent folder }
    NestedFolder := AddBackslash(DestDir) + ZipName;
    if DirExists(NestedFolder) then
    begin
      MoveCmd := '/c robocopy "' + NestedFolder + '" "' + DestDir + '" /E /MOVE /NFL /NDL /NJH /NJS /NC /NS /NP';
      Exec(ExpandConstant('{cmd}'), MoveCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      DelTree(NestedFolder, True, True, True);
    end;

    { Step 5: Restore player data }
    WizardForm.StatusLabel.Caption := 'Restoring your worlds and server list...';
    WizardForm.Refresh;
    RestorePlayerData(BackupDir, DestDir);
    DelTree(BackupDir, True, True, True);

    { Step 6: Cleanup temporary files }
    DeleteFile(TmpZip);

    if FileExists(DestDir + '\usercache.json') then
      DeleteFile(DestDir + '\usercache.json');
  end;
end;