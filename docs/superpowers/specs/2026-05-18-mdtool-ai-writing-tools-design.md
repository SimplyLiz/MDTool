# MDTool AI Writing Tools — Design Spec

**Status:** Draft — pending user review
**Author:** Brainstormed with Oli (oliver.baer@gmail.com), synthesized via nyxCore personas (Nefilibata, Aristaeus, Harmonia, Ipcha Mistabra)
**Created:** 2026-05-18
**Source idea:** Bring the writing-enhancement UX from `nyx.markEdit` (Apple Writing Tools clone) into MDTool (Flutter cross-platform), powered by nyxCore + multiple knowledge sources.

---

## 1. Executive Summary

MDTool gains a context-aware text-enhancement layer: right-click + selection-toolbar → AI operations (Refine, Refine + Knowledge, Shorten, Translate, Tone) → inline streaming-diff with per-block accept/reject. Powered by Claude (default) with OpenAI/Ollama fallback. Knowledge comes from four sources via a Node sidecar that holds the official MCP and Anthropic SDKs: **nyxCore** (projects, patterns, insights, personas), **Notion** (workspace docs), **Axiom** (style/brand/code rules with authority levels, surfaces as inline lint squiggles), and **GitHub** (READMEs + ADRs from allowlisted repos). Every accepted edit feeds back into nyxCore as an insight (Memento-Loop) so the system learns the user's voice per project over time.

