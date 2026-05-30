Add-Type -AssemblyName System.Drawing

$targetFile = 'C:\Users\Alexander Thüte\Documents\GitHub\coloured-home-sprites\abomasnow.png'
$img = [System.Drawing.Image]::FromFile($targetFile)
$w = $img.Width
$h = $img.Height
Write-Host "Target dimensions: $w x $h"
$img.Dispose()

$sourcePath = 'C:\Users\Alexander Thüte\Documents\GitHub\ShinySpritesRnB\ShinySprites\EXTRA_BACKUP_ORIGINALS_RESIZE_20260529_231447\ShinySprites\ActualSprites'
$files = Get-ChildItem -Path $sourcePath -Filter '*.png'
Write-Host "Source files found: $($files.Count)"

if ($files) {
    $sourceImg = [System.Drawing.Image]::FromFile($files[0].FullName)
    $sw = $sourceImg.Width
    $sh = $sourceImg.Height
    Write-Host "Sample source file: $($files[0].Name)"
    Write-Host "Source dimensions: $sw x $sh"
    $sourceImg.Dispose()
}
