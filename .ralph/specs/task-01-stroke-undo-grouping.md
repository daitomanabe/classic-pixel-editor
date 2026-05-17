# task-01 — Group continuous-drawing strokes into a single undo command

**Milestone:** M1 (UI/UX Hardening)
**ROADMAP item:** *"Improve canvas drag behavior so drawing strokes are grouped as one undoable command."*
**Spec author:** Planner hat (iteration #2, 2026-05-17)

## 目的 (Why)

連続描画ツール（pencil / brush / eraser）の現状の挙動:

- `CanvasView.mouseDown` / `mouseDragged` → `EditorWindowController.draw(at:y:)` → `DocumentModel.apply(name:transform:)`
- `apply(...)` は呼び出しごとに 1 つの `ImageEditCommand` を `EditHistory` に push する
- 結果として、1 ストロークで数十個の undo エントリが積まれ、ユーザーが Undo を 1 回押しても 1 サンプル分しか戻らない

これは ROADMAP M1 と `PROMPT.md` が明示的に指摘している UI/UX hardening 項目。**1 ストローク = 1 undo** を実現することで、Undo/Redo の体験を一般的なラスターエディタの期待値に揃える。

クリック単発の操作（paintBucket, eyedropper など）や、メニューからのフィルタ／変換（Invert, Threshold, Blur, Rotate90, ...）は従来通り 1 操作 = 1 undo のままで構わない。今回のスコープは `ToolInteractionKind.continuousDrawing` に該当する pencil / brush / eraser のみ。

## 対象ファイル

実装:
- `Sources/ClassicPixelCore/DocumentModel.swift` — ストロークセッション API を追加（公開）
- `Sources/ClassicPixelCore/EditCommand.swift` — 必要なら最小限のサポートを追加（基本は既存 `ImageEditCommand` を再利用）
- `Sources/ClassicPixelEditorApp/main.swift`
  - `EditorWindowController` — `beginStroke` / `extendStroke` / `endStroke` を提供（または `model` への薄いラッパー）
  - `CanvasView.mouseDown` / `mouseDragged` / `mouseUp` — `.continuousDrawing` の場合のみセッションで包む

テスト:
- `Tests/ClassicPixelCoreTests/CoreTests.swift` — 新しい XCTest を追加

ドキュメント変更は不要（README / SPEC は影響なし）。

## API スケッチ（Builder への指針、最終形は Builder の判断でよい）

`DocumentModel` に以下を追加する想定:

```swift
public mutating func beginStroke(name: String)
public mutating func extendStroke(_ transform: (PixelBuffer) throws -> PixelBuffer) throws
public mutating func endStroke()
```

セマンティクス:

- `beginStroke(name:)` で `before` をスナップショットして内部状態に保持する
- `extendStroke(...)` は `buffer` をその場で書き換える（history へは push しない）
- `endStroke()` で現在の `buffer` を `after` として `before != after` のときだけ 1 つの `ImageEditCommand` を push する
- `endStroke()` 後はストロークセッション状態をクリアする
- `beginStroke` 中にネストや他の操作が来た場合は安全側に倒す（既存の `apply(...)` 経路で別操作が来たら自動で `endStroke` を呼んでから処理するか、`assert` / `precondition` で防ぐかは Builder の判断 — ただしクラッシュさせるよりは defensive に閉じる方向を推奨）

代替案として `StrokeSession` 値型を返して `defer { session.end() }` で使う形でもよい。Builder が読みやすい方を選ぶこと。

`CanvasView` 側:

- `mouseDown` で `.continuousDrawing` のとき `beginStroke(name: tool.rawValue)` し、最初のサンプルを `extendStroke` で適用
- `mouseDragged` も `extendStroke` 経由
- `mouseUp` で `endStroke()`
- それ以外の interactionKind（clickEditing / dragSelection / clickSelection）は既存経路のまま

## 受け入れ基準（Acceptance criteria）

- [ ] `swift build` がエラー・新規警告なしで通る
- [ ] `swift test` で全件 PASS、かつ新しいテストを 2 件以上追加
  - [ ] テスト A: `beginStroke` → 複数回 `extendStroke` → `endStroke` の後、`history.canUndo == true` で **undo 1 回**で初期 buffer に戻る
  - [ ] テスト B: ストローク中に `before == after` のままで `endStroke` した場合（実質ノーオペ）は history に何も積まれない（`canUndo == false` を維持）
  - [ ] （任意・推奨）テスト C: 1 つのストロークの後にメニューからの `apply(...)`（例: invert）が来ても、Undo が 2 段階で正しく戻る
- [ ] `Sources/ClassicPixelEditorApp/main.swift` の `CanvasView` で、`.continuousDrawing` のドラッグ経路がストロークセッションを通る
- [ ] `scripts/cleanroom_guard.sh .` が exit 0
- [ ] Swift コード／コメントに `Photoshop` / `Adobe` identifier がない
- [ ] 既存テスト・既存機能（filters, transforms, paint bucket, selections, copy/paste, undo/redo for menu commands）が回帰していない

## テスト方針

`Tests/ClassicPixelCoreTests/CoreTests.swift` に純 Core ロジックの XCTest を追加する。AppKit には依存しない。
小さな PixelBuffer（例: 4x4, 白塗り）を使い、

1. `model.beginStroke(name: "Pencil")`
2. `model.extendStroke { buf in /* setPixel(0,0,.black) */ }`
3. `model.extendStroke { buf in /* setPixel(1,0,.black) */ }`
4. `model.extendStroke { buf in /* setPixel(2,0,.black) */ }`
5. `model.endStroke()`

の後で:

- `model.buffer` に 3 px が変わっていること
- `model.undo()` を 1 回呼ぶと初期状態（全 white）に戻ること
- `model.redo()` を 1 回呼ぶとストローク終了時点の状態に戻ること

を assertion する。

## CLEAN-ROOM 配慮事項

- `agdm/photoshop-1.0.1`、source ZIP、source mirrors、decompiled binaries を一切参照しない
- Undo グルーピングは一般的な GUI / vector editing / image editor の汎用パターンに基づく実装で、特定の他社ソースに由来しない
- 識別子・コメントに `Photoshop` / `Adobe` を使わない（spec / README の文脈説明は対象外）

## スコープ外（今回はやらない）

- マウス移動の補間（連続点を線分で繋ぐ stroke interpolation）— これは M4 の "stroke interpolation" の範疇
- Undo スタックの容量制限・メモリ圧縮
- ストローク中のプレビュー差分描画最適化
- 他ツール（paintBucket など）のグルーピング
- キーボードショートカット追加、selection outline (marching ants)、cursor preview — 別 task

## Builder へのハンドオフ要点

- `DocumentModel` に最小 API を追加し、`CanvasView` を切り替え、テストを足すだけで完結する規模
- 既存 `apply(name:transform:)` は維持（外部メニュー経由のフィルタが依存している）
- ストロークセッションの内部状態は `DocumentModel` 値の中に持つ。`Sendable` の制約を壊さないこと
- `EditHistory.push` は `before != after` のときのみ push する既存挙動を活かせば、ノーオペストロークの判定はそこに任せられる
