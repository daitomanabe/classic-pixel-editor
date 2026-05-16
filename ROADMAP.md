# Roadmap

Classic Pixel Editor is a clean-room macOS raster editor. This roadmap keeps the public work focused on practical product maturity rather than historical exactness.

## Milestone 0: App Shell Done

- Swift Package Manager scaffold with `ClassicPixelCore`, an AppKit executable, and a core test runner.
- Original clean-room docs, guard script, issue template, PR template, and GitHub CI.
- Basic pixel model, selections, drawing tools, destructive image operations, undo/redo, ImageIO import/export, and multi-window shell.

## Milestone 1: UI/UX Hardening

- Improve canvas drag behavior so drawing strokes are grouped as one undoable command.
- Add clearer active-tool feedback, keyboard shortcuts, cursor previews, and selection outlines.
- Add practical document status details: modified marker, file path, color mode, and current tool.
- Add lightweight smoke checks for launch, new document, simple edit, save, and reopen.

## Milestone 2: Real XCTest Migration

- Migrate the executable test runner into standard SwiftPM test targets once the supported local and CI toolchains expose the test framework reliably.
- Keep deterministic generated-image tests for pixel math, selections, transforms, adjustments, filters, and file round trips.
- Add release-guard checks for app identity, bundle identifier, and clean-room docs.

## Milestone 3: Document-Based Packaging

- Move from a SwiftPM-launched AppKit executable to a proper document-based macOS app bundle.
- Add bundle metadata, original app icon, signing/notarization notes, and export packaging.
- Preserve SwiftPM core builds for CI and library reuse.

## Milestone 4: More Tools And Filters

- Add stroke interpolation, brush shapes, brush opacity, eraser opacity, and better paint bucket tolerance controls.
- Add freehand lasso completion, selection move/copy behavior, crop UI, and resize dialogs.
- Expand filters and adjustments with tested, generic algorithms: Gaussian blur, unsharp mask, hue/saturation, noise, and histogram-based levels UI.

## Milestone 5: Releases

- Publish tagged source releases with CI artifacts.
- Add screenshots generated from this app only.
- Keep release notes clear about clean-room scope, supported formats, limitations, and non-affiliation.
