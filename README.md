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

```powershell
# Basic
.\scripts\upload.ps1 -ImagePath "C:\images\hero.jpg" -Project "portfolio"

# With subfolder
.\scripts\upload.ps1 -ImagePath "C:\images\cover.jpg" -Project "blog" -Subfolder "post-1"
```

The script prints jsDelivr URLs after a successful push.

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
