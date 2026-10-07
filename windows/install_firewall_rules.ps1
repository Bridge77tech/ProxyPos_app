# install_firewall_rules.ps1
# Run this script once on the end-user machine (as Administrator) after
# copying the release folder, to pre-allow ProxyPOS.exe through
# the Windows Firewall without triggering a popup on first launch.
#
# Usage (from the release folder):
#   Right-click -> "Run with PowerShell"   (will auto-elevate)
#   — or —
#   powershell -ExecutionPolicy Bypass -File install_firewall_rules.ps1

# ── Auto-elevate to Administrator if not already ─────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal]
          [Security.Principal.WindowsIdentity]::GetCurrent()
         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# ── Resolve exe path relative to this script ─────────────────────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exeName   = "ProxyPOS.exe"
$exePath   = Join-Path $scriptDir $exeName

if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: Could not find $exeName next to this script." -ForegroundColor Red
    Write-Host "Make sure this script is placed in the same folder as $exeName." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ruleName = "Inventory POS App"

# ── Remove stale rules first (idempotent re-runs) ────────────────────────────
netsh advfirewall firewall delete rule name="$ruleName" | Out-Null

# ── Add inbound rule (scanner / LAN callbacks, barcode devices, etc.) ────────
netsh advfirewall firewall add rule `
    name="$ruleName" `
    dir=in `
    action=allow `
    program="$exePath" `
    enable=yes `
    profile=any

# ── Add outbound rule (API calls to your backend) ────────────────────────────
netsh advfirewall firewall add rule `
    name="$ruleName" `
    dir=out `
    action=allow `
    program="$exePath" `
    enable=yes `
    profile=any

Write-Host ""
Write-Host "Firewall rules added successfully for:" -ForegroundColor Green
Write-Host "  $exePath" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
