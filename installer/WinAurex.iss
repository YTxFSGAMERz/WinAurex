[Setup]
AppId={{5A8E9A34-03C8-4BC4-B3C5-15D83AB50C54}
AppName=WinAurex
AppVersion=5.0.0
AppPublisher=WinAurex Team
AppPublisherURL=https://github.com/YTxFSGAMERz/WinAurex
AppSupportURL=https://github.com/YTxFSGAMERz/WinAurex
AppUpdatesURL=https://github.com/YTxFSGAMERz/WinAurex
DefaultDirName={autopf}\WinAurex
DefaultGroupName=WinAurex
AllowNoIcons=yes
PrivilegesRequired=admin
OutputDir=..\release
OutputBaseFilename=WinAurex-Setup
SetupIconFile=..\src\WinAurex.App\Assets\AppIcon.ico
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\src\WinAurex.App\bin\Release\net10.0-windows10.0.26100.0\win-x64\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\WinAurex"; Filename: "{app}\WinAurex.App.exe"
Name: "{group}\{cm:UninstallProgram,WinAurex}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\WinAurex"; Filename: "{app}\WinAurex.App.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\WinAurex.App.exe"; Description: "{cm:LaunchProgram,WinAurex}"; Flags: nowait postinstall skipifsilent
