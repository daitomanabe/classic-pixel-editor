# Classic Pixel Editor

Classic Pixel Editor is a clean-room, public macOS raster editor written in Swift with AppKit and CoreGraphics. It aims for a compact native image-editing workflow: create documents, open common raster formats through platform APIs, draw pixels, select regions, apply basic operations, undo destructive edits, and export PNG or TIFF.

This project is original work. It is not affiliated with, endorsed by, or compatible with Adobe products.

## MVP Status

- Swift Package Manager project with a reusable `ClassicPixelCore` library and an AppKit executable.
- New document dialog with dimensions, color mode, and background choice.
- Multi-window editor shell, canvas viewport, checkerboard background, zoom, status readout, and basic toolbar.
- PNG/JPEG/TIFF/BMP loading through ImageIO where supported by the platform.
- PNG/TIFF export.
- Pencil, brush, eraser, paint bucket, eyedropper, rectangle/ellipse/lasso selection, and magic-wand-style contiguous selection.
- Invert, threshold, brightness, levels API, resize/crop/rotate/flip transforms, blur, sharpen, edge detect, and median filter.
- Full-buffer undo/redo for destructive operations.
- Clipboard copy/paste using platform pasteboard image support.

## Build

```bash
swift build
```

## Test

```bash
swift test
scripts/cleanroom_guard.sh .
```

`ClassicPixelCoreTestRunner` remains available as a fallback smoke runner for minimal toolchains, but CI uses the XCTest target.

## Run

```bash
swift run ClassicPixelEditor
```

SwiftPM launches this as a native AppKit executable.

## Package App

```bash
scripts/package_app.sh
open "dist/Classic Pixel Editor.app"
```

The packaging script creates a local app bundle with original metadata and document type declarations for common raster images. The generated `dist/` directory is ignored by git.

## Clean-Room Notice

Contributors must follow [CLEANROOM.md](CLEANROOM.md). Do not inspect original proprietary source releases, source mirrors, forks, decompiled binaries, or source-code commentary for any historical raster editor. Implement behavior only from this specification, generic Swift/AppKit knowledge, platform API documentation, and independent image-processing references.
