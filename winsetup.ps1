param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$AppId,
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Output,
    [string]$Publisher = "Laurence Guws",
    [string]$InstallDirName = ""
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw $Message
}

if ([string]::IsNullOrWhiteSpace($InstallDirName)) {
    $InstallDirName = $Name
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$template = Join-Path $scriptRoot "app.iss"
if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
    Fail "Missing Inno template: $template"
}

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$entrypoint = Join-Path $sourcePath $Exe
if (-not (Test-Path -LiteralPath $entrypoint -PathType Leaf)) {
    Fail "Entrypoint does not exist inside source directory: $entrypoint"
}

$outputFull = [System.IO.Path]::GetFullPath($Output)
if ([System.IO.Path]::GetExtension($outputFull) -ne ".exe") {
    Fail "Output must end in .exe"
}
$outputDir = Split-Path -Parent $outputFull
$outputBaseName = [System.IO.Path]::GetFileNameWithoutExtension($outputFull)
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$candidates = @()
if ($env:INNO_SETUP_ISCC) { $candidates += $env:INNO_SETUP_ISCC }
foreach ($major in @("7", "6")) {
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup $major\ISCC.exe") }
    if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} "Inno Setup $major\ISCC.exe") }
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles "Inno Setup $major\ISCC.exe") }
}

$iscc = $null
foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $iscc = $candidate
        break
    }
}
if (-not $iscc) {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $iscc = $command.Source }
}
if (-not $iscc) {
    Fail "Inno Setup 7 compiler (ISCC.exe) not found"
}

$values = @($Name, $Version, $AppId, $Exe, $sourcePath, $outputDir, $outputBaseName, $Publisher, $InstallDirName)
foreach ($value in $values) {
    if ($value.Contains('"') -or $value.Contains([char]13) -or $value.Contains([char]10)) {
        Fail 'Values may not contain quotes or newlines'
    }
}

$args = @(
    "/Qp",
    "/DAppName=$Name",
    "/DAppVersion=$Version",
    "/DAppId=$AppId",
    "/DAppExe=$Exe",
    "/DSourceDir=$sourcePath",
    "/DOutputDir=$outputDir",
    "/DOutputBaseName=$outputBaseName",
    "/DPublisher=$Publisher",
    "/DInstallDirName=$InstallDirName",
    $template
)

& $iscc @args
if ($LASTEXITCODE -ne 0) {
    Fail "ISCC.exe failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $outputFull -PathType Leaf)) {
    Fail "Expected setup executable was not produced: $outputFull"
}

$hash = (Get-FileHash -LiteralPath $outputFull -Algorithm SHA256).Hash.ToLowerInvariant()
$info = Get-Item -LiteralPath $outputFull

[ordered]@{
    schema = 1
    ok = $true
    name = $Name
    version = $Version
    app_id = $AppId
    entrypoint = $Exe
    source = $sourcePath
    setup = $info.FullName
    size = $info.Length
    sha256 = $hash
} | ConvertTo-Json -Compress
