# Scratchpad — Classic Pixel Editor / Ralph loop

## プロジェクト状態（初期）

- リポジトリ: photoshop-challenge (clean-room raster editor)
- ブランチ: claude/clever-sammet-0e00df (git worktree)
- Swift Package Manager: `ClassicPixelCore` + `ClassicPixelEditorApp` + `ClassicPixelCoreTestRunner`
- XCTest target: `Tests/ClassicPixelCoreTests`

## 直近の完了タスク（git log より）

- Add desaturate and emboss operations (c2e5638)
- Add lasso selection tool (aa66e5a)
- Add local app bundle packaging (9305be1)
- Harden canvas tool interactions (c8c0dbe)
- Migrate core checks to XCTest (edd6c5b)

## 現在の cycle

- Cycle status: **未着手**
- Current task: なし（次のPlannerが選定）
- Phase: -

## 次に選ぶべき候補（参考）

ROADMAP 上で未完了かつ価値の高そうな項目:

- M1: stroke grouping を 1 undoable command として扱う
- M1: keyboard shortcuts、cursor previews、selection outlines の整備
- M2: pixel math・selections・transforms・adjustments・filters の決定論テスト追加
- M2: file round-trip テスト（PNG/TIFF）
- M4: Gaussian blur、unsharp mask、hue/saturation、levels UI、brush opacity

## 受け入れ基準（現タスク）

未設定

## ビルド状態

- swift build: 未測定（Git Setupで確認）
- swift test: 未測定
- cleanroom_guard.sh: 未測定

## レビュー指摘事項

なし

## メモ

- CLEAN-ROOM 厳守: `agdm/photoshop-1.0.1`・CHM source・decompiled binaries を絶対参照しない
- Swift identifier・comment に "Photoshop" / "Adobe" を書かない
- AppKit部分は `Sources/ClassicPixelEditorApp/`、pure logicは `Sources/ClassicPixelCore/` に分離
