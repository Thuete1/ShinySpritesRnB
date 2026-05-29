<#
rename_to_pokedex.ps1

Usage:
  From the repo root:
    .\scripts\rename_to_pokedex.ps1 -NumericFolder "." -DestDir "ShinySprites"

This script maps numeric PNG filenames like `1.png` -> `bulbasaur.png` using
PokéAPI (Pokédex order). If PokéAPI is unavailable it falls back to
`scripts/mapping.txt` if present.
#>

param(
    [string]$NumericFolder = ".",
    [string]$DestDir = "ShinySprites",
    [int]$Limit = 2000,
    [switch]$DryRun
)

$root = (Get-Location).Path
$numericPath = Join-Path $root $NumericFolder
$destPath = Join-Path $root $DestDir

if (-not (Test-Path $numericPath)) {
    Write-Error "Numeric folder not found: $numericPath"
    exit 1
}

if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath | Out-Null }

# Try to fetch Pokédex-ordered names from PokéAPI
try {
    Write-Host "Fetching PokéAPI list (limit=$Limit) ..."
    $resp = Invoke-RestMethod -Uri ("https://pokeapi.co/api/v2/pokemon?limit=" + $Limit) -ErrorAction Stop
    $names = $resp.results | ForEach-Object { $_.name }
} catch {
    Write-Warning ("Could not fetch from PokéAPI: " + $_.ToString() + " Falling back to scripts/mapping.txt if present.")
    $mappingFile = Join-Path $root "scripts\mapping.txt"
    if (Test-Path $mappingFile) {
        $names = Get-Content -Path $mappingFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    } else {
        Write-Error "No mapping available (PokéAPI failed and scripts/mapping.txt not found)."
        exit 1
    }
}

$processed = 0; $copied = 0; $skipped = 0; $errors = 0

Get-ChildItem -Path $numericPath -Filter "*.png" -File | ForEach-Object {
    $fileName = $_.Name
    if ($fileName -match '^(\d+)\.png$') {
        $num = [int]$Matches[1]
        $processed++
        if ($num -ge 1 -and $num -le $names.Count) {
            $target = ($names[$num - 1].Trim()) + ".png"
            $targetPath = Join-Path $destPath $target
            if ($DryRun) {
                Write-Host "Would rename $fileName -> $target"
            } else {
                try {
                    Copy-Item -Path $_.FullName -Destination $targetPath -Force
                    Write-Host "Renamed $fileName -> $target"
                    $copied++
                } catch {
                    Write-Warning ("Failed to copy " + $fileName + " -> " + $target + ": " + $_.ToString())
                    $errors++
                }
            }
        } else {
            Write-Warning "No mapping for number $num (file $fileName); names count: $($names.Count)"
            $skipped++
        }
    } else {
        Write-Verbose "Skipping non-numeric file $fileName"
        $skipped++
    }
}

Write-Host "Summary: processed=$processed, copied=$copied, skipped=$skipped, errors=$errors"
