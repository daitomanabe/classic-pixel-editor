#!/usr/bin/env bash
set -euo pipefail

repo="${1:-daitomanabe/classic-pixel-editor}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  }
}

need_cmd gh
need_cmd jq

ensure_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  if gh label list --repo "$repo" --limit 200 --json name | jq -e --arg name "$name" '.[] | select(.name == $name)' >/dev/null; then
    printf 'label exists: %s\n' "$name"
  else
    gh label create "$name" --repo "$repo" --color "$color" --description "$description"
    printf 'label created: %s\n' "$name"
  fi
}

issue_by_exact_title() {
  local title="$1"
  gh issue list --repo "$repo" --state all --limit 200 --json number,title,url \
    | jq -r --arg title "$title" '.[] | select(.title == $title) | "\(.number)|\(.url)"' \
    | head -1
}

create_issue_if_missing() {
  local title="$1"
  local labels="$2"
  local body="$3"
  local existing
  existing="$(issue_by_exact_title "$title")"
  if [ -n "$existing" ]; then
    local number="${existing%%|*}"
    local url="${existing#*|}"
    printf 'issue exists: #%s %s %s\n' "$number" "$url" "$title"
    return
  fi

  local args=(issue create --repo "$repo" --title "$title" --body "$body")
  IFS=',' read -r -a label_array <<< "$labels"
  for label in "${label_array[@]}"; do
    args+=(--label "$label")
  done
  local url
  url="$(gh "${args[@]}")"
  local number="${url##*/}"
  printf 'issue created: #%s %s %s\n' "$number" "$url" "$title"
}

ensure_label roadmap "6f42c1" "Roadmap and milestone planning"
ensure_label clean-room "0e8a16" "Clean-room process and release guard work"
ensure_label ui-ux "1d76db" "Native app interaction and visual polish"
ensure_label testing "5319e7" "Build, unit, smoke, and guard coverage"
ensure_label packaging "c5def5" "macOS app bundle, signing, and distribution"
ensure_label tools "fbca04" "Editor tools, selections, adjustments, and filters"
ensure_label release "d4c5f9" "Release readiness and public artifacts"

body="$(cat <<'BODY'
Roadmap milestone: UI/UX hardening.

Scope:
- Group drag strokes into one undoable edit.
- Improve active tool feedback, cursor previews, and selection outlines.
- Extend the status bar with modified state, color mode, and active tool.

Clean-room note: implement from repo code, platform APIs, and generic UI knowledge only.
BODY
)"
create_issue_if_missing "Harden canvas interactions and status UI" "roadmap,ui-ux" "$body"

body="$(cat <<'BODY'
Roadmap milestone: test infrastructure.

Scope:
- Move the current executable core test runner into standard SwiftPM test targets when supported toolchains expose the test framework reliably.
- Preserve deterministic generated-image coverage for pixel math and image operations.
- Keep the guard checks in CI.

Clean-room note: no behavior should be copied from proprietary implementations.
BODY
)"
create_issue_if_missing "Migrate core checks to XCTest targets" "roadmap,testing" "$body"

body="$(cat <<'BODY'
Roadmap milestone: document-based packaging.

Scope:
- Package the editor as a proper document-based macOS app bundle.
- Add original bundle metadata and icon assets.
- Document signing, notarization, and release packaging steps.

Clean-room note: all app identity and visual assets must be original.
BODY
)"
create_issue_if_missing "Package as a document-based macOS app" "roadmap,packaging" "$body"

body="$(cat <<'BODY'
Roadmap milestone: tool depth.

Scope:
- Add stroke interpolation, brush shape controls, opacity controls, and paint bucket tolerance UI.
- Improve lasso completion, selection move/copy behavior, crop UI, and resize dialogs.
- Add focused tests for each destructive operation.

Clean-room note: algorithms should come from generic image-processing knowledge.
BODY
)"
create_issue_if_missing "Expand editing tools and selection behavior" "roadmap,tools" "$body"

body="$(cat <<'BODY'
Roadmap milestone: filters and adjustments.

Scope:
- Add Gaussian blur, unsharp mask, hue/saturation, noise, and histogram-based levels UI.
- Keep operations pure in the core target and covered by generated sample images.
- Document limitations where algorithms are intentionally simple.

Clean-room note: prioritize deterministic original implementations over historical fidelity.
BODY
)"
create_issue_if_missing "Add more tested filters and adjustments" "roadmap,tools,testing" "$body"

body="$(cat <<'BODY'
Roadmap milestone: release readiness.

Scope:
- Add tagged source release process.
- Add screenshots generated from this app only.
- Verify app name, bundle identity, README, and release notes stay clean-room and non-affiliated.

Clean-room note: release artifacts must not include vendor artwork, copied prose, or private generated files.
BODY
)"
create_issue_if_missing "Prepare first public release checklist" "roadmap,release,clean-room" "$body"
