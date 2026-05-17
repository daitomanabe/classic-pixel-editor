# Ralph Scratchpad — Classic Pixel Editor

## Iteration 1 — Git Setup (2026-05-17)

### Environment
- **Branch:** `claude/clever-sammet-0e00df` (tracked to `origin/claude/clever-sammet-0e00df`)
- **Remote:** `https://github.com/daitomanabe/classic-pixel-editor.git`
- **GitHub auth:** OK (`daitomanabe`, scopes: gist/read:org/repo/workflow)
- **Swift toolchain:** 6.2.4 (swiftlang-6.2.4.1.4), target `arm64-apple-macosx26.0`
- **Ralph:** 2.8.1 at `/Users/daitomacm5/.cargo/bin/ralph`

### Baseline build
- `swift build` → **Build complete!** (17.19s on second run)
- Note: emits a non-fatal "build.db disk I/O error" warning from sqlite, but build artifacts link cleanly (ClassicPixelEditor, ClassicPixelCoreTestRunner). Likely transient lock contention on `.build/build.db`; safe to proceed. If it recurs and starts blocking, try `rm -f .build/build.db*` or fresh `.build/`.

### Project state
- Existing structure matches PROMPT.md:
  - `Sources/ClassicPixelCore/` (PixelBuffer, ImageOperations, SelectionMask, EditCommand, DocumentModel, Color, ImageIOBridge, ToolController)
  - `Sources/ClassicPixelEditorApp/` (AppKit executable)
  - `Sources/ClassicPixelCoreTestRunner/` (fallback smoke runner)
  - `Tests/ClassicPixelCoreTests/` (XCTest target)
  - `scripts/cleanroom_guard.sh`, `scripts/package_app.sh`
- Docs present: README, SPEC, ROADMAP, CLEANROOM, PROMPT
- `.ralph/specs/` exists but is empty → Planner needs to create the first task spec
- Recent commits show M0/M1 progress already: lasso, desaturate/emboss, local app bundle packaging, canvas tool hardening

### ROADMAP positioning
- M0 (App Shell) **done**
- M1 (UI/UX Hardening) **in progress** — recent commits land canvas hardening, lasso selection
- M2/M3/M4/M5 mostly open

### Next hat (Planner)
- Pick ONE atomic task from ROADMAP M1 (or earliest sub-item in M2/M3/M4 that is unblocked)
- Write spec to `.ralph/specs/task-{n}-{slug}.md`
- Suggested candidates (Planner to decide):
  - M1: stroke grouping as single undo command (PROMPT references this explicitly)
  - M1: keyboard shortcuts for tool selection
  - M1: cursor preview for brush/pencil size
  - M1: selection outlines (marching ants) for current selection
  - M2: deterministic XCTest for one image op that lacks coverage

### Clean-room reminders
- Never read `agdm/photoshop-1.0.1`, CHM source ZIPs, decompiled binaries
- No `Photoshop`/`Adobe` identifiers in Swift code or comments (docs explaining non-affiliation are OK)
