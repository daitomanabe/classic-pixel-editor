# Clean-Room Rules

Classic Pixel Editor is a clean-room implementation. The legal and engineering priority is original implementation, not historical exactness.

## Allowed Sources

- This repository's `SPEC.md`.
- Generic Swift, AppKit, CoreGraphics, ImageIO, and Swift Package Manager documentation.
- General image-processing references that are not derived from proprietary source releases.
- Public user-facing materials for broad feature awareness only, such as product screenshots, reviews, or historical summaries.

## Prohibited Sources

- Original source releases, source mirrors, forks, or local copies of proprietary historical image-editor source code.
- Decompiled binaries, reverse-engineered implementation notes, or source-code commentary.
- Vendor icons, splash screens, artwork, screenshots as UI assets, manuals copied as prose, or exact visual trade dress.
- Claims of compatibility with Adobe products or use of Adobe product names as project or app branding.

## Contributor Declaration

Every contributor must be able to state:

- I did not inspect Photoshop 1.0.1 source code or source mirrors.
- I did not copy Adobe assets, manual prose, UI artwork, or icons.
- I implemented behavior from this clean-room spec or general image-processing references.
- I added tests for new image operations where practical.

## Guard

Run the clean-room guard before opening a pull request:

```bash
scripts/cleanroom_guard.sh .
```

The guard is intentionally conservative about source and asset paths. It does not replace human review.
