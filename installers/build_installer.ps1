<#
.SYNOPSIS
  Builds the POS, packages it into installers\inventory_pos-<version>.exe, and writes the
  update manifest that tells installed tills the new version exists.

.DESCRIPTION
  Must run on Windows. Flutter refuses a Windows build from any other host
  ("build windows" only supported on Windows hosts), and Inno Setup's compiler is Windows-only,
  so there is no way to produce this from the Mac the rest of the project is developed on.

  Run from anywhere; paths are resolved relative to this script.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File installers\build_installer.ps1

.EXAMPLE
  # Package only, when a Release build is already present.
  powershell -ExecutionPolicy Bypass -File installers\build_installer.ps1 -SkipFlutterBuild
#>

[CmdletBinding()]
param(
  # Skips straight to packaging when a Release build is already present.
  [switch]$SkipFlutterBuild,

  # Where the installer will be published. The manifest's download URL is built from
  # this plus the installer's filename.
  #
  # A parameter rather than a constant because moving the builds somewhere else must
  # stay a one-flag change. Installed tills do not know this address: they read it out
  # of the manifest at run time, which is the whole reason the build host can move
  # without shipping a release. See lib/core/update/update_endpoints.dart.
  [string]$ReleaseBaseUrl,

  # Release tag the assets are attached to. Defaults to v<version>.
  [string]$Tag
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

# ── Update manifest ─────────────────────────────────────────────────────────
# Written here, from the installer that was just produced, rather than by hand later.
#
# The hash and the size are measured off the actual file. A manifest typed out
# separately drifts the first time someone rebuilds and forgets, and the symptom is
# every till in the field refusing its download as corrupt — with no error anywhere
# near the person who caused it.
if (-not $Tag) { $Tag = "v$version" }
if (-not $ReleaseBaseUrl) {
  $ReleaseBaseUrl = "https://github.com/Bridge77tech/POS-Release/releases/download/$Tag"
}

$installerFile = Get-Item $output
$sha256 = (Get-FileHash -Algorithm SHA256 -Path $output).Hash.ToLowerInvariant()

# Ordered so the file reads the way the app parses it. Depth matters: ConvertTo-Json
# silently truncates nested objects below its default of 2.
$manifest = [ordered]@{
  schema  = 1
  version = $version
  url     = "$($ReleaseBaseUrl.TrimEnd('/'))/$($installerFile.Name)"
  sha256  = $sha256
  size    = [int64]$installerFile.Length
  notes   = ""
}

# UTF-8 without a BOM. PowerShell 5's Out-File writes one by default, and a BOM ahead
# of the opening brace makes jsonDecode throw on the till — which the updater treats
# as "no update", so it fails silently and forever rather than loudly once.
$manifestPath = Join-Path $installerDir 'latest.json'
$json = ($manifest | ConvertTo-Json -Depth 4)
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "Installer: $output"
Write-Host "Size: $([math]::Round($installerFile.Length / 1MB, 1)) MB"
Write-Host "SHA-256: $sha256"
Write-Host "Manifest: $manifestPath"
Write-Host ""
Write-Host "To publish this build:"
Write-Host "  1. gh release create $Tag `"$output`" --repo Bridge77tech/POS-Release --title `"$version`""
Write-Host "  2. Copy $manifestPath over v1/pos/windows/latest.json in POS-Release and commit."
Write-Host ""
Write-Host "Step 2 is what makes tills see it. Do it after step 1, never before:"
Write-Host "publishing the manifest first points every till at a file that is not there yet."

# ── Signing (waiting on a certificate) ──────────────────────────────────────
# Nothing below runs yet. When the code-signing certificate arrives, this is the whole
# change — two commands, no updater code touched.
#
#   1. Sign the application, before ISCC packages it. Insert above the "Package" block:
#
#        & signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 `
#            /f $env:PROXYPOS_CERT_PFX /p $env:PROXYPOS_CERT_PASSWORD $exe
#
#   2. Sign the installer ISCC produces, by adding to [Setup] in inventory_pos.iss:
#
#        SignTool=proxypos
#
#      and registering that tool once per build machine (Inno Setup IDE →
#      Tools → Configure Sign Tools), or by signing $output here with the same
#      signtool call.
#
# Timestamping (/tr) is not optional: without it every installer ever shipped stops
# validating the day the certificate expires, including ones already installed.
#
# The updater needs no change at all. It verifies the download against the SHA-256 in
# the manifest, which is about the file arriving intact and is unrelated to who signed
# it. What signing changes is the UAC prompt: "Unknown publisher" becomes the company
# name. Until then the owner sees that warning on every update, which is expected.
