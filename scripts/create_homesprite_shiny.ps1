param(
    [string]$Source = (Join-Path $env:USERPROFILE 'Documents\GitHub\ShinySpritesRnB\ShinySprites\ActualSprites'),
    [string]$Dest = (Join-Path $env:USERPROFILE 'Documents\GitHub\ShinySpritesRnB\HomeSpriteShiny'),
    [double]$Scale = 2.0,
    [switch]$DryRun
)

[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')

if (-not (Test-Path -LiteralPath $Source)) {
    Write-Error "Source path not found: $Source"
    exit 1
}

if (-not (Test-Path -LiteralPath $Dest)) {
    if ($DryRun) { Write-Host "Would create folder: $Dest" } else { New-Item -ItemType Directory -LiteralPath $Dest | Out-Null }
}

$files = Get-ChildItem -LiteralPath $Source -Filter *.png -File | Sort-Object Name
Write-Host "Found $($files.Count) PNG files in $Source"

foreach ($f in $files) {
    $destPath = Join-Path $Dest $f.Name
    if ($DryRun) {
        Write-Host "DRYRUN: $($f.Name) -> $destPath (scale $Scale)"
        continue
    }

    try {
        $img = [System.Drawing.Image]::FromFile($f.FullName)
        $newW = [int]([Math]::Max(1, [Math]::Round($img.Width * $Scale)))
        $newH = [int]([Math]::Max(1, [Math]::Round($img.Height * $Scale)))

        $bmp = New-Object System.Drawing.Bitmap $newW, $newH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        $bmp.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($img, 0, 0, $newW, $newH)

        $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)

        $g.Dispose()
        $bmp.Dispose()
        $img.Dispose()

        Write-Host "Saved: $destPath"
    } catch {
        Write-Warning "Failed to process $($f.FullName): $_"
    }
}

Write-Host "Done. Output folder: $Dest"
