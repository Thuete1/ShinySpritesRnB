param(
    [switch]$DryRun,
    [string]$NumberList = "scripts/number_list.txt",
    [string]$FinalList = "scripts/final_names_list.txt",
    [string]$SourceDir = ".",
    [string]$DestDir = "ShinySprites"
)

function Normalize-Filename([string]$name) {
    if (-not $name) { return $name }
    $n = $name.Trim()
    return $n
}

if (-not (Test-Path $NumberList)) { Write-Host "Number list not found: $NumberList"; exit 1 }
if (-not (Test-Path $FinalList)) { Write-Host "Final names list not found: $FinalList"; exit 1 }

# Read source list robustly
$numbers = @()
Get-Content $NumberList | ForEach-Object {
    $ln = $_.ToString().Trim()
    if ($ln -ne '') { $numbers += $ln }
}

# Read final/target list robustly and strip optional prefix
$finals = @()
Get-Content $FinalList | ForEach-Object {
    $ln = $_.ToString() -replace '^RnBRegularSprites/',''
    $ln = $ln.Trim()
    if ($ln -ne '') { $finals += $ln }
}

$total = [math]::Min($numbers.Count, $finals.Count)
Write-Host "Mapping $total items (using min of source/target lists): $($numbers.Count) source, $($finals.Count) target"

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$backupDir = Join-Path $DestDir "EXTRA_BACKUP_MAP_$timestamp"

$processed = 0
$copied = 0
$skipped = 0
$missing = 0
$backedUp = 0

for ($i = 0; $i -lt $total; $i++) {
    $processed++
    $srcEntry = $numbers[$i]
    $targetBasename = $finals[$i]
    if (-not $targetBasename.ToLower().EndsWith('.png')) { $targetBasename += '.png' }
    $destPath = Join-Path $DestDir $targetBasename

    # Determine candidate source files. Prefer exact entry, then numeric fallback (leading digits). Also try lowercase
    $candidates = @()
    $candidates += $srcEntry
    if ($srcEntry -match '^\s*(\d+)') { $num = $matches[1]; $candidates += ("$num.png") }
    # ensure unique
    $candidates = $candidates | Select-Object -Unique

    $srcFound = $null
    foreach ($c in $candidates) {
        $tp = Join-Path $SourceDir $c
        if (Test-Path $tp) { $srcFound = $tp; break }
        $tpLower = Join-Path $SourceDir ($c.ToLower())
        if (Test-Path $tpLower) { $srcFound = $tpLower; break }
        $tpUpper = Join-Path $SourceDir ($c.ToUpper())
        if (Test-Path $tpUpper) { $srcFound = $tpUpper; break }
    }

    if (-not $srcFound) {
        Write-Host "MISSING: No source found for '$srcEntry' (position $([int]($i+1))) -> will skip" -ForegroundColor Yellow
        $missing++
        continue
    }

    if ($DryRun) {
        Write-Host "DRYRUN: Would copy: $srcFound -> $destPath"
        if (Test-Path $destPath) { Write-Host "DRYRUN: Would backup existing $destPath -> $backupDir" }
        $copied++
        continue
    }

    # Ensure dest dir exists
    if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir | Out-Null }

    # Backup existing dest if present
    if (Test-Path $destPath) {
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        $backupPath = Join-Path $backupDir $targetBasename
        Move-Item -Path $destPath -Destination $backupPath -Force
        $backedUp++
        Write-Host "Backed up existing: $destPath -> $backupPath"
    }

    try {
        Copy-Item -Path $srcFound -Destination $destPath -Force
        Write-Host "Copied: $srcFound -> $destPath"
        $copied++
    } catch {
        Write-Host "ERROR copying $srcFound -> $destPath : $($_.Exception.Message)" -ForegroundColor Red
        $skipped++
    }
}

Write-Host "--- Summary ---"
Write-Host "Processed: $processed"
Write-Host "Copied (or planned in dry-run): $copied"
Write-Host "Backed up existing dest files: $backedUp"
Write-Host "Skipped due to errors: $skipped"
Write-Host "Missing sources: $missing"
if ($DryRun) { Write-Host "Dry-run mode: no files were modified." }
else { Write-Host "Destination folder: $DestDir (backups placed under $backupDir if any)" }
