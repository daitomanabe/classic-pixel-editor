# Public Clean-Room Handoff Spec: Classic Pixel Editor

## Summary

Goal: build a public, open-source macOS native image editor inspired by early raster image editors, without using or referencing Photoshop 1.0.1 source code.

Working product name: `Classic Pixel Editor`.

The implementation agent must receive only this spec, not the previous conversation, not source-code-derived notes, and not any local/vendor copy of Photoshop 1.0.1. The agent may use public user-facing materials such as manuals, screenshots, reviews, and general image-processing references, but must not inspect original source code, forks, decompiled binaries, or source-code commentary.

Reference context allowed for product-level scope:
- CHM historical page: https://computerhistory.org/blog/adobe-photoshop-source-code/?key=adobe-photoshop-source-code
- CHM license context: https://computerhistory.org/blogs/photoshop-software-license-agreement/
- Public screenshots/features summary: https://gigazine.net/gsc_news/en/20130215-photoshop-source-code/

## Clean-Room Rules

- Do not read `agdm/photoshop-1.0.1`, CHM source ZIP, source mirrors, source excerpts, or implementation analyses.
- Do not copy Adobe/Photoshop names, icons, splash screens, artwork, manual prose, UI drawings, or exact visual trade dress.
- Do not claim compatibility with Photoshop or Adobe products.
- Use a neutral repo/app name such as `classic-pixel-editor`.
- Public repo may include original Swift code, tests, screenshots of this app, and clean-room specs.
- Public repo must include `CLEANROOM.md` documenting allowed/prohibited sources and a contributor declaration.

## Product Scope

Build a native macOS raster editor with an early-1990s desktop-publishing feel, but original UI.

MVP capabilities:

- New document with width, height, color mode, and background.
- Open common raster images through platform APIs: PNG, JPEG, TIFF, BMP if available.
- Save/export PNG and TIFF.
- Single-document and multi-document window support.
- Canvas viewport with zoom, pan, rulers optional, checkerboard transparency optional.
- Basic pixel model with grayscale, indexed-color-like palette mode, RGB, and alpha support.
- Selection tools: rectangular selection, elliptical selection, freehand/lasso-style selection, magic-wand-style contiguous color selection.
- Editing tools: pencil, brush, eraser, paint bucket, eyedropper, clone/stamp optional, text insertion optional.
- Image operations: crop, resize, rotate 90/180, flip horizontal/vertical.
- Adjustments: invert, threshold, brightness/contrast, levels-style tonal remap, hue/saturation optional.
- Filters: blur, sharpen, edge detect, median/noise optional.
- Undo/redo for every destructive operation.
- Clipboard copy/paste for selected pixels.
- Status readout: cursor position, zoom, document size, color under cursor.

Out of scope for MVP:

- Layers.
- Photoshop file compatibility.
- Plug-in compatibility.
- Scanner/acquire workflows.
- Printing workflows.
- Exact historical UI reproduction.
- Any source-derived algorithmic fidelity.

## Implementation Guidance

Use Swift and native macOS APIs.

- UI: AppKit document-based app. SwiftUI may be used for inspector panels or dialogs if useful.
- Rendering: start with CoreGraphics/CGImage. Add Metal later only if performance requires it.
- Core data model:
  - `DocumentModel`: image dimensions, color mode, channels, selection, metadata.
  - `PixelBuffer`: owned pixel storage with safe row access.
  - `SelectionMask`: boolean or 8-bit alpha mask.
  - `EditCommand`: undoable operation with apply/unapply.
  - `ToolController`: maps mouse/keyboard gestures into commands.
  - `ImageOperation`: pure functions for adjustments, transforms, and filters.
- File I/O should use ImageIO for public formats.
- Image algorithms should come from general image-processing knowledge or independent references, not from Photoshop source.

## GitHub Plan

Create a public repo with:

- `README.md`: project purpose, clean-room notice, non-affiliation with Adobe.
- `CLEANROOM.md`: allowed/prohibited sources, contributor rules.
- `SPEC.md`: this product specification.
- `docs/feature-research.md`: links to public user-facing materials only.
- `.github/ISSUE_TEMPLATE/feature.yml`: feature tasks with clean-room source checklist.
- `.github/pull_request_template.md`: checkbox confirming no prohibited source was used.
- `LICENSE`: choose permissive license such as MIT or Apache-2.0 for original code only.
- CI: macOS Swift build and unit tests.

PR checklist must include:

- I did not inspect Photoshop 1.0.1 source code or source mirrors.
- I did not copy Adobe assets, manual prose, UI artwork, or icons.
- I implemented behavior from this clean-room spec or general image-processing references.
- I added tests for new image operations where practical.

## Test Plan

- Unit tests for pixel buffer bounds, color conversion, selections, flood fill, transforms, adjustments, and filters.
- Snapshot-style tests for deterministic operations using generated sample images.
- UI smoke tests: launch app, create document, draw, select, apply adjustment, undo, save, reopen.
- Clean-room guard: repository scan for prohibited filenames, source URLs, Adobe assets, and copied license text beyond short attribution links.
- Release guard: verify app name, bundle identifier, icon, and README do not imply Adobe affiliation.

## Assumptions

- The public implementation prioritizes legal cleanliness over historical exactness.
- The implementer starts from this document only.
- Historical manuals and screenshots may be used to identify broad user-facing features, but not copied verbatim.
- The first public release is an original “classic raster editor,” not a Photoshop clone.
