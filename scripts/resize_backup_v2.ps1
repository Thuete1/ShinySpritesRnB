$ErrorActionPreference = 'Stop'

# Use environment variables to build paths correctly
$userProfile = $env:USERPROFILE
$SourceFolder = "$userProfile\Documents\GitHub\ShinySpritesRnB\ShinySprites\EXTRA_BACKUP_ORIGINALS_RESIZE_20260529_231447\ShinySprites\ActualSprites"
$TargetDimFolder = "$userProfile\Documents\GitHub\coloured-home-sprites"
$OutputFolder = "$userProfile\Documents\GitHub\ShinySpritesRnB\output_resized_backup"

Write-Host "Source: $SourceFolder"
Write-Host "Target: $TargetDimFolder"
Write-Host "Output: $OutputFolder"
Write-Host ""

# Verify paths exist
if (-not (Test-Path $SourceFolder)) {
    Write-Host "ERROR: Source folder not found"
    exit 1
}
Write-Host "[OK] Source folder found"

if (-not (Test-Path $TargetDimFolder)) {
    Write-Host "ERROR: Target folder not found"
    exit 1
}
Write-Host "[OK] Target folder found"

Add-Type -AssemblyName System.Drawing

# Get target dimensions
$sampleFile = Get-ChildItem -Path $TargetDimFolder -Filter "*.png" | Select-Object -First 1
if (-not $sampleFile) {
    Write-Host "ERROR: No PNG files in target folder"
    exit 1
}

$sampleImg = [System.Drawing.Image]::FromFile($sampleFile.FullName)
$targetWidth = $sampleImg.Width
$targetHeight = $sampleImg.Height
$sampleImg.Dispose()
Write-Host "[OK] Target dimensions: ${targetWidth}x${targetHeight}"

# Create output folder
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "[OK] Created output folder"
}

# Count PNG files
$pngFiles = @(Get-ChildItem -Path $SourceFolder -Filter "*.png")
$totalFiles = $pngFiles.Count
Write-Host "[OK] Found $totalFiles PNG files to process"
Write-Host ""

$successCount = 0
$failCount = 0

for ($i = 0; $i -lt $pngFiles.Count; $i++) {
    $file = $pngFiles[$i]
    $destPath = Join-Path $OutputFolder $file.Name
    
    try {
        $originalImg = [System.Drawing.Image]::FromFile($file.FullName)
        $resizedBitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($resizedBitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($originalImg, 0, 0, $targetWidth, $targetHeight)
        $graphics.Dispose()
        $resizedBitmap.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resizedBitmap.Dispose()
        $originalImg.Dispose()
        
        $successCount++
        $progress = [math]::Round((($i + 1) / $totalFiles) * 100)
        if (($i + 1) % 100 -eq 0 -or ($i + 1) -eq $totalFiles) {
            Write-Host "[$($i + 1)/$totalFiles] $progress% complete"
        }
    } catch {
        $failCount++
        Write-Warning "Failed [$($i + 1)]: $($file.Name) - $_"
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Resize Complete!"
Write-Host "Successful: $successCount / $totalFiles"
Write-Host "Failed: $failCount"
Write-Host "Output: $OutputFolder"
Write-Host "=========================================="
