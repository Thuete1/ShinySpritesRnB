# Downloads https://pokemondb.net/pokedex/all and generates scripts/mapping.txt
# Each line i corresponds to i.png (0-based).

$uri = 'https://pokemondb.net/pokedex/all'
$outFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) 'mapping.txt'

Write-Host "Fetching $uri ..."
try {
    $resp = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error ("Failed to download {0}: {1}" -f $uri, $_.Exception.Message)
    exit 1
}

$html = $resp.Content

# Grab table rows' name cells. The page uses <td class="cell-name"> ... </td>
$pat = '(?s)<td[^>]*class="cell-name"[^>]*>(.*?)</td>'
$matches = [regex]::Matches($html, $pat)

$names = @()
foreach ($m in $matches) {
    $cell = $m.Groups[1].Value
    # extract the first anchor text inside the cell
    $aPat = '<a[^>]*href="/pokedex/[^\"]+"[^>]*>([^<]+)</a>'
    $a = [regex]::Match($cell, $aPat)
    if ($a.Success) {
        $name = $a.Groups[1].Value.Trim()
        $names += $name
    }
}

if ($names.Count -eq 0) {
    Write-Error "No names extracted. The page structure may have changed."
    exit 1
}

# Convert names to slugs that resemble filenames used in your sprites folder.
function To-Slug($s) {
    $s = $s.ToLower()
    # normalize parentheses and punctuation to spaces (do replacements stepwise to avoid quoting issues)
    $s = $s -replace '\(', ' '
    $s = $s -replace '\)', ' '
    $s = $s -replace '\[', ' '
    $s = $s -replace '\]', ' '
    $s = $s -replace '"', ' '
    $s = $s -replace ':', ' '
    $s = $s -replace ',', ' '
    $s = $s -replace "'", ' '
    # replace whitespace with hyphens
    $s = $s -replace '\s+', '-'
    # remove periods
    $s = $s -replace '\.', ''
    # remove characters that are not alphanumeric or hyphen
    $s = $s -replace '[^a-z0-9-]', ''
    # collapse multiple hyphens and trim
    $s = $s -replace '-+', '-'
    $s = $s.Trim('-')
    return $s + '.png'
}

$slugs = $names | ForEach-Object { To-Slug $_ }

# Write to mapping.txt (0-based mapping: line 0 -> 0.png)
Set-Content -Path $outFile -Value ("# Generated mapping from $uri`n# Line 0 -> 0.png (0-based)" ) -Encoding UTF8
Add-Content -Path $outFile -Value ($slugs -join "`n")

Write-Host "Wrote $($slugs.Count) entries to $outFile"