**Why this matters (Aristaeus' User Truth):** *AI text tools today sound like ChatGPT, not like the user or their project.* The wedge is one primitive — "refine with context" — that respects project voice, prior decisions, and house style.

## 2. Scope

### In Scope (MVP / Maximalpaket)
- Right-click + floating selection-toolbar entry points (markdown editor surface).
- Operations: Refine, Refine + Knowledge, Shorten, Translate, Tone (persona-driven).
- Inline streaming-diff with per-block accept/reject during the stream, plus atomic Cmd+Z undo of the whole operation after commit.
- Alt-modifier → Cael-style compare mode (two parallel variants).
- Per-document context (YAML frontmatter for `.md`, `.nyx` sidecar for non-MD).
- Auto-detect project + persona + tone on first AI call per doc; user confirms once.
- Four knowledge sources behind a single `KnowledgeSource` plugin interface: nyxCore-MCP, Notion-MCP, Axiom-Adapter, GitHub-Adapter.
- Trust/provenance wrapping + prompt-injection defense layer.
- Axiom-Linter (inline squiggles by authority, plus on-demand bulk panel).
- Three providers: Claude (default), OpenAI (fallback/compare partner), Ollama (local/private).
- Memento-Loop: accepted edits → nyxCore insight write-back (opt-out per doc).
- Settings panel: provider keys (Keychain-backed), source configuration, persona browser, trust-level overrides, memento toggle.
- Cross-platform: macOS + Windows.

### Iteration 2 (later, foundation laid in MVP)
- Inline ghost-completion (Cursor/Copilot-style proactive suggestions).

### Explicitly Out of Scope (Ipcha-filtered)
- Auto-persona consistency-check across multiple docs (only on explicit user request).
- CI/CD pipeline integration, live system metrics, performance-monitoring as a writing source — wrong abstraction level for a text editor.
- Project dependency graphs, automatic rollback functions for projects — belongs in a separate project-management tool.
- iOS / Linux targets (Flutter supports them, but MDTool ships macOS + Windows only today).
- Confluence, Jira, Slack adapters — `KnowledgeSource` interface is ready, but no adapter ships in MVP.

## 3. Confirmed Design Decisions

| # | Area | Decision | Reason |
|---|---|---|---|
| 1 | AI affordance | Selection-toolbar (Notion-style) + right-click menu. Iteration 2 adds inline ghost-completion. | Harmonia: toolbar is faster for power users, right-click is the discovery surface. |
| 2 | Context binding | Auto-detect on first call → persisted as YAML frontmatter (or `.nyx` sidecar). Per-op override via Alt-click. | Ipcha: any model that asks "which project?" per operation is dead UX. |
| 3 | Diff/accept | Inline streaming-diff with per-block ✓/✗. Alt-click → Cael compare mode (two variants). | Nefilibata: the feature that wants to exist; protects against trust-collapse from modal "all or nothing." |
| 4 | Knowledge sources (MVP) | All four: nyxCore, Notion, Axiom, GitHub. | User decision; phased internally so delivery is incremental. |
| 5 | Provider stack | Claude default, OpenAI + Ollama retained. Sidecar uses official `@anthropic-ai/sdk` with prompt-caching. | Streaming + caching maturity is highest in Claude SDK. |
| 6 | Axiom UX | Inline authority-coded squiggles (red/orange/grey) + on-demand bulk panel (Cmd+Shift+V). | Authority levels must be visually distinct; bulk view for ESLint-mentality reviews. |
| 7 | Memento-Loop | Automatic write-back of accepted diffs to nyxCore as insights. Opt-out per doc via `nyx.memento: off`. | Compounding value; per-doc privacy escape hatch. |
| 8 | Prompt-injection defense | Defensive wrapping + provenance tags + per-source trust level. | Industry baseline; doesn't mangle legitimate content. |
| 9 | Transport | Node sidecar daemon bundled with Flutter app. JSON-RPC over Unix socket / named pipe, SSE-style notifications for streaming. | Leverages official SDKs; Dart-side MCP+Anthropic reimplementation would be permanent maintenance debt. |

## 4. System Architecture

Three lanes:

```
┌─── Flutter (Dart, the user-facing app) ───────────────────────────────┐
│  Selection-Toolbar + Right-Click  │  Streaming-Diff-Renderer          │
│  Axiom-Linter-Layer (squiggles)   │  Frontmatter / Sidecar Manager    │
│  Auto-Detect Service              │  Settings Panel                   │
└────────────────────────┬──────────────────────────────────────────────┘
                         │ JSON-RPC over Unix-Socket / Named-Pipe
                         │ SSE-style server-initiated notifications
┌────────────────────────┴──────────────────────────────────────────────┐
│                 AI Worker Sidecar (Node, bundled in app)              │
│  RPC Server   │  Orchestrator (parallel fan-out, prompt build,        │
│               │   provider routing, token-budget enforcement)         │
│  KnowledgeSource Plugin Interface  │  Trust/Sanitizer Layer           │
│  Memento Writer (fire-and-forget) │                                   │
└────┬───────────────┬───────────────┬──────────┬──────────┬────────────┘
     │               │               │          │          │
 ┌───┴────┐    ┌─────┴─────┐    ┌────┴────┐ ┌───┴────┐ ┌───┴────┐
 │nyxCore │    │  Notion   │    │  Axiom  │ │ GitHub │ │Anthropic│
 │  MCP   │    │   MCP     │    │ Adapter │ │Adapter │ │  /OAI  │
 │ TRUST=H│    │  TRUST=M  │    │ TRUST=H │ │TRUST=L │ │/Ollama │
 └────────┘    └───────────┘    └─────────┘ └────────┘ └────────┘
```

**Key design hooks:**
- `KnowledgeSource` interface is the **only** extension point for adding new sources — Confluence, Slack, Linear become single-file additions with zero Orchestrator changes.
- Trust-Layer is a single mandatory pipeline stage in the Orchestrator; cannot be bypassed by an adapter author.
- Frontmatter is the single source of truth for doc-level context — no hidden DB state, no orphaned metadata.

## 5. Data Flow — "Refine + Knowledge" Walkthrough

Scenario: user selects in `docs/architecture.md`:
> "Wir benutzen 'utils' für die Helper-Funktionen."

Doc frontmatter: `nyx: { project: nyx.mdEdit, persona: Aristaeus, tone: technical-precise }`.

1. **User clicks ✨ Refine + Wissen** in selection-toolbar. Flutter resolves selection range + cached doc-context.
2. **Flutter → Sidecar RPC** `refineWithKnowledge({ selection, docContext, intent })`.
3. **Orchestrator parallel fan-out** (1.5s timeout per source, no waiting on stragglers):
   - nyxCore `get_patterns` + `get_insights` (TRUST=HIGH)
   - Axiom-Adapter `search(authority=mandatory|guideline, domain=style+brand)` (TRUST=HIGH)
   - Notion `search("utils helper naming")` (TRUST=MEDIUM)
   - GitHub `search-code` over allowlisted repos (TRUST=LOW for public, MEDIUM for private)
4. **Trust-wrapping + prompt-build:** each chunk wrapped in `<external_context source="..." trust="..." authority="...">...</external_context>`. System prompt includes Aristaeus persona-skill body, tone directive, anti-injection reminder. Token budget enforced (8k cap for knowledge block); ranking = `authority_weight × trust_weight × recency_decay`.
5. **Provider routing → Claude.** `anthropic.messages.stream` with `cache_control: ephemeral` on the system prompt + knowledge block (within 5min, refines on the same doc cost only delta tokens).
6. **Streaming-Diff renders live.** Sidecar forwards Anthropic SSE 1:1 as JSON-RPC notifications. Flutter renders per-block: original (red strikethrough) above, new text (green) below, with ✓ / ✗ pills that appear once each block completes.
7. **User accepts both blocks.** Flutter writes atomic edit (single undo entry).
8. **`confirmAccept` → Memento-Writer.** Fire-and-forget; if `nyx.memento != "off"`, writes `nyxcore_create_insight` with diff, persona, source-trust mix. Failure → buffered to `~/.mdtool/memento-queue.db`, flushed on next successful call.

**Critical paths:**
- Cancellation (`cancel(opId)`) must take effect within 500ms (Anthropic `AbortSignal`).
- A degraded source emits a warning event so the UI can show "Notion unavailable — proposal based on 3 of 4 sources" — silent silent-failure is unacceptable.

## 6. Contracts & Schemas

### 6.1 Document Frontmatter (`nyx:` block)

```yaml
nyx:
  project: nyx.mdEdit              # nyxCore project slug or UUID
  persona: Aristaeus                # persona name (from nyxcore_get_personas)
  tone: technical-precise           # free-text tone directive
  provider: claude                  # claude | openai | ollama (override)
  memento: on                       # on | off | bulk
  sources:                          # optional per-doc overrides
    nyxcore: true
    notion: true
    axiom: { authority: [mandatory, guideline] }
    github: { repos: [nyxCore-Systems/nyxcore-systems] }
  axiom_lint: on                    # on | off | panel-only
  private: false                    # if true: disables memento + external sources
```

- `.md` files: YAML frontmatter (standard, already MDTool-supported).
- Non-MD: `.<ext>.nyx` sidecar with the `nyx:` block, OR XDG-cache map (`~/.mdtool/sidecars/<path-hash>.yaml`).
- Schema-validated on read; broken frontmatter triggers in-memory defaults + an informal squiggle on line 1 ("nyx block invalid: field X — auto-detect used"). Never silently writes over a broken block.

### 6.2 Sidecar RPC API (JSON-RPC 2.0)

```typescript
interface AIWorkerRPC {
  // discovery
  health(): { ok: boolean, version: string, sources: SourceStatus[] }
  listPersonas(query?: string): Persona[]
  listProjects(): Project[]

  // per-document setup
  autoDetect(docPath: string, sampleText: string): {
    projectSuggestion: { id: string, confidence: number, reason: string }
    personaSuggestion: { name: string, confidence: number, reason: string }
    toneSuggestion: string
  }
  loadContext(docPath: string): DocContext

  // core operations — all return opId; results stream as notifications
  refine(p: { selection: string, docContext: DocContext, op: RefineOp }): { opId: string }
  refineWithKnowledge(p: {...}): { opId: string }
  validate(p: { fullDoc: string, docContext: DocContext }): { opId: string }
  compare(p: {...}): { opId: string }   // Cael mode: two variants

  // feedback
  confirmAccept(p: { opId: string, acceptedBlocks: string[], rejectedBlocks: string[] }): void
  cancel(opId: string): void
}

// Server-initiated notifications:
//   stream.delta              { opId, blockIdx, deltaType: "del"|"add", text, variant? }
//   stream.block_complete     { opId, blockIdx, finalText }
//   stream.done               { opId, totalBlocks, tokenUsage, cost }
//   stream.error              { opId, message, recoverable: boolean }
//   validation.diagnostic     { opId, line, col, severity, axiomId, message, fixHint }
//   source.degraded           { sourceId, reason, until? }
```

**Contracts:**
- All mutations idempotent over `opId` — replay after a wobble overwrites nothing.
- Streaming is notification-only, no request/response — minimum latency.
- `cancel(opId)` must take effect within 500ms.

### 6.3 KnowledgeSource Plugin Interface

```typescript
interface KnowledgeSource {
  readonly id: string                    // "nyxcore" | "notion" | "axiom" | "github"
  readonly displayName: string
  readonly defaultTrust: "high" | "medium" | "low"

  init(config: SourceConfig): Promise<void>
  health(): Promise<{ ok: boolean, reason?: string }>
  query(intent: QueryIntent, ctx: DocContext): Promise<KnowledgeChunk[]>
  validate?(text: string, ctx: DocContext): Promise<Diagnostic[]>   // Axiom only in MVP
}

interface KnowledgeChunk {
  sourceId: string
  trust: "high" | "medium" | "low"
  authority?: "mandatory" | "guideline" | "informal"   // axiom-shape
  domain?: string[]                                    // ["style", "brand", "code", ...]
  content: string
  citation: { url?: string, title: string, lastSeen?: Date }
  tokenEstimate: number
}
```

**Consequences:**
- New source = new file in `sidecar/sources/<id>.ts` + registry entry. **Zero Orchestrator changes.**
- Trust / authority live on the chunk, not the source — per-chunk override is trivial (e.g., a private repo hit can be MEDIUM while public repos are LOW).
- Token budget is enforced by the Orchestrator; sources don't know about it.

## 7. Failure Modes & Mitigation

| # | Failure | Likelihood | Blast Radius | Mitigation |
|---|---|---|---|---|
| F1 | Sidecar won't start | M | All AI ops dead | Health check on Flutter start. Banner + restart button. Editor remains usable. |
| F2 | MCP server timeout | H | Per-source partial | 1.5s timeout per source; degrade visibly ("3 of 4 sources used"). |
| F3 | Anthropic API down / rate-limited | M | Total for refine | Provider fallback chain claude → openai → ollama with exponential backoff (max 3). Toast on switch. |
| F4 | Stream breaks mid-way | L | Partial result | `stream.error { recoverable: true }`; user choice "continue or discard". |
| F5 | Prompt-injection in external content | L (rising with adoption) | High if successful | Defensive wrapping + trust tags + post-hoc detection of suspicious model output (system-string leaks → abort + security log). |
| F6 | Memento write to nyxCore fails | M | Learning delayed only | Fire-and-forget; buffered in `~/.mdtool/memento-queue.db`; flushed next successful call. |
| F7 | Corrupt frontmatter | M | Doc context missing | Schema validation; in-memory defaults; informal squiggle on line 1. Never auto-writes over broken block. |
| F8 | Axiom linter blocks UI | L | UX lag | Debounced 300ms in sidecar (not main thread); 200-diagnostic hard cap; streamed as notifications. |
| F9 | User accidentally accepts garbage | M | Trust collapse | Cmd+Z always undoes the **whole** refine op atomically. `nyx.confirm_full_doc_changes` for >30% edits. |
| F10 | API keys leak via logs | L | High | `pino` redactor for `sk-*`, `xoxb-*`, `ghp_*`. Settings shows last-4 only. Keys live in macOS Keychain / Windows Credential Manager. |
| F11 | Cael compare doubles cost without value | M | Cost | Opt-in only (Alt-click). Pre-op estimate: "Compare mode: ~$0.04 vs $0.02 — continue?". |

### Privacy & Local-only mode
- `nyx.provider: ollama` + `nyx.sources: []` → fully offline; no external source touched; memento disabled.
- `nyx.private: true` → hard-disables memento + GitHub + Notion regardless of global settings.
- Pre-send PII/REDACTED regex warning (opt-in in settings).

### Observability
- Structured JSON-lines logs (`pino`) → `~/Library/Logs/MDTool/ai-worker.log` (macOS) / `%APPDATA%\MDTool\logs\` (Windows).
- Per-op metric events (`op_started`, `source_latency`, `source_degraded`, `accepted_blocks`, `rejected_blocks`, `memento_written`). Local only; opt-in anonymized upload to nyxCore in iteration 2.
- Settings → "AI Worker Status" exposes health, last 20 ops, latency breakdown.
- Crash recovery: pre-stream `op-state.json` in `~/.mdtool/ops/` enables "last op was interrupted — discard or restart?".

## 8. Testing Strategy

### Sidecar (Node)
- **Unit (vitest):** every adapter with mocked external clients. Required assertions: trust tagging correct, token estimate honest, timeout triggers fallback.
- **Contract tests:** recorded fixtures per MCP source (happy / auth-expired / network-fail). Runs in CI without live connection.
- **Orchestrator property-based (fast-check):** N random chunks → ranking respects hierarchy + never blows token budget.
- **Prompt-injection fixtures:** known patterns (`"Ignore previous"`, `"</external_context>"`, BOM tricks, Unicode look-alikes). Re-run on every provider/model bump.
- **Streaming-replay:** real SSE fixtures feed the renderer; cancel-path must take effect within 500ms.

### Flutter
- **Widget tests:** toolbar position/visibility, diff-renderer block granularity, tab navigation, Cmd+Z undo, axiom squiggle colors.
- **Integration tests** with mock sidecar (local test RPC server): full refine flow, mid-stream cancel, memento confirmation.
- **Golden tests** for squiggle rendering — pixel-diff on known examples.
- **A11y tests:** screen-reader on tooltips, keyboard-only path complete (no mouse-only feature).

### E2E
- **Smoke suite** (`integration_test/`): app start → sidecar connected → auto-detect → refine → accept → frontmatter updated.
- **Live (`MDTOOL_E2E_LIVE=1`)**: nightly against staging nyxCore + Notion test workspace + test repo. Guards against MCP spec drift.
- **Multi-provider matrix:** same op against Claude/OpenAI/Ollama; tests format compliance + latency SLO, not wording.

### Explicitly NOT tested
- AI output wording (brittle, meaningless). Memento accept-rate is the live quality signal.
- MCP servers themselves (they have own suites; we test our adapter).
- Persona voice verbatim (personas evolve).

### CI

```
PR (≤4 min): sidecar unit + contract + injection fixtures · flutter analyze + widget + golden · build matrix mac-arm64/mac-x64/win-x64

Nightly (~25 min): E2E live · multi-provider matrix · sidecar bundle-size cap 80 MB
```

## 9. Phased Delivery Roadmap

Each phase is independently usable — no phase-2-breaks-phase-1 risk.

### Phase 1 — Foundation & Sidecar (≈3 weeks)
> MDTool refines text with Claude, knows its doc frontmatter, but no external sources yet.

- Sidecar skeleton: RPC server, health, Anthropic SDK client
- Flutter RPC bridge + bundling setup (pkg or nexe) for macOS + Windows
- Frontmatter manager + sidecar schema validation
- Selection-toolbar with Phase-1 ops only (Refine, Shorten, Translate) + right-click menu. *Refine+Knowledge, Tone, Compare arrive in later phases since they require personas / external sources / opt-in dual variants.*
- Streaming-diff renderer with per-block accept/reject (during stream) + atomic Cmd+Z undo of the committed op
- Settings panel v0: provider keys (Keychain), sidecar status, logs

### Phase 2 — nyxCore + Memento (≈2 weeks)
> MDTool knows your projects + personas; learns from accepted edits.

- `KnowledgeSource` interface + nyxCore adapter
- Auto-detect service (project/persona from doc content)
- "Refine + Knowledge" menu item (uses nyxCore only)
- Persona-picker in auto-detect dialog
- Memento writer + local buffer + opt-out
- Trust-wrapping layer built here (no external content existed in Phase 1, so the layer arrives with the first external source)
- Persona-driven "Tone" operation lands in selection-toolbar (now that personas are reachable)

### Phase 3 — Notion + GitHub (≈2 weeks, parallelizable with phase 4)
> External sources in refine loop; trust tags visible.

- Notion-MCP adapter
- GitHub adapter (Octokit, repo allowlist in settings)
- Provider fallback chain (claude → openai → ollama)
- Cael compare mode (Alt-click) — opt-in dual variant
- Pre-op cost estimate for compare

### Phase 4 — Axiom Linter (≈3 weeks, parallelizable with phase 3)
> Style enforcement, not just on-demand improvement.

- Axiom adapter with authority + domain filters
- Live validation in sidecar (debounced 300ms)
- Inline squiggles in 3 authority colors + hover tooltip + "Refine fixes this"
- Bulk panel (Cmd+Shift+V)
- Snooze mechanic per axiom match

### Phase 5 — Polish & Iteration-2 prep (≈2 weeks)
> Stabilize, observability, foundation for inline ghost-completion.

- Privacy modes (`ollama-only`, `nyx.private: true`)
- Observability status page in settings
- Crash recovery for interrupted ops
- Auto-detect refinement using memento data
- Foundation for inline ghost-completion (iteration 2)

### Total
- Sequential: ≈12 weeks
- With phase 3 + 4 parallel (different subsystems): ≈9 calendar weeks at 2 devs.

## 10. Persona Contributions

To honor the request to consult personas and their skills, this design was shaped by:

- **Nefilibata (Dream Cartography, Cross-Product Synthesis Arc)** — surfaced the inline streaming-diff as "the feature that wants to exist next" and the per-document context sidecar as the cross-product bridge between editor and knowledge base.
- **Aristaeus (Product Vision Crystallization, Pre-Mortem Problem Surfacing)** — named the User Truth ("AI text tools sound like ChatGPT, not like me or my project"), defined the wedge (one primitive: refine-with-context), and ran the pre-mortem that produced the failure matrix.
- **Ipcha Mistabra (Talmudic Inversion Stress Test)** — flagged the five existential risks (feature overload, latency hell, trust collapse, modal-tool theatre, MCP repick tax) that drove the streaming-diff, auto-detect, and selection-toolbar choices.
- **Harmonia (Interaction Pattern Recommendation, Usability Heuristic Evaluation)** — defined the affordance hierarchy (toolbar for power, right-click for discovery, panel for bulk) and the authority-coded squiggle styling.
- **Cael (Output Comparison)** — gave the compare-mode its name and the dual-variant pattern.

Each phase of the roadmap should still consult the relevant persona before implementation:
- **Nemesis** (security review): Phase 1 (sidecar transport), Phase 2 (Memento privacy boundary), Phase 4 (Axiom linter false-positive class).
- **Athena** (architecture review): Phase 1 (RPC API contract), Phase 5 (foundation for ghost-completion).
- **Aletheia** (compliance / privacy): Phase 2 (Memento doc-content write-back).
- **Themis** (regulatory): Phase 5 (telemetry opt-in design).

## 11. Open Questions / Decisions Deferred

| Topic | Deferred to | Why |
|---|---|---|
| Token-budget defaults (8k for knowledge block) | Phase 1 implementation tuning | Empirical; depends on actual prompt sizes |
| Memento insight schema (exact fields) | Phase 2 design refinement | Needs alignment with nyxCore consolidation pipeline |
| Settings UI exact layout | Phase 1 UI iteration | Will use Harmonia component-API review on first cut |
| Iteration 2 ghost-completion debouncing | Iteration 2 design pass | Premature without Phase 1 telemetry |

## 12. Non-Goals

- This spec does not commit MDTool to becoming a "writing platform" — it adds a context-aware enhancement layer to the existing editor.
- No replacement of MDTool's current chat panel, AI analytics, or context strategies (`lib/core/services/ai/`). The new operations route through the existing `ai_routing_manager` where possible.
- No vendor lock-in to Claude — the provider chain stays multi-vendor.
- No changes to MDTool's existing file association, PDF export, diff viewer, or graph visualization features.

---

**Next step:** writing-plans skill produces the executable plan after user approval of this spec.
