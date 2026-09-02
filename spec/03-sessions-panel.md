# Sessions panel

Status: proposed, 2026-09-01. Slice 1. Builds on the session record, state machine, and reconciler in `01-session-model.md`.

The panel is a user shell plugin, id `praneet.agent-sessions` for the experiment; the release name is a slice 2 decision. Its only kind is `bar-widget`. Entry point `Panel.qml` holds the bar icon and the popup surface. `Main.qml` holds the data: the process, the timer, the FileView, and the derived section lists. `Session.qml` is one row, instantiated per session. This mirrors the entry, data, and row split the `omarchy.agents` plugin uses.

## Manifest and layout

```json
{
  "schemaVersion": 1,
  "id": "praneet.agent-sessions",
  "name": "Agent Sessions",
  "version": "0.1.0",
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "Panel.qml" },
  "barWidget": {
    "displayName": "Agent Sessions",
    "category": "AI",
    "allowMultiple": false,
    "defaultSection": "right",
    "defaults": {
      "refreshIntervalSec": 10,
      "showWhenEmpty": false,
      "maxRows": 20
    },
    "schema": {
      "refreshIntervalSec": { "type": "integer", "min": 5, "max": 120 },
      "showWhenEmpty": { "type": "boolean" },
      "maxRows": { "type": "integer", "min": 5, "max": 50 }
    }
  }
}
```

Directory, no symlinks anywhere in it, per `omarchy plugin validate`:

```
~/.config/omarchy/plugins/praneet.agent-sessions/
  manifest.json
  Panel.qml          entry: bar icon + popup surface
  Main.qml           data: process, timer, FileView, derived lists
  Session.qml        one row
  scripts/
    view-receipt.sh  vendored copy; pretty-prints and pages a receipt
```

`scripts/view-receipt.sh` is a copy, not a link, of the script the omarchy-multiplayer repo ships for terminal use. A change to the shared version needs a manual re-vendor; that cost is what `omarchy plugin validate` charges for banning symlinks.

| Setting | Type | Default | Bounds |
|---|---|---|---|
| `refreshIntervalSec` | integer | 10 | 5-120 |
| `showWhenEmpty` | boolean | false | - |
| `maxRows` | integer | 20 | 5-50 |

`refreshIntervalSec` governs the reconciliation poll, not the panel's responsiveness; see Data below for why 10 s is safe.

## Data

Two sources. No event push yet.

Primary: a Timer drives a `Quickshell.Io.Process` running `omarchy-agent-session list --json`. This is the reconciliation path, authoritative but only as fresh as the last tick.

```qml
Process {
    id: listProc
    command: ["omarchy-agent-session", "list", "--json"]
    stdout: SplitParser { onRead: data => Sessions.ingest(data) }
}
Timer {
    interval: settings.refreshIntervalSec * 1000
    running: true; repeat: true; triggeredOnStart: true
    onTriggered: listProc.running = true
}
```

Modeled on the Hermes plugin, which polls `scripts/snapshot.sh` on a 30 s Timer and parses stdout the same way.

Secondary: a `FileView` on the reconciler's index, watched for changes.

```qml
FileView {
    id: indexFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/sessions/index.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: Sessions.mergeIndex(JSON.parse(text()))
}
```

Modeled on the agents plugin, which reads its per-agent usage JSON the same way.

This spec adds one duty to the reconciler defined in `01-session-model.md`: after it appends any event to any session's `events.jsonl`, it rewrites `~/.local/state/omarchy/sessions/index.json` atomically, temp file then rename, and it also rewrites the file once per its own tick even when nothing changed. The index carries a `generated_at` field and one row per live session: `id`, `name`, `agent.kind`, `status`, `workspace.branch`, `owner`, `lineage.children.length`. `generated_at` is a liveness signal a reader checks against the wall clock; see the stale marker below. The `watchChanges` path delivers a state change inside five seconds; the Timer poll is the fallback for a missed watch.

Event push, an `events.subscribe`-style stream from Herdr or a state-version cursor like OpenClaw's, would remove polling entirely and would satisfy PLAN.md success signal 4 in full. It is a later refinement. Slice 1 ships Timer plus Process plus FileView only; that is stated plainly here.

## Bar widget

A single agent glyph plus a badge counting sessions in `waiting` or `blocked`. Color follows a strict order, most urgent condition wins:

| Condition | Color |
|---|---|
| any session `blocked` | `Color.urgent` |
| none blocked, any `waiting` | `Color.foreground` |
| all live sessions `working`, `starting`, or `idle` | `Color.muted` |

Hidden entirely when there are no live sessions and `showWhenEmpty` is false, matching the hide-when-empty behavior of both the agents plugin and the Hermes plugin.

Clicks: left toggles the panel through the popup's own `PanelController`. Right runs `Quickshell.execDetached(["omarchy","agent","session","new","--pick"])`. Middle opens the session most recently needing attention: sort blocked before waiting, then by most recent `status.since` within each group, and open the first result the same way Open does.

## Panel layout

`Panel.qml` opens a `KeyboardPanel` anchored to the bar button. Inside: a `PanelHero` naming the top "needs you" session, or the working count when there is none, then four sections separated by `PanelSeparator`, each under a `PanelSectionHeader`:

1. **Needs you**: `waiting`, `blocked`. Blocked before waiting, oldest `since` first within each group, so the longest-neglected session leads.
2. **Working**: `starting`, `working`, `idle`. Alive, asking for nothing.
3. **Done today**: `done`, `failed`, `stopped` in the last 24 h. Older ones drop off the panel; the receipt is their record.
4. **Orphaned**: `orphaned`.

