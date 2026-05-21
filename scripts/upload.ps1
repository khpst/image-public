<#
.SYNOPSIS
    Upload an image to the image-public CDN repository.

.PARAMETER ImagePath
    Full or relative path to the image file.

.PARAMETER Project
    Top-level project folder name (e.g. "portfolio", "blog").

.PARAMETER Subfolder
    Optional subfolder within the project (e.g. "post-1", "thumbnails").

.PARAMETER Force
    Overwrite the file if it already exists at the destination.

.EXAMPLE
    .\scripts\upload.ps1 -ImagePath "C:\pics\hero.jpg" -Project "portfolio"

.EXAMPLE
    .\scripts\upload.ps1 -ImagePath "cover.webp" -Project "blog" -Subfolder "post-1"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,

    [Parameter(Mandatory = $true)]
    [string]$Project,

    [Parameter(Mandatory = $false)]
    [string]$Subfolder = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REPO_ROOT    = Split-Path -Parent $PSScriptRoot
$REPO_OWNER   = "khpst"
$REPO_NAME    = "image-public"
$BRANCH       = "main"
$BASE_CDN_URL = "https://cdn.jsdelivr.net/gh/$REPO_OWNER/$REPO_NAME"

$SUPPORTED_EXTENSIONS = @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".avif", ".ico")

# Validate image file
$ResolvedImage = Resolve-Path -Path $ImagePath -ErrorAction SilentlyContinue
if (-not $ResolvedImage) {
    Write-Error "Image file not found: $ImagePath"
    exit 1
}
$ImageFile = Get-Item $ResolvedImage.Path

$ext = $ImageFile.Extension.ToLower()
if ($ext -notin $SUPPORTED_EXTENSIONS) {
    Write-Error "Unsupported file type '$ext'. Supported: $($SUPPORTED_EXTENSIONS -join ', ')"
    exit 1
}

# Validate project name
if ($Project -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Error "Project name must contain only letters, numbers, hyphens, and underscores."
    exit 1
}

if ($Subfolder -ne "" -and $Subfolder -notmatch '^[a-zA-Z0-9_/-]+$') {
    Write-Error "Subfolder must contain only letters, numbers, hyphens, underscores, and forward slashes."
    exit 1
}

# Build destination path
$DestRelativeParts = @($Project)
if ($Subfolder -ne "") {
    $subParts = $Subfolder.TrimEnd("/").TrimStart("/") -split "/"
    $DestRelativeParts += $subParts
}
$DestRelativeParts += $ImageFile.Name

$RelativePath = $DestRelativeParts -join "/"
$DestPath     = Join-Path $REPO_ROOT ($DestRelativeParts -join "\")
$DestDir      = Split-Path $DestPath -Parent

# Copy file
if (Test-Path $DestPath) {
    if (-not $Force) {
        Write-Error "Destination already exists: $RelativePath`nUse -Force to overwrite."
        exit 1
    }
    Write-Host "Overwriting existing file at $RelativePath" -ForegroundColor Yellow
}

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    Write-Host "Created directory: $DestDir" -ForegroundColor Cyan
}

Copy-Item -Path $ImageFile.FullName -Destination $DestPath -Force
Write-Host "Copied to: $DestPath" -ForegroundColor Green

# Git operations
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

# Output CDN URLs
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
