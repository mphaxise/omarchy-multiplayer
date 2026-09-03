# Notifications and attention

Status: proposed, 2026-09-01. Slice 1.

A user unit, `omarchy-agent-session-watch.service`, mirrors the shape of `omarchy-crash-watch.service`: `WantedBy=graphical-session.target`, `Restart=always`, running `bin/omarchy-agent-session-watch`.

```
[Unit]
Description=Omarchy agent session notifier
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/omarchy-agent-session-watch
Restart=always

[Install]
WantedBy=graphical-session.target
```

The unit as built (`systemd/omarchy-agent-session-watch.service`) runs from `~/.local/bin`, where the install links every command, and adds `PartOf=graphical-session.target` and `RestartSec=2`; the rig has run it that way since 2026-09-02.

The watcher opens Herdr's `events.subscribe` (filtered to `pane.agent_status_changed`) as a low-latency nudge, and tails every session's `events.jsonl` under `~/.local/state/omarchy/sessions/*/`, since only that local log carries the Omarchy-only event types (`child.completed`, `status.changed` to `orphaned`) that Herdr never sees. The local log is authoritative for what to notify; the Herdr subscription only wakes the tail loop sooner than a plain poll would.

## What notifies

| Event | Notify | Urgency |
|---|---|---|
| `status.changed` to `waiting` | yes | normal |
| `status.changed` to `blocked` | yes | normal |
| `status.changed` to `done` | yes | low |
| `status.changed` to `failed` | yes | critical |
| `status.changed` to `orphaned` | yes | critical; normal when `data.detail` is exactly `Herdr server not running` |
| `child.completed` (to the parent's owner) | yes | low |
| `status.changed` to `working` | no | n/a |
| `status.changed` to `idle` | no | n/a |
| `instruction.delivered` | no | n/a |

`waiting` and `blocked` are the two states `01-session-model.md` says the panel counts and the notifier announces; they are routine multi-agent traffic, so they stay at `normal`. `failed` and `status.changed` to `orphaned` are anomalies and get `critical`, matching the existing crash path. One exception, from the live desktop (2026-09-02): when the reconciler orphans sessions because Herdr itself is unreachable (its `detail` is `Herdr server not running`, typically right after a reboot), every bound session is orphaned at once and the panel already carries a Herdr-down row for the outage, so those notices go out at `normal`; one critical toast per session would mean relaunching every agent just to clear the corner. Any other detail (`pane not found in Herdr's list`) is one agent dying behind the person's back and stays `critical`. `done` and a completed child are good news, not a request, so they stay `low`. Urgency maps directly to `omarchy-notification-send --urgency <level>`.

## Text templates

Title first, name first in the title, so the notice reads at a glance. The build adds a body line, `<agent> · <goal first line or branch> · <what a click does>`, and the sessions glyph, after the rig showed the title-only toast next to Omarchy's own crash toast with its icon and second line (2026-09-02). The words were revised the same day after a review on the live desktop: Herdr reports a question and a permission prompt both as `blocked`, so `waiting` and `blocked` share one title instead of guessing which (they stay distinct kinds inside the watcher); `failed`'s detail moves into the body to keep the title short; "lost its pane" was Herdr vocabulary that read as the window the person closed on purpose.

| Event | Title | Body |
|---|---|---|
| `waiting` | `<name> needs you` | `<agent> · <goal or branch> · Click to open and answer` |
| `blocked` | `<name> needs you` | `<agent> · <goal or branch> · Click to open and answer` |
| `done` | `<name> finished` | `<agent> · <goal or branch> · Click to open the receipt` |
| `failed` | `<name> failed` | `<agent> · <detail, or unknown error> · Click to open` |
| `status.changed` to `orphaned` | `<name> stopped unexpectedly` | `<agent> · <goal or branch> · Click to revive, same conversation` when `agent.harness_session_ref` is set, else `... · Click to revive, fresh conversation` |
| `child.completed` | `<parent_name>: <child_name> finished (<state>)` | `<agent> · <goal or branch> · Click to open` |

Click action: `done` and `failed` leave the session in a terminal state, where `session open` exits 5 with no pane to attach, so their click runs `omarchy-launch-tui --app-id=org.omarchy.session-receipt omarchy-agent-session-receipt --pager <id>` and shows the receipt the body promised; the same target applies to any notice whose session record already reads `done`, `failed`, or `stopped` by the time the event is tailed. Every other notice runs `omarchy-agent-session-open <id>`, so acting on it opens that session's own terminal (or, for `orphaned`, revives it), never a list to search through.

## Coalescing and self-suppression

One pending notice per session. A newer notify-worthy event for the same session inside 10 seconds of the last one replaces it instead of stacking a second toast (via Notify's `replaces_id`; whether `omarchy-notification-send` exposes that itself or the watcher must call `org.freedesktop.Notifications.Notify` directly for it is verify on rig).

Suppress entirely when that session's own terminal window is the focused Hyprland window: detect via `hyprctl activewindow -j` and compare its app id to `org.omarchy.session.<id>` (verify on rig: exact JSON field and match behavior). A user already looking at the session is already looking at what the notification would announce.

## Quiet hours: fullscreen

When the focused window is fullscreen (via `hyprctl activewindow -j`; exact field and truthy values verify on rig), hold notices and flush them once fullscreen ends. This keeps a game or a video free of toasts while still delivering the information as soon as it is safe to show.

## Digest

If a fourth notify-worthy event inside a rolling 60-second window would otherwise fire a fourth separate notice, suppress the individual notices from that point and send one summary instead, naming counts by kind: `4 sessions need you: 2 waiting, 1 blocked, 1 failed`. Its click action opens the session list, since no single session id applies (`omarchy-agent-session list`; wiring it straight to the bar panel's own popup is a later refinement, verify on rig). The 60-second counter resets once a full window passes with no further notice.

## Recovery after restart

The watcher persists, per session, the `seq` / `state_version` it has already acted on. On restart it re-subscribes to Herdr fresh, since the socket carries no history, and replays each session's `events.jsonl` from its saved cursor forward, so a notice is never skipped or repeated across a restart.

## Bar widget versus notification

The bar widget is peripheral awareness: it shows a count of sessions in `waiting` or `blocked` (the same two states the JSON `needs_attention` field in `02-command-surface.md` marks true), hidden at zero like the existing agents-plugin pattern, refreshed from the same local files with no polling of Herdr. A notification is an interruption: it names exactly one session and one reason. The widget answers "is anything happening"; a notification answers "which one, right now."

## Why these rules

Horvitz 1999, cost of interruption: notifying only on `waiting`/`blocked`/`done`/`failed`/`orphaned`, never on `working`/`idle`, weighs the interruption against the value of the information it carries. Iqbal & Horvitz 2007, resumption cues: the `open <id>` click action drops the user back into the exact session instead of a list, cutting the cost of resuming what they were doing. Mark et al. 2005, interruption digests: the more-than-three-a-minute rule trades individual precision for a bounded number of interruptions. McFarlane & Latorella 2002, delivery modes: urgency and timing are matched to the event, from a held fullscreen-safe low-urgency note to an immediate critical one for `failed` or `orphaned`. Gutwin & Greenberg 2002, workspace awareness elements: the template's name-state-since fields and the widget's separate count split who/what/when across the peripheral channel and the interrupting one.

## Verify on rig

- Whether `omarchy-notification-send` exposes a replaces-id flag, or the watcher needs a direct `busctl` call for coalescing.
- The exact `hyprctl activewindow -j` field and value for matching `org.omarchy.session.<id>` as the focused window.
- The exact fullscreen field and truthy values in `hyprctl activewindow -j`.
- Whether `omarchy-notification-send --urgency` accepts `low` and `normal` the same way it accepts the already-confirmed `critical`.
- Whether a direct bar-panel-popup click action is reachable from a notification `--exec`, versus falling back to `omarchy-agent-session list`.

## Sources

`01-session-model.md` for the event types (`status.changed`, `child.completed`, `status.changed` to `orphaned`, `instruction.delivered`) and `state_version`. `02-command-surface.md` for the `needs_attention` field and `session open`. Omarchy `omarchy-crash-watch.service`, `omarchy-notification-send`, and its `--exec`/`--urgency` flags on branch quattro. Herdr Socket API page at herdr.dev/docs (observed 2026-09-01) for `events.subscribe` and `pane.agent_status_changed`. CSCW findings per the verified bibliographic list in the context pack: Horvitz 1999 (cost of interruption); Iqbal & Horvitz 2007 (resumption cues); Mark et al. 2005 (interruption digests); McFarlane & Latorella 2002 (interruption delivery modes); Gutwin & Greenberg 2002 (workspace awareness elements: who, what, where, when, next).
