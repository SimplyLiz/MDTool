# MDTool AI Phase 2 — Trust-Editor Design

**Date:** 2026-05-28
**Status:** Design approved in brainstorm, pending user review of written spec
**Supersedes nothing; builds on:** Phase 1 (`docs/superpowers/specs/2026-05-18-mdtool-ai-writing-tools-design.md`, merged via PR #3)

---

## 1. Vision Context

**Product positioning:** MDTool is a public, cross-platform (macOS + Windows) indie Markdown editor. Phase 2 commits to the **Trust-Editor** edge: the first markdown editor whose AI edits a writer can actually trust, because the original text stays visible and every AI change is accepted or rejected per block with a single atomic undo.

**Visual identity:** Sober Minimalist (iA Writer / Typora lineage) — warm/cool accent, generous whitespace, serif body + mono code, pastel diff colors instead of saturated red/green.

**Edge sequencing (Hybrid A → B):** Phase 2 ships edge A (Trust-Editor). Phase 3 will layer edge B (doc-anchored Memento context via YAML frontmatter) on top. Phase 2 architecture must not block B but does not implement it.

**Why this phase exists:** Phase 1 shipped the streaming-diff mechanics (per-block accept/reject, atomic undo, sidecar) but rendered them as a floating overlay Card with saturated colors, and never wired the editor's syntax theme — leaving the editor body itself nearly unreadable (verified: `CodeController` constructed with no theme, `CodeField.textStyle` with no color, `MarkdownHighlighter` defined but unused). Phase 2 fixes the editor foundation and replaces the overlay with true inline track-changes rendering.

### In Scope
1. **Editor Foundation** — wire syntax highlighting via `CodeTheme`, set readable text colors, typography (serif body / mono code), Light + Dark themes.
2. **Inline Diff (P1 Track-Changes)** — original shown strikethrough on pastel-rose, AI text on pastel-mint, in the same spatial location, with per-block ✓/✗ pills and keyboard control.

### Out of Scope (deferred to separate specs)
- **Block B:** 3-tier Design Token System + app-wide visual refresh (dialogs, toolbars, sidebar).
- **Block C:** Performance audit ("app feels sluggish").
- **Block E:** Bug-sweep — `sidecarLifecycleProvider` invalidation (nyxCore `ef2bcf80`), commit the 3 local Phase-1 fixes (anthropic.ts signal, secrets.dart legacy keychain, entitlements), investigate AppDelegate `unrecognized selector`.
- **Phase 3:** Memento/nyxCore frontmatter context binding.

---

## 2. Architecture

The editor occupies one spatial frame with two discrete states sharing identical typography and padding:

```
EditorPane (Stateful)
├── diffState == null  → CodeField(controller)          [Edit-Mode, existing]
└── diffState != null  → DiffDecisionView(state)         [Decision-Mode, new]
        controlled by StreamingDiffController (Phase-1, existing)
```

**Mode-switch trigger:** `streamingDiffStateProvider` value transitions null ↔ non-null.
- Edit-Mode: full `CodeField` (undo, selection, cursor, scrolling).
- Decision-Mode: read-only `SelectableText.rich`. Keyboard: Tab = next block, Enter = accept, Backspace = reject, Esc = cancel all.
- Commit (all blocks decided): single `controller.value = TextEditingValue(...)` write → one undo step → switch back to Edit-Mode.

**Three sub-systems:**

| Sub-System | Location | Responsibility | Phase-1 status |
|---|---|---|---|
| EditorTheme | `lib/core/theme/` (new) | Light+Dark color sets, typography scale, syntax-highlight map. Pure data. | absent |
| EditorPane | `lib/ui/widgets/markdown_editor.dart` (modified) | Mode-switch CodeField ↔ DiffDecisionView; identical geometry (font, padding, line-height, scroll). | Edit-Mode exists, Decision-Mode missing |
| DiffDecisionView | `lib/ui/widgets/ai/streaming_diff/diff_decision_view.dart` (new) | Renders track-changes TextSpans + interactive ✓/✗ pills per block. Read-only. | Phase-1 had Stack-overlay Card — replaced |

**Local-first:** Fully offline-capable. Diff state is in-memory; only the live token stream needs network. Decision phase is synchronous and local.

**Phase-3 (B) compatibility:** DiffDecisionView can later gain a context-lane showing Memento refs without touching EditorTheme or StreamingDiffController. EditorTheme naming uses **intent** (`diffDelBg`, `pillAcceptFg`) not appearance, so the Block-B token refactor is additive.

**Deliberate constraint:** One AI op at a time. Decision-Mode is read-only, so the user cannot start a second op on another paragraph mid-decision. This eliminates the "selection moved between trigger and commit" bug class (see §5 E5). Multi-op queue is Phase-3 YAGNI.

---

## 3. Components

### New: `lib/core/theme/editor_theme.dart`
Flat data class (no token hierarchy — that is Block B). Intent-based naming. Fields:

```dart
class EditorTheme {
  final Brightness brightness;
  // Editor surface
  final Color surface;          // light #FBFAF7  dark #1E1F23
  final Color onSurface;        // light #1A1A1A  dark #E8E6E0
  final Color onSurfaceMuted;   // light #6E6E6E  dark #8A8780
  final Color caret;            // accent
  final Color selection;        // pastel highlight
  // Diff tokens (P1 track-changes)
  final Color diffDelBg;        // light #FDE8E8  dark #3A2424  (pastel rose)
  final Color diffDelFg;        // light #6B2929  dark #E5B5B5
  final Color diffDelStrike;    // strikethrough line color
  final Color diffInsBg;        // light #E6F4EA  dark #1F3A2A  (pastel mint)
  final Color diffInsFg;        // light #1F4D2F  dark #B5DCC5
  // Pills
  final Color pillBg;
  final Color pillBorder;
  final Color pillAcceptFg;
  final Color pillRejectFg;
  // Syntax map for CodeTheme widget
  final Map<String, TextStyle> syntaxStyles;
  // Typography
  final TextStyle bodyStyle;    // Charter / Iowan Old Style, 16, line-height 1.6
  final TextStyle codeStyle;    // JetBrains Mono / SF Mono, 14, line-height 1.5

  factory EditorTheme.light();
  factory EditorTheme.dark();
}
```

All concrete color values above are the **specified defaults** for v1. Every diff color pair MUST meet WCAG AA (≥ 4.5:1 fg-on-bg); values may be nudged during implementation only to satisfy that assertion (see §5 contrast tests).

The syntax map reuses the existing GitHub-light palette already present in `lib/core/utils/markdown_highlighter.dart` (currently dead code) as the light-theme source, plus a dark equivalent. `MarkdownHighlighter` is otherwise removed once its palette is migrated into `EditorTheme`.

### New: `lib/core/theme/editor_theme_provider.dart`
```dart
final editorThemeProvider = Provider.family<EditorTheme, Brightness>((ref, brightness) {
  return brightness == Brightness.dark ? EditorTheme.dark() : EditorTheme.light();
});
```
The consuming widget reads brightness from context (`MediaQuery.platformBrightnessOf(context)`, inherit-aware — rebuilds automatically on system theme switch) and passes it to the family provider: `ref.watch(editorThemeProvider(brightness))`. This keeps theme selection in one place and consumable by other widgets (dialogs/toolbars for the minimal app-theme derivation in §3).

### New: `lib/ui/widgets/ai/streaming_diff/diff_decision_view.dart`
```dart
class DiffDecisionView extends ConsumerStatefulWidget {
  final StreamingDiffController controller;
  final EditorTheme theme;
  final TextStyle baseTextStyle;   // MUST equal CodeField's textStyle
  final EdgeInsets padding;        // MUST equal CodeField's padding
  final double initialScrollOffset; // captured from editor before switch
  final VoidCallback onCommit;
  final VoidCallback onCancel;
}
```
Body: `SingleChildScrollView` → `SelectableText.rich(TextSpan(children: [...]))`:
- equal block → `baseTextStyle.copyWith(color: theme.onSurface)`
- delete block → `+ backgroundColor: diffDelBg, color: diffDelFg, decoration: TextDecoration.lineThrough, decorationColor: diffDelStrike`
- insert block → `+ backgroundColor: diffInsBg, color: diffInsFg`
- per DiffPair → trailing `WidgetSpan` with two `_Pill` buttons (✓/✗)
- focused block → visible focus outline + keyboard hint
Keyboard via `FocusNode` + `Shortcuts`/`Actions`. Pills disabled until stream `done`.

### Modified: `lib/ui/widgets/markdown_editor.dart`
- `_initializeController()` (≈L136): unchanged controller construction.
- `CodeField` (≈L823): wrapped in `CodeTheme(data: CodeThemeData(styles: theme.syntaxStyles), child: ...)`; `textStyle` set to `theme.bodyStyle.copyWith(color: theme.onSurface)`; `cursorColor`/selection from theme.
- New conditional build:
```dart
final diffState = ref.watch(streamingDiffStateProvider);
final brightness = MediaQuery.platformBrightnessOf(context);
final theme = ref.watch(editorThemeProvider(brightness));
return diffState == null
  ? CodeTheme(data: CodeThemeData(styles: theme.syntaxStyles),
      child: CodeField(controller: _codeController, textStyle: theme.bodyStyle.copyWith(color: theme.onSurface), padding: kEditorPadding))
  : DiffDecisionView(controller: _diffController!, theme: theme,
      baseTextStyle: theme.bodyStyle.copyWith(color: theme.onSurface),
      padding: kEditorPadding, initialScrollOffset: _capturedScrollOffset,
      onCommit: _commitDiff, onCancel: _cancelDiff);
```
- The Phase-1 `if (diffOverlay != null) diffOverlay` Stack overlay (≈L853) is **removed**.
- `kEditorPadding` becomes a shared constant used by both modes (eliminates §5 E6 mismatch).

### Modified: app theme entry (`lib/main.dart` or equivalent)
Derive `ColorScheme` from `EditorTheme` so dialogs/toolbars stay consistent. Minimal-effort only; full app-wide token unification is Block B.

---

## 4. Data Flow

### Flow 1 — Edit → Refine trigger
`SelectionDetector` (Phase-1) detects non-empty selection → `SelectionToolbar` (Phase-1) → user clicks action → `aiIntentProvider` set → `markdown_editor.dart` listener spawns `StreamingDiffController.start(opId, originalText, request)` and exposes `streamingDiffStateProvider` → `diffState != null` → switch to DiffDecisionView. The mode-switch happens **before the first delta**; DiffDecisionView opens with a "thinking" hint and fills live. The editor scroll offset is captured immediately before the switch and passed as `initialScrollOffset`.

### Flow 2 — Streaming → Decision-Mode
Sidecar (Phase-1) emits JSON-RPC `stream.delta {opId, blockIdx, deltaType, text}` → `AIWorkerClient` per-opId filtered stream → `StreamingDiffController._onDelta` → `state.applyDelta(...)` → `notifyListeners()` → DiffDecisionView rebuilds. `stream.done` → `state.markComplete` → pills become interactive.

Block model (Phase-1 exists): output is a sequence of `equal` / `delete` / `insert` blocks; adjacent delete+insert form a DiffPair with one ✓/✗ pill group. Pills disabled before `done`.

### Flow 3 — Accept/Reject → atomic commit
Per-block decision (interim, no doc mutation): user Tab/Enter/Backspace/click → `controller.accept(idx)` / `.reject(idx)` → `state.blocks[idx].decision` set → DiffDecisionView rebuilds (rejected del loses strikethrough; rejected ins dims; accepted ins keeps mint).

Atomic commit (all decided): `controller._maybeCommit()` checks all decisions set → builds `committedText = blocks.map((b) => b.committedText).join()` → sets `_committed` guard (nyxCore `b59387f0`) → `onCommit` callback → `markdown_editor.dart` does ONE `controller.value = TextEditingValue(text: editorText.replaceRange(start, end, committedText))` (one undo step) → `streamingDiffStateProvider` set null → switch back to Edit-Mode → cursor at end of inserted text, scroll preserved.

Cancel path (Esc or stream error): `controller.cancel()` → abort signal to sidecar → state null → switch back, no doc mutation.

---

## 5. Error Handling & Edge Cases

### Critical (would corrupt the op)
| # | Edge | Behavior | Mitigation |
|---|---|---|---|
| E1 | Stream stalled (no delta/done for 60s) | pills never interactive | heartbeat timeout since last **delta** → footer "Stream stalled — Esc to cancel" → cancel path |
| E2 | Stream error mid-flight (401/network/400) | error event in stream | `state.markError(msg)` → inline pastel-amber banner + Retry/Cancel; no doc mutation |
| E3 | Re-entrancy — `onCommit` fires twice | double `atomicReplace` on already-replaced text (nyxCore `b59387f0`) | `_committed` bool guard set before callback; mandatory test |
| E4 | Empty AI output (only `equal` blocks) | nothing to decide | "No changes suggested" + auto-dismiss after 1.5s → Edit-Mode |

### Medium (degrades UX)
| # | Edge | Behavior | Mitigation |
|---|---|---|---|
| E5 | Selection moves between trigger and commit | **impossible** — Decision-Mode is read-only | architecture eliminates this bug class |
| E6 | Padding/font mismatch CodeField ↔ DiffDecisionView | visible flicker on switch | shared `kEditorPadding` + shared `theme.bodyStyle`; golden test |
| E7 | Scroll jump on mode-switch | Decision-View starts at offset 0 | capture editor scroll offset pre-switch, pass to DiffDecisionView. **Risk:** Phase-1 comments (≈L445) suggest CodeField scroll-position API is limited. If pixel-offset is unavailable, fall back to scrolling the focused block into view by block index. Verify in spike. |
| E8 | Very long selection (multi-screen) | Decision-View must scroll | `SelectableText.rich` in `SingleChildScrollView`; focused block auto-scrolls into view on Tab |

### Low (cosmetic / rare)
| # | Edge | Behavior | Mitigation |
|---|---|---|---|
| E9 | System theme switch mid-decision | provider rebuilds, colors swap live | acceptable; spans recompute, no data loss |
| E10 | Markdown syntax inside a diff block (e.g. `**bold**`) | no syntax highlight in read-only Decision-Mode | deliberate: raw text with diff colors only; syntax returns after commit. Trust > pretty |
| E11 | Sidecar dead at trigger | "Could not resolve auth" etc. | SidecarHealthBanner (Phase-1) + lifecycle invalidation — belongs to **Block E**, referenced only |

### Deliberate constraints (design, not bugs)
- One op at a time (eliminates E5).
- No syntax highlight in Decision-Mode (E10) — trust clarity beats prettiness.
- Decision-Mode fully keyboard-operable with visible per-block focus ring (Harmonia WCAG, mandatory for indie-public).

### Top residual risks (Cael)
1. **E7 scroll-sync** is the largest real risk; CodeField may not expose pixel scroll position. Spike must verify before committing to pixel-offset; block-index fallback otherwise.
2. **E1 timeout = 60s since last delta** (not since start) handles slow long Opus streams. `bedarf validierung` against real latency.
3. **E10 no-syntax Decision-Mode** may surprise users; accepted tradeoff, candidate for user testing.

---

## 6. Testing

TDD. Unit-heavy, targeted widget tests, one load-bearing golden. Fake client only — fixtures match real Anthropic SDK behavior (nyxCore `9d76c4c`), no real API calls.

### Unit
**`editor_theme_test.dart`** (new)
- `.light()`/`.dark()` return all required fields non-null.
- WCAG AA contrast: `onSurface`/`surface` ≥ 4.5:1; `diffDelFg`/`diffDelBg` ≥ 4.5:1; `diffInsFg`/`diffInsBg` ≥ 4.5:1 (luminance-ratio helper).

**`streaming_diff_model_test.dart`** (extend Phase-1)
- interleaved equal/del/ins → correct block sequence.
- `accept`/`reject` targets only one block.
- `committedText` for mixed decisions = correct concatenation.
- E4: only-equal → `hasChanges == false`.
- E3: "all decided" reached twice fires `onCommit` exactly once (`_committed` guard).

**`streaming_diff_controller_test.dart`** (extend Phase-1)
- fake client delta→delta→done → correct progression.
- E2: error event → `state.error != null`, no commit.
- E1: no delta past timeout → stalled flag (fake clock).
- cancel → abort called, state nulled, no commit callback.

### Widget
**`diff_decision_view_test.dart`** (new)
- del block has `lineThrough` + `diffDelBg`; ins block has `diffInsBg`, no strikethrough.
- pills disabled before `done`, enabled after.
- Tab moves focus to next DiffPair; Enter→accept; Backspace→reject; Esc→cancel.
- focus ring visible on active block (A11y).
- E8: long selection scrolls; Tab scrolls focused block into view.

**`markdown_editor_mode_switch_test.dart`** (new)
- `diffState == null` → CodeField present, no DiffDecisionView.
- `diffState != null` → DiffDecisionView present, no CodeField.
- after commit → CodeField returns, doc text contains committedText.
- E3: commit produces exactly one undo entry; undo restores full pre-op state.

### Golden
**`mode_switch_geometry_golden_test.dart`** (new, E6)
- same text in CodeField vs DiffDecisionView (no active diffs) → identical baseline + padding (golden file). Structurally prevents the 1px flicker problem.

### Not tested (YAGNI)
- real Anthropic calls; sidecar integration (Phase-1 + Block E); frame-timing/performance (Block C); scroll pixel-sync E7 (spike-dependent — gets its own test once the approach is fixed).

---

## 7. Open Items Before Planning
- **Spike (1–2h):** verify CodeField scroll-position access for E7; decide pixel-offset vs block-index fallback. This is the only unknown that could reshape DiffDecisionView's scroll handling.
- Confirm body/mono font availability bundled on both macOS and Windows (Charter/Iowan are macOS system serifs; Windows needs a bundled fallback such as a packaged serif). `bedarf validierung`.
