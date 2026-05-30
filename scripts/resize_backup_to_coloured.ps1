# Resize backup sprites to match coloured-home-sprites dimensions
[CmdletBinding()]
param(
    [string]$SourceFolder = "C:\Users\Alexander Thüte\Documents\GitHub\ShinySpritesRnB\ShinySprites\EXTRA_BACKUP_ORIGINALS_RESIZE_20260529_231447\ShinySprites\ActualSprites",
    [string]$TargetDimFolder = "C:\Users\Alexander Thüte\Documents\GitHub\coloured-home-sprites",
    [string]$OutputFolder = "C:\Users\Alexander Thüte\Documents\GitHub\ShinySpritesRnB\output_resized_backup",
    [switch]$Overwrite
)

Add-Type -AssemblyName System.Drawing

# Get target dimensions from a sample file
$sampleFile = Get-ChildItem -Path $TargetDimFolder -Filter "*.png" | Select-Object -First 1
if (-not $sampleFile) {
    Write-Error "No PNG files found in target dimensions folder"
    exit 1
}

try {
    $sampleImg = [System.Drawing.Image]::FromFile($sampleFile.FullName)
    $targetWidth = $sampleImg.Width
    $targetHeight = $sampleImg.Height
    $sampleImg.Dispose()
    Write-Host "Target dimensions detected: ${targetWidth}x${targetHeight}"
} catch {
    Write-Error "Failed to read target dimensions: $_"
    exit 1
}

# Create output folder if it doesn't exist
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "Created output folder: $OutputFolder"
}

# Get all PNG files from source
$pngFiles = Get-ChildItem -Path $SourceFolder -Filter "*.png"
$totalFiles = $pngFiles.Count
$successCount = 0
$failCount = 0

Write-Host "Processing $totalFiles PNG files..."
Write-Host ""

$pngFiles | ForEach-Object -Begin { $count = 0 } -Process {
    $count++
    $file = $_
    $destPath = if ($Overwrite) { $file.FullName } else { Join-Path $OutputFolder $file.Name }
    
    try {
        # Load original image
        $originalImg = [System.Drawing.Image]::FromFile($file.FullName)
        
        # Create resized bitmap
        $resizedBitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($resizedBitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($originalImg, 0, 0, $targetWidth, $targetHeight)
        $graphics.Dispose()
        
        # Save resized image
        $resizedBitmap.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resizedBitmap.Dispose()
        $originalImg.Dispose()
        
        $successCount++
        if ($count % 50 -eq 0) {
            Write-Host "[$count/$totalFiles] Processed $($file.Name)"
        }
    } catch {
        $failCount++
        Write-Warning "Failed to process $($file.Name): $_"
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Resize Complete!"
Write-Host "Successful: $successCount"
Write-Host "Failed: $failCount"
Write-Host "=========================================="
if ($failCount -eq 0) {
    Write-Host "All files resized successfully to ${targetWidth}x${targetHeight}!"
}
