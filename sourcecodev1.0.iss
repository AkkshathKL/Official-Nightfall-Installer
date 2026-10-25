; I used a bit of AI tomake this.. took me 2 day's to make, work's pretty clean. AnonymousKL, please approve.
; Nightfall Client Installer Version 1.0
; Akkshath, Executable Approved. proceed with publishing it.

#define MyAppName "Nightfall Modpack Installer"
#define MyAppVersion "1.0"
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

procedure InitializeWizard();
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);

  { Create custom directory page matching TInputDirWizardPage }
  CustomDirPage := CreateInputDirPage(
    wpSelectComponents,
    'Select Destination Location',
    'Where should Nightfall Client be installed?',
    'Select the folder where Setup should install Nightfall Client, then click Next.',
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
    UpdateDirText();
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
  DestDir, TmpZip, ZipName, TarCommand: String;
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    ZipName := GetSelectedZipName();
    TmpZip := ExpandConstant('{tmp}\') + ZipName + '.zip';
    DestDir := CustomDirPage.Values[0];

    if not FileExists(TmpZip) then 
      Exit;

    if not ForceDirectories(DestDir) then
    begin
      MsgBox('Failed to create destination folder: ' + DestDir, mbError, MB_OK);
      Exit;
    end;

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

    { Clean up temporary files }
    DeleteFile(TmpZip);

    if FileExists(DestDir + '\usercache.json') then
      DeleteFile(DestDir + '\usercache.json');
  end;
end;