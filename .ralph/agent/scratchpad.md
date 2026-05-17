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

## Iteration 2 — Planner (2026-05-17)

### Selected task
**task-01-stroke-undo-grouping** — M1 UI/UX hardening の中で ROADMAP と PROMPT が明示する最優先項目。
Spec: `.ralph/specs/task-01-stroke-undo-grouping.md`

### Why this task
- 現状の `CanvasView.mouseDragged` → `EditorWindowController.draw(at:y:)` → `DocumentModel.apply(name:...)` は **drag sample 1 つにつき 1 つの `ImageEditCommand`** を push する（`Sources/ClassicPixelCore/DocumentModel.swift:27-32`, `Sources/ClassicPixelCore/EditCommand.swift:24-28` で確認）
- ユーザーが 1 ストロークを 1 回の Undo で取り消せない、典型的な UX バグ
- 影響範囲が狭く（Core に小さな API を足し、CanvasView の 3 メソッドを切り替えるだけ）アトミックに収まる
- 新規 XCTest 追加により M2 のテストカバレッジ目標にも自然に寄与する

### Target files
- `Sources/ClassicPixelCore/DocumentModel.swift` — `beginStroke` / `extendStroke` / `endStroke` を追加
- `Sources/ClassicPixelEditorApp/main.swift` — `CanvasView.mouseDown/Dragged/Up` で `.continuousDrawing` 時にセッションを使う
- `Tests/ClassicPixelCoreTests/CoreTests.swift` — 多段ストローク → 単一 undo の XCTest を追加

### Acceptance (Builder 側で満たす)
- [ ] `swift build` クリーン
- [ ] `swift test` 全件 PASS、新規テスト 2 件以上
- [ ] 多サンプルのストロークが 1 回の `undo()` で初期状態に戻る
- [ ] `before == after` のストロークは history に積まれない
- [ ] `scripts/cleanroom_guard.sh .` exit 0
- [ ] 既存メニュー操作（Invert / Blur / Rotate / Paint Bucket / Selections / Copy/Paste / Undo/Redo）が回帰なし

### Out of scope（今回はやらない）
- stroke interpolation（連続点の線分補間）— M4
- keyboard shortcuts、marching ants、cursor preview — 別 task
- paintBucket など `.continuousDrawing` 以外のグルーピング

### Next hat
Builder — spec に沿って実装し、`swift build` + `swift test` が両方通ったら `build.done` を emit。
