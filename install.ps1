param(
  [switch]$Uninstall,
  [switch]$Silent
)

# Installs a packaged Windows build per-user — no admin rights, no MSI. Run from
# the extracted release folder (the one holding `dist\`).

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$AppName = 'Game Collection'
$ExeName = 'game_collection.exe'
$InstallDir = Join-Path $env:LOCALAPPDATA 'GameCollection'
$SourceDir = Join-Path $PSScriptRoot 'dist\GameCollection-windows'
$StartMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$ShortcutPath = Join-Path $StartMenuDir "$AppName.lnk"

# build.sh rewrites this line when it packages a release; the pubspec fallback
# keeps a run straight from the repo honest.
$Version = '0.0.0'
if ($Version -eq '0.0.0') {
  $versionFile = Join-Path $SourceDir 'version.txt'
  $pubspec = Join-Path $PSScriptRoot 'pubspec.yaml'
  if (Test-Path $versionFile) {
    $Version = (Get-Content $versionFile -First 1).Trim()
  } elseif (Test-Path $pubspec) {
    $line = Get-Content $pubspec | Select-String -Pattern '^version:\s*'
    if ($line) { $Version = ($line.Line -replace '^version:\s*', '').Trim() }
  }
}

function Write-Info { Write-Host "INFO: $($args[0])" -ForegroundColor Cyan }
function Write-Ok { Write-Host "OK:   $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "WARN: $($args[0])" -ForegroundColor Yellow }
function Write-Err { Write-Host "ERR:  $($args[0])" -ForegroundColor Red }

function Stop-App {
  $processName = [IO.Path]::GetFileNameWithoutExtension($ExeName)
  $running = Get-Process -Name $processName -ErrorAction SilentlyContinue
  if ($running) {
    Write-Info "Stopping running $AppName..."
    $running | Stop-Process -Force
    Start-Sleep -Milliseconds 800
  }
}

function New-Shortcut {
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($ShortcutPath)
  $shortcut.TargetPath = Join-Path $InstallDir $ExeName
  $shortcut.WorkingDirectory = $InstallDir
  $shortcut.Description = 'A collection of casual games'
  $shortcut.Save()
  Write-Ok "Start menu shortcut: $ShortcutPath"
}

function Install-App {
  if (-not (Test-Path (Join-Path $SourceDir $ExeName))) {
    Write-Err "Build not found at $SourceDir. Run './build.sh windows' first."
    exit 1
  }

  Stop-App
  Write-Info "Copying files to $InstallDir..."
  if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  Copy-Item (Join-Path $SourceDir '*') $InstallDir -Recurse -Force
  $count = (Get-ChildItem $InstallDir -Recurse -File).Count
  Write-Ok "Copied $count files"

  New-Shortcut

  Write-Ok "$AppName installed to $InstallDir"
  Write-Info 'Launch it from the Start menu'
  Write-Info "Run this script with -Uninstall to remove it"
}

function Uninstall-App {
  Write-Info "Uninstalling $AppName..."
  Stop-App
  if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Ok 'Removed Start menu shortcut'
  }
  if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
    Write-Ok "Removed $InstallDir"
  }
  Write-Ok 'Uninstall complete'
  # Saves live in the roaming app-support directory, not the install dir, so an
  # uninstall never throws away a run in progress.
  Write-Info 'Saved games were left untouched'
}

Write-Info "Installer for $AppName (v$Version)"

if ($Uninstall) {
  Uninstall-App
  if (-not $Silent) { Read-Host 'Press Enter to close' | Out-Null }
  exit 0
}

if ((Test-Path $InstallDir) -and (-not $Silent)) {
  Write-Info "$AppName is already installed at $InstallDir"
  $answer = Read-Host 'Reinstall/update? [Y/n]'
  if ($answer -match '^[Nn]') {
    Write-Info 'Update cancelled'
    exit 0
  }
}

Install-App
if (-not $Silent) { Read-Host 'Press Enter to close' | Out-Null }
