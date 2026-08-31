<#
.SYNOPSIS
  Builds the POS and packages it into installers\inventory_pos-<version>.exe

.DESCRIPTION
  Must run on Windows. Flutter refuses a Windows build from any other host
  ("build windows" only supported on Windows hosts), and Inno Setup's compiler is Windows-only,
  so there is no way to produce this from the Mac the rest of the project is developed on.

  Run from anywhere; paths are resolved relative to this script.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File installers\build_installer.ps1
#>

[CmdletBinding()]
param(
  # Skips straight to packaging when a Release build is already present.
  [switch]$SkipFlutterBuild
)

$ErrorActionPreference = 'Stop'

$installerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot  = Resolve-Path (Join-Path $installerDir '..')
$releaseDir   = Join-Path $projectRoot 'build\windows\x64\runner\Release'

# ── Version ─────────────────────────────────────────────────────────────────
# From pubspec, so the installer announces what it actually is. It used to be hardcoded to 1.0,
# which meant no till could be told whether it had the new build — the entire point of shipping one.
$pubspec = Get-Content (Join-Path $projectRoot 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
  throw "Could not read a version from pubspec.yaml."
}
$version = $Matches[1]
Write-Host "Version from pubspec: $version"

# ── Build ───────────────────────────────────────────────────────────────────
if (-not $SkipFlutterBuild) {
  Push-Location $projectRoot
  try {
    Write-Host "Building the Windows release..."
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed ($LASTEXITCODE)." }
  } finally {
    Pop-Location
  }
}

$exe = Join-Path $releaseDir 'inventory_app_pos.exe'
if (-not (Test-Path $exe)) {
  throw "No build output at $releaseDir. Run without -SkipFlutterBuild."
}

# The installer ships the whole Release folder, so say what is in it — a plugin DLL that failed to
# build would otherwise be noticed only when the app will not start on somebody's till.
$dlls = @(Get-ChildItem $releaseDir -Filter *.dll)
Write-Host "Release folder: $($dlls.Count) DLL(s), data folder $(if (Test-Path (Join-Path $releaseDir 'data')) { 'present' } else { 'MISSING' })"

# ── Package ─────────────────────────────────────────────────────────────────
$iscc = Get-Command iscc -ErrorAction SilentlyContinue
if (-not $iscc) {
  foreach ($candidate in @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
  )) {
    if (Test-Path $candidate) { $iscc = $candidate; break }
  }
}
if (-not $iscc) {
  throw "Inno Setup's compiler (ISCC.exe) was not found. Install Inno Setup 6, or add it to PATH."
}

$script = Join-Path $installerDir 'inventory_pos.iss'
Write-Host "Packaging..."
# The output name comes from the .iss (OutputBaseFilename), so it is decided in one place whether
# the build is scripted or run from the Inno Setup IDE.
& $iscc "/DMyAppVersion=$version" $script
if ($LASTEXITCODE -ne 0) { throw "ISCC failed ($LASTEXITCODE)." }

$output = Join-Path $installerDir "inventory_pos-$version.exe"
if (-not (Test-Path $output)) { throw "ISCC reported success but $output is not there." }

Write-Host ""
Write-Host "Installer: $output"
Write-Host "Size: $([math]::Round((Get-Item $output).Length / 1MB, 1)) MB"
