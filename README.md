# image-public

Shared image CDN using GitHub + jsDelivr. Images are version-controlled and served globally via jsDelivr's CDN.

## CDN URL Format

```
https://cdn.jsdelivr.net/gh/khpst/image-public@main/{project}/{filename}
```

For cache-stable links (recommended for production), use the commit hash:

```
https://cdn.jsdelivr.net/gh/khpst/image-public@{commit-hash}/{project}/{filename}
```

## Folder Structure

```
{project}/
└── {optional-subfolder}/
    └── image.ext
```

Each project owns its own top-level folder.

## Uploading an Image

### Option A — Script (automatic)

```powershell
# Basic
.\scripts\upload.ps1 -ImagePath "C:\images\hero.jpg" -Project "portfolio"

# With subfolder
.\scripts\upload.ps1 -ImagePath "C:\images\cover.jpg" -Project "blog" -Subfolder "post-1"
```

The script copies the file, commits, pushes, and prints the jsDelivr URLs automatically.

### Option B — Manual

1. Copy the image into the repo at the desired path, e.g. `portfolio/hero.jpg`
2. Run:

```powershell
git add portfolio/hero.jpg
git commit -m "upload: portfolio/hero.jpg"
git push origin main
```

3. Get the commit hash for a cache-stable URL:

```powershell
git rev-parse HEAD
```

4. Build the URL:

```
# @main
https://cdn.jsdelivr.net/gh/khpst/image-public@main/portfolio/hero.jpg

# @commit (cache-stable)
https://cdn.jsdelivr.net/gh/khpst/image-public@<commit-hash>/portfolio/hero.jpg
```

## Supported Formats

`jpg` `jpeg` `png` `gif` `webp` `svg` `avif` `ico`

## Image Manifest

`manifest.json` is auto-generated at the repo root by GitHub Actions on every push.

```json
{
  "generated_at": "2026-05-21T12:00:00Z",
  "base_url": "https://cdn.jsdelivr.net/gh/khpst/image-public@main",
  "image_count": 1,
  "images": [
    {
      "project": "test",
      "path": "test/drawing.png",
      "url": "https://cdn.jsdelivr.net/gh/khpst/image-public@main/test/drawing.png"
    }
  ]
}
```
