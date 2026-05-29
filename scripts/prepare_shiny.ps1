<#
prepare_shiny.ps1

Usage:
  1) Place numeric PNGs (e.g. 0.png, 1.png, 2.png ...) into a folder you choose, e.g. `ShinyNumbers`.
  2) Edit `scripts/mapping.txt` so that each line i (0-based) contains the target filename for `i.png` (for example line 1 -> "bulbasaur.png").
     - If your numeric files start at 1 instead of 0, set $ZeroBased = $false below.
  3) Run this script from the repo root in PowerShell:
       .\scripts\prepare_shiny.ps1 -NumericFolder "ShinyNumbers"

What it does:
  - Ensures `ShinySprites` exists
  - Copies all `*-mega.png` from `RnBRegularSprites` into `ShinySprites`
  - If a numeric folder exists and `scripts/mapping.txt` is present, it will copy/rename numeric PNGs into `ShinySprites` using the mapping.
#>

param(
    [string]$SourceDir = "RnBRegularSprites",
    [string]$NumericFolder = "ShinyNumbers",
    [string]$DestDir = "ShinySprites",
    [object]$ZeroBased = $null
)

$root = (Get-Location).Path
$sourcePath = Join-Path $root $SourceDir
$destPath = Join-Path $root $DestDir
$numericPath = Join-Path $root $NumericFolder
$mappingFile = Join-Path $root "scripts\mapping.txt"

if (-not (Test-Path $sourcePath)) {
    Write-Error "Source directory '$SourceDir' not found. Expected at: $sourcePath"
    exit 1
}

if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath | Out-Null }

# Copy all mega sprites
Get-ChildItem -Path $sourcePath -Filter "*-mega.png" -File -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $destPath $_.Name) -Force
    Write-Host "Copied mega: $($_.Name)"
}

# Rename numeric files if mapping exists
if (-not (Test-Path $numericPath)) {
    Write-Host "Numeric folder '$NumericFolder' not found. Skipping numeric renaming step."
    exit 0
}

if (-not (Test-Path $mappingFile)) {
    Write-Error "Mapping file 'scripts/mapping.txt' not found. Create it with one target filename per line (0-based)."
    exit 1
}

$mapping = Get-Content -Path $mappingFile

# Auto-detect zero/one-based numeric filenames if the caller didn't provide a boolean
if ($ZeroBased -eq $null) {
    $numericFiles = Get-ChildItem -Path $numericPath -Filter "*.png" -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    if ($numericFiles -contains '0.png') {
        $ZeroBased = $true
        Write-Host "Auto-detected numeric files are 0-based. Using ZeroBased = $ZeroBased"
    } elseif ($numericFiles -contains '1.png') {
        $ZeroBased = $false
        Write-Host "Auto-detected numeric files are 1-based. Using ZeroBased = $ZeroBased"
    } else {
        # default to true if unclear
        $ZeroBased = $true
        Write-Host "Could not auto-detect numeric base; defaulting to ZeroBased = $ZeroBased"
    }
} else {
    # ensure boolean conversion for common string/number inputs
    try { $ZeroBased = [bool]$ZeroBased } catch { $ZeroBased = $ZeroBased }
}

Get-ChildItem -Path $numericPath -Filter "*.png" -File | ForEach-Object {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    if ($base -match '^(\d+)$') {
        $idx = [int]$Matches[1]
        if (-not $ZeroBased) { $idx = $idx - 1 }
        if ($idx -ge 0 -and $idx -lt $mapping.Count) {
            $targetName = $mapping[$idx].Trim()
            if ($targetName -ne "") {
                $targetPath = Join-Path $destPath $targetName
                Copy-Item -Path $_.FullName -Destination $targetPath -Force
                Write-Host "Renamed numeric $($_.Name) -> $targetName"
            } else {
                Write-Warning "Mapping line for index $idx is empty; skipping $($_.Name)"
            }
        } else {
            Write-Warning "No mapping for index $idx (file: $($_.Name)); mapping lines: $($mapping.Count)"
        }
    } else {
        Write-Verbose "Skipping non-numeric file: $($_.Name)"
    }
}

Write-Host "Done. Check the '$DestDir' folder."