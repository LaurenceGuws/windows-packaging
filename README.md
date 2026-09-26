# windows-packaging

One shared Inno Setup recipe for ordinary per-user Windows applications.

The contract is deliberately small:

> Give `winsetup.ps1` a directory containing a working x64 Windows application and the executable inside it. Get back one standard Setup EXE.

Inno Setup owns installation, upgrades, Start Menu integration, Add/Remove Programs, and uninstall. This repository owns no runtime updater, download protocol, package manager, product scripting, or application configuration.

## Builder setup

One time on a Windows builder:

```powershell
winget install --id JRSoftware.InnoSetup --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
```

`winsetup.ps1` discovers user-local or Program Files installations of Inno Setup 6 or 7. `INNO_SETUP_ISCC` is an explicit override when a builder keeps it elsewhere.

## Build

```powershell
.\winsetup.ps1 `
  -Name "Howl" `
  -Version "0.1.6-dev-beta.4" `
  -AppId "io.github.laurenceguws.howl" `
  -Exe "howl-odin.exe" `
  -Source "C:\build\howl" `
  -Output "C:\build\HowlSetup.exe"
```

The source directory is copied recursively into the application's dedicated install directory below:

```text
%LOCALAPPDATA%\Programs\<InstallDirName>
```

The same stable `AppId` and install directory are used for later versions. Running a newer Setup EXE is the update path.

Uninstall is the normal Inno-generated entry in Windows Installed Apps / Add or Remove Programs.

## Product boundary

A product owns:

- the files in its staging directory;
- `Name`;
- `Version`;
- one stable `AppId`;
- its relative entrypoint filename.

That is all.

If an application later demonstrates a real packaging need that this template cannot express, add the smallest generic option that earns its existence. Do not add product-specific scripts to this repository.

## Proven Windows behavior

The initial wrapper was dogfooded on the accepted Win11 VM with two distinct real Howl bundles and one stable AppId:

- fresh per-user install into `%LOCALAPPDATA%\\Programs\\Howl`;
- normal Start Menu and Installed Apps registration;
- second Setup EXE updated the same installation in place and replaced Howl's executable/bridge with the new bytes;
- the updated installed `howl-odin.exe` launched successfully;
- Inno's generated uninstaller removed the application directory, Installed Apps entry, and Start Menu shortcut.

Application configuration is not installer-owned and is therefore not removed by this generic template.
