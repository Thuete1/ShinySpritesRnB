<#
clean_shiny_keep_list.ps1

Reads `scripts/desired_keep_raw.txt`, normalizes names (lowercase, spaces->hyphens),
appends `.png`, then moves any file in `ShinySprites/` not in that keep list into
a timestamped backup directory under `ShinySprites/`.

Usage:
  .\scripts\clean_shiny_keep_list.ps1 [-DryRun]
#>

param(
    [string]$RawFile = ".\scripts\desired_keep_raw.txt",
    [string]$ShinyDir = ".\ShinySprites",
    [string]$BackupPrefix = "EXTRA_BACKUP_KEEP",
    [switch]$DryRun
)

$root = (Get-Location).Path
$raw = Join-Path $root $RawFile
$shiny = Join-Path $root $ShinyDir

if (-not (Test-Path $raw)) { Write-Error "Raw file not found: $raw"; exit 1 }
if (-not (Test-Path $shiny)) { Write-Error "Shiny dir not found: $shiny"; exit 1 }

$lines = Get-Content -Path $raw | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$keep = @{}
foreach ($l in $lines) {
    $norm = $l.ToLower().Replace(' ', '-').Replace('_','-')
    # ensure no trailing .png in input; if present, keep it
    if ($norm -notmatch '\.png$') { $norm = $norm + '.png' }
    $keep[$norm] = $true
}

Write-Host "Keep list contains $($keep.Keys.Count) entries."

$existing = Get-ChildItem -Path $shiny -Filter '*.png' -File
$toMove = @()
foreach ($f in $existing) { if (-not $keep.ContainsKey($f.Name.ToLower())) { $toMove += $f } }

Write-Host "Found $($existing.Count) PNGs; $($toMove.Count) will be moved to backup."
if ($toMove.Count -eq 0) { Write-Host 'Nothing to move.'; exit 0 }

$ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
$backup = Join-Path $shiny ($BackupPrefix + '_' + $ts)
if (-not $DryRun) { New-Item -Path $backup -ItemType Directory | Out-Null; Write-Host "Created backup: $backup" }

$moved = 0
foreach ($f in $toMove) {
    $dest = Join-Path $backup $f.Name
    if ($DryRun) { Write-Host "Would move: $($f.FullName) -> $dest" }
    else { Move-Item -Path $f.FullName -Destination $dest -Force; Write-Host "Moved: $($f.Name)"; $moved++ }
}

Write-Host "Done. moved=$moved (dryrun=$([bool]$DryRun))"
