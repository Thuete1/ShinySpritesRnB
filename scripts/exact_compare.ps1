$A = Join-Path $env:USERPROFILE 'Documents\GitHub\ShinySpritesRnB\ShinySprites\ActualSprites'
$B = Join-Path $env:USERPROFILE 'Documents\GitHub\coloured-box-sprites'

$filesA = Get-ChildItem -LiteralPath $A -Filter *.png -File | Select-Object -ExpandProperty Name
$filesB = Get-ChildItem -LiteralPath $B -Filter *.png -File | Select-Object -ExpandProperty Name

$onlyA = foreach ($fa in $filesA) { if (-not ($filesB | Where-Object { $_ -ceq $fa })) { $fa } }
$onlyB = foreach ($fb in $filesB) { if (-not ($filesA | Where-Object { $_ -ceq $fb })) { $fb } }

$caseDiffs = foreach ($fa in $filesA) {
    $match = $filesB | Where-Object { $_.ToLower() -eq $fa.ToLower() }
    if ($match -and -not ($match | Where-Object { $_ -ceq $fa })) {
        [PSCustomObject]@{A=$fa;B=($match -join ', ')}
    }
}

$onlyA | Out-File "$PSScriptRoot\..\exact_only_in_A.txt" -Encoding utf8
$onlyB | Out-File "$PSScriptRoot\..\exact_only_in_B.txt" -Encoding utf8
$caseDiffs | Export-Csv -NoTypeInformation "$PSScriptRoot\..\case_mismatch_pairs.csv" -Encoding utf8

Write-Host 'Exact only in A:' ($onlyA.Count)
Write-Host 'Exact only in B:' ($onlyB.Count)
Write-Host 'Case-differing pairs:' ($caseDiffs.Count)
