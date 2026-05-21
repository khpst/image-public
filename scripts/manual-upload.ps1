<#
.SYNOPSIS
    Commit and push an image already placed in the repo, then print its jsDelivr URLs.

.PARAMETER RelativePath
    Path to the image relative to the repo root (e.g. "portfolio/hero.jpg").

.EXAMPLE
    .\scripts\manual-upload.ps1 -RelativePath "portfolio/hero.jpg"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REPO_ROOT    = Split-Path -Parent $PSScriptRoot
$REPO_OWNER   = "khpst"
$REPO_NAME    = "image-public"
$BRANCH       = "main"
$BASE_CDN_URL = "https://cdn.jsdelivr.net/gh/$REPO_OWNER/$REPO_NAME"

$SUPPORTED_EXTENSIONS = @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".avif", ".ico")

# Normalise to forward slashes
$RelativePath = $RelativePath.Replace("\", "/").Trim("/")

$FullPath = Join-Path $REPO_ROOT ($RelativePath.Replace("/", "\"))

if (-not (Test-Path $FullPath)) {
    Write-Error "File not found in repo: $RelativePath"
    exit 1
}

$ext = [System.IO.Path]::GetExtension($RelativePath).ToLower()
if ($ext -notin $SUPPORTED_EXTENSIONS) {
    Write-Error "Unsupported file type '$ext'. Supported: $($SUPPORTED_EXTENSIONS -join ', ')"
    exit 1
}

Push-Location $REPO_ROOT
try {
    git add $RelativePath
    if ($LASTEXITCODE -ne 0) { Write-Error "git add failed"; exit 1 }

    git commit -m "upload: $RelativePath"
    if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed"; exit 1 }

    git push origin $BRANCH
    if ($LASTEXITCODE -ne 0) { Write-Error "git push failed"; exit 1 }

    $CommitHash = (git rev-parse HEAD).Trim()
}
finally {
    Pop-Location
}

$UrlMain   = "$BASE_CDN_URL@$BRANCH/$RelativePath"
$UrlCommit = "$BASE_CDN_URL@$CommitHash/$RelativePath"

Write-Host ""
Write-Host "=== Upload complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "  File        : $RelativePath"
Write-Host "  Commit      : $CommitHash"
Write-Host ""
Write-Host "  CDN URL (@main):" -ForegroundColor Cyan
Write-Host "  $UrlMain"
Write-Host ""
Write-Host "  CDN URL (@commit) [cache-stable]:" -ForegroundColor Cyan
Write-Host "  $UrlCommit"
Write-Host ""
