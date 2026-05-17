# Task: Classic Pixel Editor を ROADMAP に沿って前進させる

## Overview

Classic Pixel Editor は Swift + AppKit + CoreGraphics で書かれた **clean-room な macOS raster image editor** です。
Adobe Photoshop 1.0.1 の source は **絶対に参照しない**。実装は SPEC.md と generic な画像処理・Swift/AppKit 公開ドキュメントからのみ行います。

このRalph loopの目的は、1 cycleにつき ROADMAP.md の中から **1つの小さなタスク** を選び、
実装 → swift test → cleanroom_guard → review の流れで安全に完了させることです。

## プロジェクト構造

```
Sources/
  ClassicPixelCore/          # Pure logic (PixelBuffer, ImageOperation, SelectionMask, EditCommand)
  ClassicPixelEditorApp/     # AppKit executable (canvas, tools, windows)
  ClassicPixelCoreTestRunner # Minimal fallback smoke runner
Tests/
  ClassicPixelCoreTests/     # XCTest target (primary CI path)
scripts/
  cleanroom_guard.sh         # Required guard before PR
  package_app.sh             # Local .app bundle packager
SPEC.md / ROADMAP.md / CLEANROOM.md / README.md
```

## ROADMAP（主要マイルストーン）

- **M0**: App Shell（完了済み）
- **M1**: UI/UX Hardening — canvas event split、stroke grouping、shortcuts、cursor previews、selection outlines、status details
- **M2**: XCTest Coverage And Smoke Tests — pixel math・selections・transforms・adjustments・filters・round trips の決定論的テスト
- **M3**: Document-Based Packaging — document-based app architecture、icon、signing/notarization
- **M4**: More Tools And Filters — Gaussian blur、unsharp mask、hue/saturation、levels UI、brush opacity 等
- **M5**: Releases — tagged releases、CI artifacts、自前screenshot

## CLEAN-ROOM ルール（絶対遵守）

- `agdm/photoshop-1.0.1`、CHM source ZIP、source mirrors、forks、decompiled binaries、source commentary を **読まない・参照しない**
- Adobe/Photoshop 名、icons、splash screens、artwork、manual prose、UI drawings、trade dress を **コピーしない**
- 実装はこの SPEC、generic Swift/AppKit/CoreGraphics ドキュメント、独立した画像処理リファレンスからのみ
- Swift identifier・コメントに `Photoshop` / `Adobe` を書かない（README/SPEC/CLEANROOM 内の文脈説明はOK）

## CRITICAL: 毎iteration必須事項

### 作業開始時
1. `.ralph/agent/scratchpad.md` を読んで現在の状況を把握
2. `.ralph/agent/iteration.log` を読んで直近の進捗を確認

### 作業完了後（イベント発行前）
1. `.ralph/agent/iteration.log` に記録を追記
   ```
   [{ISO8601}] iteration #{n} | {Hat名} | {受け取ったイベント} | {状態} | {具体的な変更内容}
   ```
2. `.ralph/agent/scratchpad.md` を更新（タスクID・受け入れ基準・現在のフェーズを明記）
3. Git commit & push
   ```bash
   git add -A
   git commit -m "[Ralph] {Hat名}: {完了内容}"
   git push
   ```

### エラー発生時
1. `.ralph/agent/errors.log` にエラー詳細を記録
2. 修正可能なら修正して続行、5 iteration以上同じエラーで詰まったらLOOP_COMPLETEを検討

## Backpressure（品質ゲート）

`build.done` を発行する**前に**:
- `swift build` がエラーなく通る
- `swift test` が全件PASSする（新機能には対応テスト必須）

`guard.passed` を発行する**前に**:
- `scripts/cleanroom_guard.sh .` がexit 0で通る
- 変更コード内に `Photoshop` / `Adobe` identifier がない

通らない場合は対応する done イベントを発行せず修正を続ける。

## LOOP_COMPLETE時の追加処理

LOOP_COMPLETE を発行する前に:
1. `COMPLETION_REPORT.md` を生成
2. 最終 `git push`

## Event Flow

```
work.start
   │
   ▼
git_setup ──(失敗)─→ LOOP_COMPLETE
   │ git.ready
   ▼
planner ── plan.ready ──▶ builder ◀──┐
                           │         │ review.changes_requested
                           ▼ build.done
                          guard ─────┘
                           │ guard.passed
                           ▼
                         reviewer
                           │
                           ├── review.changes_requested ──▶ builder
                           └── LOOP_COMPLETE
```

## Hat Roles

| Hat | 役割 |
|------|------|
| **Git Setup** | 認証・ブランチ・swift toolchain確認、baseline `swift build` |
| **Planner** | ROADMAPから単一タスクを選び、`.ralph/specs/task-{n}-{slug}.md` を生成 |
| **Builder** | Swift実装、`swift build` + `swift test` 両方PASSで `build.done` |
| **Cleanroom Guard** | `cleanroom_guard.sh` 実行、identifier違反チェック |
| **Reviewer** | 受け入れ基準・コード品質・テストカバレッジを最終確認 |

## Success Criteria

- [ ] 1 cycleで ROADMAP の Milestone 1〜M5 から1項目（または1サブ項目）を完了させる
- [ ] `swift build` / `swift test` / `scripts/cleanroom_guard.sh` 全てPASS
- [ ] 新機能には対応するXCTestがある
- [ ] CLEAN-ROOM 違反なし（identifier・comment・コピペコード）
- [ ] 全変更が remote にpush済み
- [ ] `.ralph/agent/iteration.log` が最新
- [ ] `COMPLETION_REPORT.md` を生成
- [ ] LOOP_COMPLETE
