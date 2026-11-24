<#
.SYNOPSIS
Creates/refreshes Desktop & Start Menu shortcuts with custom icon for Hardened Toolkit
#>

$AppName      = "Hardened Toolkit"
$ShortcutName = "Hardened Toolkit.lnk"
$IconName     = "HardenedToolkit.ico"

Write-Host "`n=== $AppName — Shortcut Generator ===" -ForegroundColor Cyan

# --- Step 1: Locate files ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$iconPath  = Join-Path $scriptDir $IconName

if (-not (Test-Path -LiteralPath $iconPath)) {
    Write-Host "[ERROR] $IconName not found in:`n   $scriptDir" -ForegroundColor Red
    Write-Host "   Make sure the .ico file is in the SAME folder as this script!" -ForegroundColor Yellow
    pause
    exit 1
}

# Try to find installed main script
$programFiles = $env:ProgramFiles
$targetDir    = Join-Path $programFiles "HardenedToolkit"
$targetScript = Join-Path $targetDir "HardenedToolkit.ps1"

if (-not (Test-Path -LiteralPath $targetScript)) {
    Write-Host "[!] Installed version not found at:`n   $targetScript" -ForegroundColor Yellow
    Write-Host "   Using local script instead..." -ForegroundColor Gray
    $targetScript = Join-Path $scriptDir "HardenedToolkit.ps1"
}

$psExe    = Join-Path $PSHOME "powershell.exe"
$runArgs  = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$targetScript`" -Hidden"

# --- Step 2: Create shortcut helper ---
function New-CustomShortcut {
    param($Path, $Icon)
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($Path)
    $sc.TargetPath        = $psExe
    $sc.Arguments         = $runArgs
    $sc.WorkingDirectory  = $targetDir
    $sc.Description      = "Launch $AppName"
    $sc.IconLocation      = $Icon
    $sc.Save()

    # Set "Run as Administrator" flag
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -gt 0x15) {
            $bytes[0x15] = $bytes[0x15] -bor 0x20
            [System.IO.File]::WriteAllBytes($Path, $bytes)
        }
        return $true
    } catch { return $false }
}

# --- Step 3: Create shortcuts ---
$desktopPath = [Environment]::GetFolderPath("DesktopDirectory")
$desktopLnk  = Join-Path $desktopPath $ShortcutName
if (New-CustomShortcut $desktopLnk $iconPath) {
    Write-Host "[OK] Desktop shortcut → $desktopLnk" -ForegroundColor Green
}

$smPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$smLnk   = Join-Path $smPath $ShortcutName
if (New-CustomShortcut $smLnk $iconPath) {
    Write-Host "[OK] Start Menu shortcut → $smLnk" -ForegroundColor Green
}

Write-Host "`n✅ Done! Your custom icon should appear on both shortcuts now." -ForegroundColor Green
Write-Host "   (You may need to wait a few seconds or press F5 to refresh the icons)" -ForegroundColor Gray
pause
