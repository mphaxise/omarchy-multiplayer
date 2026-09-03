# Sessions panel

Status: proposed, 2026-09-01. Slice 1. Builds on the session record, state machine, and reconciler in `01-session-model.md`.

The panel is a user shell plugin named Keepalive, id `io.github.mphaxise.keepalive` (renamed 2026-09-02 from `praneet.agent-sessions`, the id the experiment used until the listing was prepared; the marketplace makes ids permanent, so the dev checkout and the rig now carry the listing id). Its only kind is `bar-widget`. Entry point `Panel.qml` holds the bar icon and the popup surface. `Main.qml` holds the data: the process, the timer, the FileView, and the derived section lists. `Session.qml` is one row, instantiated per session. This mirrors the entry, data, and row split the `omarchy.agents` plugin uses.

## Manifest and layout

```json
{
  "schemaVersion": 1,
  "id": "io.github.mphaxise.keepalive",
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
~/.config/omarchy/plugins/io.github.mphaxise.keepalive/
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
| `doneRowsCollapsed` | integer | 2 | 0-20 |
| `motion` | string | `full` | `full` or `reduced`; `reduced` replaces the stop spinner with a static glyph |

`refreshIntervalSec` governs the reconciliation poll, not the panel's responsiveness; see Data below for why 10 s is safe.

## Data

Two sources. No event push yet.

Primary: a Timer drives a `Quickshell.Io.Process` running `omarchy-agent-session list --ended-within 24h --json` (through `scripts/snapshot.sh`). This is the reconciliation path, authoritative but only as fresh as the last tick. The window is the panel's, asked for by the panel: the store keeps every record (`01-session-model.md`, Retention), and without the window the payload carried all of them, 53 KB for 52 records on 2026-09-03 against the 64 KB cap below, one evaluation run short of the panel showing an error row instead of sessions. The payload's `window.earlier_ended` is how the panel knows how much history sits outside the day it shows.

```qml
Process {
    id: listProc
    command: ["omarchy-agent-session", "list", "--ended-within", "24h", "--json"]
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

The reconciler (every 5 s from the watcher, and on every Herdr nudge) rewrites `~/.local/state/omarchy/sessions/index.json` atomically at the end of every run, on both its paths: `{"generated_at", "herdr": "running" | "unreachable", "orphaned": [...], "adopted": [...], "counts": {"needs_attention", "live", "orphaned"}}`. The panel uses `generated_at` as its liveness signal (stale after twice `refreshIntervalSec`) and `herdr` for the Herdr-down row; session rows come from `list --json`, never from the index. Built and verified on the rig 2026-09-02.

Event push, an `events.subscribe`-style stream from Herdr or a state-version cursor like OpenClaw's, would remove polling entirely and would satisfy PLAN.md success signal 4 in full. It is a later refinement. Slice 1 ships Timer plus Process plus FileView only; that is stated plainly here.

## Bar widget

A single agent glyph plus a badge counting sessions in `waiting` or `blocked`. Color follows a strict order, most urgent condition wins:

| Condition | Color |
|---|---|
| any session `blocked` or `waiting` | `Color.urgent`, with the badge |
| none of those, any `orphaned` | `Color.foreground`, no badge: a person is needed, nobody is asking |
| otherwise | `Qt.darker(Color.foreground, 1.5)`, 3.82:1 on Tokyo Night |

`Color.muted` (1.91:1 on Tokyo Night) is decoration only and the panel never uses it for a state. Revised 2026-09-02 after the review pass; the earlier three-way `blocked` / `waiting` / `muted` scheme could not fire its middle state because Herdr reports both as `blocked`, and its rest state failed 3:1.

Hidden entirely when there are no sessions in the payload, no ended sessions outside its window (`window.earlier_ended` is 0), and `showWhenEmpty` is false: a fresh install. The agents plugin and the Hermes plugin hide when nothing is running; this one stays once a record exists, because a bar icon that vanishes with the last live session reads as the sessions being gone, and on 2026-09-03 that is what it read as. In that quiet state the glyph is the rest color and the hero says "Nothing running" over "<n> earlier · e history · n new".

Clicks: left toggles the panel through the popup's own `PanelController`. Right runs `Quickshell.execDetached(["omarchy","agent","session","new","--pick"])`. Middle opens the session most recently needing attention: sort blocked before waiting, then by most recent `status.since` within each group, and open the first result the same way Open does.

## Panel layout

`Panel.qml` opens a `KeyboardPanel` anchored to the bar button. Inside: a `PanelHero` naming the top "needs you" session, or the working count when there is none, then four sections separated by `PanelSeparator`, each under a `PanelSectionHeader`:

1. **Needs you**: `waiting`, `blocked`. Blocked before waiting, oldest `since` first within each group, so the longest-neglected session leads. The first row is set larger than every other row (the measurement hook below).
2. **Orphaned**: `orphaned`, newest first. Above Working because a session that lost its pane is the state this product exists to protect; the hero and the glyph count it.
3. **Working**: `starting`, `working`, `idle`. Alive, asking for nothing.
4. **Done today**: `done`, `failed`, `stopped` in the last 24 h, newest first, collapsed to `doneRowsCollapsed` rows with the count in the header ("DONE TODAY · 19") and "17 more · →"; the right arrow expands, the left arrow collapses. Older sessions leave the panel and keep their record; under the last section a footer line, "31 earlier · e", says how many ended before the window and that `e` opens History (a click does the same). History is `omarchy-agent-session-history --pager` in a TUI window, the way Receipt is (`02-command-surface.md`): fourteen days grouped by day, with the receipt and resume commands named at the foot. The footer is absent when nothing ended before the window.

Each row is two lines at rest: a state dot, the name, and the state with its age on the right ("needs you · 7m" in urgent, "orphaned · resumes conversation" or "orphaned · fresh start" from the resume ref, "idle · 3m", "stopped · 1h 24m"); then the goal's first line, or project · branch when there is no goal, with the permission mode on the right (`shared` and `restricted` in accent, `personal` dim). The cursor row grows a third line of actions. Dots carry shape as well as color: filled urgent for needs-you, a foreground ring for orphaned, an urgent ring for failed, a filled rest-color dot otherwise; a small outlined dot beside the state text marks a heuristic status.

Row actions, using `Button`, shown on the cursor row only:

| Row state | Buttons | Keys |
|---|---|---|
| live (`starting`, `working`, `idle`, `waiting`, `blocked`) | ⏎ Open (⏎ Answer when it needs you), s Send, x Stop | Enter, `s`, `x` |
| `orphaned` | ⏎ Revive, s Send (queued, delivered on revive), x Stop | Enter, `s`, `x` |
| ended (`done`, `failed`, `stopped`) | ⏎ Receipt | Enter, `r` |
| ended and `revivable` (an inferred end, or a stop, with a transcript) | ⏎ Revive on an inferred end, ⏎ Resume on a stop; r Receipt | Enter, `r` |
| any row with a registered preview | p Preview, added after Send | `p` |
| the starter row under the hero (no session needed) | New session…, which becomes a field with a Start button | `n` |

A row with a registered preview (`09-closed-loop-surfaces.md` section 7) changes two more things: its Send field says "Feedback on the preview (a capture goes with it)…" and runs `send --with-capture`, closing the panel first so the capture shows the preview and not the panel over it (the command starts 400 ms after the close; a failure that nobody can see goes out as a toast, and a delivery shows on the row's loop count the next time the panel opens); and its second line leads with the loop count, `<n> instructions, <m> captures`, ahead of the goal, so a long goal cannot elide it. `p` and the Preview button run `preview --focus`, which focuses the window or launches it for a URL, and close the panel on exit 0. Verified on the rig 2026-09-02 (run 4, `captures/evaluation-run4-panel-loop_hands-on_arm-port_2026-09-02/`).

Every action runs through a `Process` (never `execDetached`) and reports its exit code into the row's state slot for five seconds: `open` closes the panel on exit 0 and otherwise says "couldn't open · Herdr is not running" (4) or "· the session's state forbids it" (5); `send` says "sent" or "not delivered · open it and answer there" (5); a failed `stop` clears the spinner and says why; the receipt opens `omarchy-agent-session-receipt --pager <id>` in `omarchy-launch-tui`. Stop is two presses: the first arms the label ("x Confirm stop (+1 child)" when children would stop too), the second executes; moving the cursor disarms it; while the stop runs the row shows a spinner and "stopping…" until the record reports a terminal state.

Starting a session from the panel (built 2026-09-02 at Praneet's request, run 5 in `captures/evaluation-run5-start-from-panel_…/`): one row sits under the hero and reads "n  New session in ~/Work…" at rest. `n`, a click on it, or a right click on the bar icon turns it into a text field with a Start button; the legend changes to "⏎ starts it in ~/Work · esc cancels". Enter runs `scripts/new-session.sh "<text>" <dir> <mode>`, which takes the default agent from `omarchy-default-agent`, creates the session in the configured directory with the text as the first prompt (an empty text starts the agent with no prompt), and opens its terminal; on exit 0 the panel closes and the row appears on the next poll. A failure shows beneath the field: no default agent (exit 6, with the `omarchy default agent <name>` hint), directory missing (exit 7), or the `new` and `open` codes. Two manifest settings: `newSessionDir` (`~/Work`) and `newSessionMode` (`personal`). The empty state says "No sessions yet. Press n, or click above, to start one." on a fresh install, and "Nothing running. 31 ended earlier: e opens History. n starts one." once records exist outside the window.

Keyboard: up/down move the cursor, which is a session id, so a list that re-sorts keeps it on the same session and the cursor row scrolls into view; Enter opens (or revives, resumes, or opens the receipt); `s`/`x`/`r` act on the cursor row; right/left expand and collapse Done today; `e` opens History whether or not a row is under the cursor (`h` would read as "history" and is taken: `PanelKeyCatcher` turns h, j, k, and l into arrows before a text key is seen, run 9), and stays off the legend because the "N earlier · e" footer names it, the way `r` stays off because the ended rows' own button does; Esc clears an open Send field or an armed Stop first and closes the panel on the press after that. While a Send field is open the other keys are the field's. A key legend under the list names the keys ("↑↓ move · ⏎ open · s send · x stop · → more · esc"; "n new" is always there, "p preview" joins when the cursor row has one, and the legend holds six entries at most in priority order, "→ more" and esc giving way first, because a seventh entry elided "→ more" on the rig; the Done today header carries "N more · →" anyway) and changes while Stop is armed ("x again stops <name> · esc cancels") or a field is open ("⏎ sends · esc cancels"). Hovering a row moves the cursor to it, so keyboard and mouse share one highlight. Spacing, type, and color all come from `Style.space()`, `Style.font.*`, and `Color.*`.

Bindings on the rig (provisional, free on this image): `Super+Ctrl+G` toggles the panel, `Super+Ctrl+Shift+G` opens the agent that needs you (`omarchy-shell io.github.mphaxise.keepalive openMostUrgent`); the same IPC target also answers `open`, `close`, `toggle`, and `refresh`.

Gutwin and Greenberg's workspace awareness elements, mapped to fields already on the row:

| Element | Field |
|---|---|
| Who | permission mode (what the agent may do alone); the owner label returns with slice 2, when there is more than one person |
| What | goal first line, current state |
| Where | project · branch when there is no goal; the branch as a tooltip |
| When | since-duration |
| Next | needs-you state and the ⏎ Answer / ⏎ Revive label; "waiting for child" is slice 2 |

## States and empty states

No Herdr running: the reconciler's `index.json` says `herdr: unreachable`, and the panel shows one row under the hero, "Herdr is not running. Super+Ctrl+Return starts it; a session revives with Enter once it is up."; the hero reads "N orphaned · Herdr is not running · Enter revives"; the panel does not try to start it. The row shows only while the index is fresh, since a stale index means the reconciler stopped and its last word on Herdr is a guess. No sessions: an empty-state message plus a New button running the same command as the bar's right click, matching the Hermes plugin's New Session button. Reconciler stale: when `now - index.generated_at` exceeds twice `refreshIntervalSec`, the `PanelHero` carries a small muted "stale" marker with the age, shown as text and shape, not color alone. Heuristic status: a row whose `status.source` is `herdr-manifest`, the heuristic path, shows a small outlined dot beside the state text; its tooltip reads "status inferred from on-screen text; no lifecycle hook available."

## Accessibility

Every text color the panel chooses pairs against the popup background at 4.5:1 or better, and every state dot and the bar glyph at 3:1 or better (WCAG 1.4.11). Verified on the rig, 2026-09-02, against Tokyo Night: `Qt.darker(foreground, 1.55)` gave 3.60:1 and failed; 1.3 gives 4.89:1 and is what the build uses; `Color.muted` is 1.91:1 and may only decorate. The shell's own section headers and hero meta use 1.4 (4.28:1), which is the shell's call. The stale marker and the low-confidence dot use shape and text, never color alone, so they hold under any contrast condition. Every action control is at least 28 px tall, the measured height of the row buttons; `Style.space(px)` is px times the spacing scale, so an earlier floor of `Style.space(4)` meant 4 px and guaranteed nothing. The buttons are sized for a pointer; touch is out of scope for slice 1. Every action already has a letter key, so the row is fully usable with no mouse; tab order follows the visual top-to-bottom order, and focus uses `Color.accent` and is never suppressed. The blocked-color change and any future pulsing indicator respect a reduced-motion preference where the shell exposes one; verify on rig whether it does, and cap to a single sub-150 ms opacity change with no pulsing loop if not. What `/design-qa` checks: contrast per state color pair, tab order against the visual order, minimum hit target size, and whether motion can be turned off.

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
