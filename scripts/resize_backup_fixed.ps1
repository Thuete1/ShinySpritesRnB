# Get 8.3 short names to work around encoding issues
$sourceBase = "C:\Users\ALEXAND~1\DOCUME~1\GitHub\ShinySpritesRnB\ShinySprites"
$targetBase = "C:\Users\ALEXAND~1\DOCUME~1\GitHub"

$SourceFolder = "$sourceBase\EXTRA_B~1\ShinySprites\ActualSprites"
$TargetDimFolder = "$targetBase\coloured-home-sprites"
$OutputFolder = "C:\Users\ALEXAND~1\DOCUME~1\GitHub\ShinySpritesRnB\output_resized_backup"

Write-Host "Source: $SourceFolder"
Write-Host "Target: $TargetDimFolder"
Write-Host "Output: $OutputFolder"

# Verify paths exist
if (-not (Test-Path $SourceFolder)) {
    Write-Host "Source not found"
    exit 1
}
if (-not (Test-Path $TargetDimFolder)) {
    Write-Host "Target folder not found"
    exit 1
}

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
    Write-Host "Target dimensions: ${targetWidth}x${targetHeight}"
} catch {
    Write-Error "Failed to read target dimensions: $_"
    exit 1
}

# Create output folder if needed
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Get all PNG files
$pngFiles = Get-ChildItem -Path $SourceFolder -Filter "*.png"
$totalFiles = $pngFiles.Count
$successCount = 0
$failCount = 0

Write-Host "Processing $totalFiles PNG files..."

$pngFiles | ForEach-Object -Begin { $count = 0 } -Process {
    $count++
    $file = $_
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
        if ($count % 100 -eq 0) {
            Write-Host "  [$count/$totalFiles] Processed"
        }
    } catch {
        $failCount++
        Write-Warning "Failed: $($file.Name)"
    }
}

Write-Host ""
Write-Host "Complete! Success: $successCount, Failed: $failCount"
