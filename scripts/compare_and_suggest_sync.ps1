param(
  [switch]$DryRun = $true,
  [string]$A = "ShinySprites/ActualSprites",
  [string]$B = "c:\Users\Alexander Thüte\Documents\GitHub\coloured-box-sprites",
  [string]$BackupDir = "ShinySprites/EXTRA_SYNC_BACKUP_$(Get-Date -Format yyyyMMdd_HHmmss)"
)

function NormalizeName($name){
  $n = [IO.Path]::GetFileNameWithoutExtension($name).ToLower().Trim()
  $n = $n -replace '\s+','-'
  $n = $n -replace '[^a-z0-9\-\_]',''
  return $n
}

$filesA = Get-ChildItem -Path $A -Filter *.png -File -Recurse | ForEach-Object {
  [PSCustomObject]@{
    FullName = $_.FullName
    Key = NormalizeName($_.Name)
  }
}
$filesB = Get-ChildItem -Path $B -Filter *.png -File -Recurse | ForEach-Object {
  [PSCustomObject]@{
    FullName = $_.FullName
    Key = NormalizeName($_.Name)
  }
}

$mapA = @{}
foreach($f in $filesA){ if($f -and $f.Key){ $mapA[$f.Key] = $f.FullName } }
$mapB = @{}
foreach($f in $filesB){ if($f -and $f.Key){ $mapB[$f.Key] = $f.FullName } }

$onlyA = $mapA.Keys | Where-Object { -not $mapB.ContainsKey($_) } | Sort-Object
$onlyB = $mapB.Keys | Where-Object { -not $mapA.ContainsKey($_) } | Sort-Object
$both  = $mapA.Keys | Where-Object { $mapB.ContainsKey($_) } | Sort-Object

"Only in A (`$A`): $($onlyA.Count)" | Tee-Object -FilePath compare_report.txt
$onlyA | ForEach-Object { "{0} -> {1}" -f $_, $mapA[$_] } | Tee-Object -FilePath compare_only_in_A.txt -Append

"Only in B (`$B`): $($onlyB.Count)" | Tee-Object -FilePath compare_report.txt -Append
$onlyB | ForEach-Object { "{0} -> {1}" -f $_, $mapB[$_] } | Tee-Object -FilePath compare_only_in_B.txt -Append

"Matches (same normalized key): $($both.Count)" | Tee-Object -FilePath compare_report.txt -Append
$both | ForEach-Object { "{0} -> A:{1}  B:{2}" -f $_, $mapA[$_], $mapB[$_] } | Out-File sync_candidates.txt

# Suggest direct copy for keys only in B (i.e., B has file, A missing)
"Suggested copies (dry-run):" | Tee-Object -FilePath compare_report.txt -Append
$suggestedCopies = foreach($k in $onlyB){
  $src = $mapB[$k]
  $destName = [IO.Path]::GetFileName($src)
  $dest = Join-Path -Path $A -ChildPath $destName
  [PSCustomObject]@{Key=$k; Source=$src; Dest=$dest}
}

$suggestedCopies | Format-Table -AutoSize | Out-String | Tee-Object -FilePath sync_suggested_copies.txt
$suggestedCopies | Export-Csv -Path sync_suggested_copies.csv -NoTypeInformation -Force

if(-not $DryRun){
  New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
  foreach($row in $suggestedCopies){
    if(Test-Path $row.Dest){
      $bk = Join-Path $BackupDir ([IO.Path]::GetFileName($row.Dest))
      Move-Item -Path $row.Dest -Destination $bk -Force
    }
    Copy-Item -Path $row.Source -Destination $row.Dest -Force
    "Copied: $($row.Source) -> $($row.Dest)"
  }
  "Done. Copied $($suggestedCopies.Count) files. Backed up overwritten to $BackupDir" | Tee-Object -FilePath compare_report.txt -Append
} else {
  "Dry-run: no files changed. Review `sync_suggested_copies.csv`, `sync_candidates.txt`, `compare_only_in_A.txt`, `compare_only_in_B.txt`." | Tee-Object -FilePath compare_report.txt -Append
}
