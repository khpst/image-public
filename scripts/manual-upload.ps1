<#
.SYNOPSIS
    Scan the repo for new/modified images, commit them all, push, and print jsDelivr URLs.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REPO_ROOT    = Split-Path -Parent $PSScriptRoot
$REPO_OWNER   = "khpst"
$REPO_NAME    = "image-public"
$BRANCH       = "main"
$BASE_CDN_URL = "https://cdn.jsdelivr.net/gh/$REPO_OWNER/$REPO_NAME"

$SUPPORTED_EXTENSIONS = @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".avif", ".ico")

Push-Location $REPO_ROOT
try {
    # Find all new/modified files via git status
    $statusLines = git status --porcelain
    if ($LASTEXITCODE -ne 0) { Write-Error "git status failed"; exit 1 }

    $imagePaths = $statusLines | ForEach-Object {
        $line = $_.Trim()
        # Format: "XY path" — extract path after status chars
        $path = ($line -replace '^.{2}\s+', '').Replace('"', '').Replace("\", "/")
        $ext  = [System.IO.Path]::GetExtension($path).ToLower()
        if ($ext -in $SUPPORTED_EXTENSIONS) { $path }
    } | Where-Object { $_ }

    if (-not $imagePaths) {
        Write-Host "No new or modified images found." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Found $($imagePaths.Count) image(s):" -ForegroundColor Cyan
    $imagePaths | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    foreach ($path in $imagePaths) {
        git add $path
        if ($LASTEXITCODE -ne 0) { Write-Error "git add failed for: $path"; exit 1 }
    }

    $fileList = $imagePaths -join ", "
    $commitMsg = if ($imagePaths.Count -eq 1) { "upload: $($imagePaths[0])" } else { "upload: $($imagePaths.Count) images" }

    git commit -m $commitMsg
    if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed"; exit 1 }

    git push origin $BRANCH
    if ($LASTEXITCODE -ne 0) { Write-Error "git push failed"; exit 1 }

    $CommitHash = (git rev-parse HEAD).Trim()
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== Upload complete ===" -ForegroundColor Green
Write-Host "  Commit: $CommitHash"
Write-Host ""

foreach ($path in $imagePaths) {
    Write-Host "  $path" -ForegroundColor White
    Write-Host "  @main   : $BASE_CDN_URL@$BRANCH/$path" -ForegroundColor Cyan
    Write-Host "  @commit : $BASE_CDN_URL@$CommitHash/$path" -ForegroundColor DarkCyan
    Write-Host ""
}
