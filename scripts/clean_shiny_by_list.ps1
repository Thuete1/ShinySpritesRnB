<#
clean_shiny_by_list.ps1

Usage:
  From repo root:
    .\scripts\clean_shiny_by_list.ps1 [-RawListFile .\scripts\desired_list_raw.txt] [-ShinyDir .\ShinySprites] [-BackupDirName EXTRA_BACKUP]

This script reads a raw list (space/newline separated paths like `RnBRegularSprites/name.png`),
extracts basenames, then moves any PNG in `ShinySprites/` not present in that list
into a timestamped backup directory under `ShinySprites/`.
#>

param(
    [string]$RawListFile = ".\scripts\desired_list_raw.txt",
    [string]$ShinyDir = ".\ShinySprites",
    [string]$BackupDirName = "EXTRA_BACKUP",
    [switch]$DryRun
)

$root = (Get-Location).Path
$rawPath = Join-Path $root $RawListFile
$shinyPath = Join-Path $root $ShinyDir

if (-not (Test-Path $shinyPath)) { Write-Error "Shiny directory not found: $shinyPath"; exit 1 }
if (-not (Test-Path $rawPath)) { Write-Error "Raw list file not found: $rawPath"; exit 1 }

# Read raw list and extract basenames
$raw = Get-Content -Path $rawPath -Raw
$tokens = -split $raw -ne ''
$desired = @{}
foreach ($t in $tokens) {
    if ($t -match '\.png$') {
        $b = [System.IO.Path]::GetFileName($t)
        if ($b) { $desired[$b] = $true }
    }
}

Write-Host "Desired names count: $($desired.Keys.Count)"

# Find existing PNGs in ShinySprites
$existing = Get-ChildItem -Path $shinyPath -Filter "*.png" -File

$toMove = @()
foreach ($f in $existing) { if (-not $desired.ContainsKey($f.Name)) { $toMove += $f } }

Write-Host "Found $($existing.Count) PNGs in $ShinyDir; $($toMove.Count) extra files will be moved."

if ($toMove.Count -eq 0) { Write-Host "Nothing to do."; exit 0 }

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$backupPath = Join-Path $shinyPath ($BackupDirName + "_" + $timestamp)

if ($DryRun) { Write-Host "Dry-run mode: no files will be moved. Backup path would be: $backupPath" }
else { New-Item -Path $backupPath -ItemType Directory | Out-Null; Write-Host "Created backup dir: $backupPath" }

$moved = 0
foreach ($f in $toMove) {
    $dest = Join-Path $backupPath $f.Name
    if ($DryRun) { Write-Host "Would move: $($f.FullName) -> $dest" }
    else {
        Move-Item -Path $f.FullName -Destination $dest -Force
        $moved++
        Write-Host "Moved: $($f.Name)"
    }
}

Write-Host "Done. moved=$moved (dryrun=$([bool]$DryRun))"