Each row: name, agent glyph, state with since-duration ("blocked · 6m"), workspace branch, owner label, child count. Row actions, using `Button`:

| Action | Key / trigger | Command |
|---|---|---|
| Open (default) | Enter, or click the row | `omarchy-agent-session open <id>` via `Quickshell.execDetached` |
| Send | `s` opens an inline field; submit sends | `omarchy-agent-session send <id> "<text>"` |
| Stop | `x` or click; arms a confirm label, a second press executes | `omarchy-agent-session stop <id>` |
| Receipt | `r` or click | `scripts/view-receipt.sh <id>` inside `omarchy-launch-tui` |

Keyboard: up/down move the selection, Enter opens, `s`/`x`/`r` act on the selected row, Esc clears an armed Stop or an open Send field first and closes the panel on the second press. Spacing, type, and color all come from `Style.space()`, `Style.font.*`, and `Color.*`.

Gutwin and Greenberg's workspace awareness elements, mapped to fields already on the row:

| Element | Field |
|---|---|
| Who | owner label, agent glyph and kind |
| What | goal first line, current state |
| Where | workspace branch, worktree path (tooltip) |
| When | since-duration |
| Next | needs-you flag, or "waiting for child" when blocked on a spawned session |

## States and empty states

No Herdr running: one row, "Herdr is not running," with the existing `Super+Ctrl+Return` hint as text; the panel does not try to start it. No sessions: an empty-state message plus a New button running the same command as the bar's right click, matching the Hermes plugin's New Session button. Reconciler stale: when `now - index.generated_at` exceeds twice `refreshIntervalSec`, the `PanelHero` carries a small muted "stale" marker with the age, shown as text and shape, not color alone. Heuristic status: a row whose `status.source` is `herdr-manifest`, the heuristic path, shows a small outlined dot beside the state text; its tooltip reads "status inferred from on-screen text; no lifecycle hook available."

## Accessibility

Every state color pairs against `Color.popups.background` at 4.5:1 or better. The stale marker and the low-confidence dot use shape and text, never color alone, so they hold under any contrast condition. Row height and every action control are at least `Style.space(4)` tall, sized for pointer precision as well as touch. Every action already has a letter key, so the row is fully usable with no mouse; tab order follows the visual top-to-bottom order, and focus uses `Color.accent` and is never suppressed. The blocked-color change and any future pulsing indicator respect a reduced-motion preference where the shell exposes one; verify on rig whether it does, and cap to a single sub-150 ms opacity change with no pulsing loop if not. What `/design-qa` checks: contrast per state color pair, tab order against the visual order, minimum hit target size, and whether motion can be turned off.

## Failure isolation

`Sessions.ingest` wraps `JSON.parse` in try/catch; a failure logs one line, keeps the last good list, and never rethrows, so a malformed payload cannot throw into the Quickshell process. `Sessions.ingest` also stops accumulating stdout past 64 KB and discards the remainder before it reaches `JSON.parse`, so a runaway CLI cannot hand the parser more than the cap. Three consecutive failures, non-zero exit or parse failure, replace the list with a single error row ("Session list unavailable, retrying") and back the Timer off to 60 s; the next success restores `refreshIntervalSec` and clears the row.

## Mockup plan

Three `proposed` screens, drawn against the rig's real bar:

- `proposed_sessions-panel_widget-at-rest_2026-09-01.png`: bar icon only, muted, panel closed.
- `proposed_sessions-panel_three-sessions_2026-09-01.png`: panel open, one session in each of Needs you, Working, and Done today.
- `proposed_sessions-panel_blocked-notification_2026-09-01.png`: urgent glyph, the OS notification toast, and the panel open with the blocked row visible, in one frame.

## Measurement hook

PLAN.md success signal 1 is five seconds to identify the session waiting on the user. What the panel renders first: the bar glyph turns `Color.urgent` the instant any session is blocked, visible with the panel still closed. Opening the panel puts Needs you first with zero scroll, and its first row is the single longest-neglected blocked or waiting session, name and state-with-duration set larger than every other row. That row, not the hero line, not the count, is what a user's eye must land on first, and it is what a five-second test times.

## Verify on rig

- `omarchy-agent-session`'s exact subcommands and flags belong to `02-command-surface.md`; this file assumes `list --json`, `open`, `send`, and `stop` exist with the shapes used here.
- Whether `FileView.watchChanges` fires reliably when `index.json` is replaced by rename instead of edited in place; some inotify setups miss a rename.
- Whether `omarchy-launch-tui`'s `-e "$1" "${@:2}"` form runs a bare vendored script directly, or needs a shell wrapper.
- Whether a 10 s CLI poll stays cheap on the rig; Hermes chose 30 s for a heavier sqlite3-plus-python pipeline, and this spec assumes a lighter one.
- The `omarchy.agents` plugin's own `Main.qml` and `Session.qml` are described here from the context pack's prose and from Hermes's confirmed layout, not from a direct read of those two files.

## Sources

`context-pack.md` (2026-09-01) for the Omarchy plugin manifest schema, the bar widget contract, the FileView/Process/Timer/Instantiator patterns, and PLAN.md's success signals. `01-session-model.md` for the session record, state machine, and reconciler this file builds on. github.com/stevequinn/omarchy-hermes-sessions (fetched 2026-09-01): confirmed the flat `Panel.qml` plus `manifest.json` plus `scripts/` layout, the `refreshIntervalSec` setting with default 30 and bounds 10-600, hide-when-empty, keyboard navigation, and the New Session button this file follows. raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/omarchy.agents/manifest.json, /Main.qml, and shell/qs/Ui/Panel.qml (fetch attempted 2026-09-01, no content returned from outside the shell repo).
