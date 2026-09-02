# Notifications and attention

Status: proposed, 2026-09-01. Slice 1.

A user unit, `omarchy-agent-session-watch.service`, mirrors the shape of `omarchy-crash-watch.service`: `WantedBy=graphical-session.target`, `Restart=always`, running `bin/omarchy-agent-session-watch`.

```
[Unit]
Description=Omarchy agent session notifier
After=graphical-session.target

[Service]
ExecStart=%h/.local/share/omarchy/bin/omarchy-agent-session-watch
Restart=always

[Install]
WantedBy=graphical-session.target
```

The watcher opens Herdr's `events.subscribe` (filtered to `pane.agent_status_changed`) as a low-latency nudge, and tails every session's `events.jsonl` under `~/.local/state/omarchy/sessions/*/`, since only that local log carries the Omarchy-only event types (`child.completed`, `status.changed` to `orphaned`) that Herdr never sees. The local log is authoritative for what to notify; the Herdr subscription only wakes the tail loop sooner than a plain poll would.

## What notifies

| Event | Notify | Urgency |
|---|---|---|
| `status.changed` to `waiting` | yes | normal |
| `status.changed` to `blocked` | yes | normal |
| `status.changed` to `done` | yes | low |
| `status.changed` to `failed` | yes | critical |
| `status.changed` to `orphaned` | yes | critical |
| `child.completed` (to the parent's owner) | yes | low |
| `status.changed` to `working` | no | n/a |
| `status.changed` to `idle` | no | n/a |
| `instruction.delivered` | no | n/a |

`waiting` and `blocked` are the two states `01-session-model.md` says the panel counts and the notifier announces; they are routine multi-agent traffic, so they stay at `normal`. `failed` and `status.changed` to `orphaned` are anomalies and get `critical`, matching the existing crash path. `done` and a completed child are good news, not a request, so they stay `low`. Urgency maps directly to `omarchy-notification-send --urgency <level>`.

## Text templates

One line, name first, no separate body, so the whole notice reads at a glance:

| Event | Text |
|---|---|
| `waiting` | `<name> needs an answer` |
| `blocked` | `<name> needs approval` |
| `done` | `<name> finished` |
| `failed` | `<name> failed: <detail>` |
| `status.changed` to `orphaned` | `<name> lost its pane` |
| `child.completed` | `<parent_name>: <child_name> finished (<state>)` |

Click action on every one of these: `omarchy-notification-send ... --exec omarchy-agent-session open <id>`, so acting on a notification always opens that session's own terminal, never a list to search through.

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
