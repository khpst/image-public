<#
.SYNOPSIS
    Scan the repo for deleted images, commit removals, push, and report which CDN URLs are now gone.
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
    $statusLines = git status --porcelain -uall
    if ($LASTEXITCODE -ne 0) { Write-Error "git status failed"; exit 1 }

    $deletedPaths = @($statusLines | ForEach-Object {
        $line = $_.Trim()
        # " D path" = deleted in working tree (not yet staged)
        if ($line -match '^\s*D\s+(.+)$') {
            $path = $Matches[1].Replace('"', '').Replace("\", "/")
            $ext  = [System.IO.Path]::GetExtension($path).ToLower()
            if ($ext -in $SUPPORTED_EXTENSIONS) { $path }
        }
    } | Where-Object { $_ })

    if (-not $deletedPaths) {
        Write-Host "No deleted images found." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Found $($deletedPaths.Count) deleted image(s):" -ForegroundColor Cyan
    $deletedPaths | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    foreach ($path in $deletedPaths) {
        git rm --cached $path 2>$null
        # If not in index, just stage the deletion via add
        if ($LASTEXITCODE -ne 0) {
            git add $path
        }
        if ($LASTEXITCODE -ne 0) { Write-Error "Failed to stage deletion: $path"; exit 1 }
    }

    $commitMsg = if ($deletedPaths.Count -eq 1) { "delete: $($deletedPaths[0])" } else { "delete: $($deletedPaths.Count) images" }

    git commit -m $commitMsg
    if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed"; exit 1 }

    git pull origin $BRANCH --rebase --quiet
    if ($LASTEXITCODE -ne 0) { Write-Error "git pull --rebase failed"; exit 1 }

    git push origin $BRANCH
    if ($LASTEXITCODE -ne 0) { Write-Error "git push failed"; exit 1 }

    $CommitHash = (git rev-parse HEAD).Trim()
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== Delete complete ===" -ForegroundColor Red
Write-Host "  Commit: $CommitHash"
Write-Host ""
Write-Host "  The following CDN URLs are no longer valid:" -ForegroundColor Yellow
foreach ($path in $deletedPaths) {
    Write-Host "  $BASE_CDN_URL@$BRANCH/$path"
}
Write-Host ""
