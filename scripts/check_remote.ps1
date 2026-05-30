$raw='https://raw.githubusercontent.com/Thuete1/ShinySpritesRnB/main/ShinySprites/ActualSprites/abomasnow.png'
Write-Host "RAW_URL: $raw"
try {
    $r = Invoke-WebRequest -Uri $raw -Method Head -UseBasicParsing -TimeoutSec 15
    Write-Host "RAW_STATUS: $($r.StatusCode)"
} catch {
    if ($_.Exception.Response) {
        Write-Host "RAW_STATUS: $($_.Exception.Response.StatusCode.Value__)"
    } else {
        Write-Host "RAW_ERROR: $($_.Exception.Message)"
    }
}

Write-Host "--- GitHub API ---"
try {
    $api = Invoke-RestMethod -Uri 'https://api.github.com/repos/Thuete1/ShinySpritesRnB' -Headers @{ 'User-Agent' = 'curl/7.0' } -ErrorAction Stop
    Write-Host "REPO_PRIVATE: $($api.private)"
    Write-Host "DEFAULT_BRANCH: $($api.default_branch)"
} catch {
    Write-Host "API_ERROR: $($_.Exception.Message)"
}

Write-Host '--- git ls-remote ---'
try {
    git -C "$PSScriptRoot\.." ls-remote origin refs/heads/main
} catch {
    Write-Host 'GIT_ERROR: git ls-remote failed or not available'
}
