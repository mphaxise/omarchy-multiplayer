# Slice 1 architecture

Status: proposed, 2026-09-01. Slice 1. Read this first; each numbered file below owns one part.

## The shape

```
 keybinding / menu / panel / CLI          (entry points)
            |
   omarchy-agent-session-*                 (bin/: new, list, show, open, send, stop, ...)
            |                 \
   session records             Herdr socket API   (herdr: panes, agent status, worktrees, events)
   ~/.local/state/omarchy/     |
     sessions/<id>/            harness in a Herdr pane  (claude, codex, opencode, ...)
     session.json              |
     events.jsonl              terminal window attaches (app id org.omarchy.session.<id>)
     receipt.json
     artifacts/
            |
   omarchy-agent-session-watch.service    (systemd user unit: events -> notifications, reconciler)
            |
   praneet.agent-sessions shell plugin    (bar widget + panel, reads list --json and index.json)
```

Herdr keeps the process alive and reports what the agent is doing. Omarchy scripts own the session record, the mode, the lineage, the receipt, and the artifacts. The shell plugin renders the record. The watcher turns events into notifications and keeps records and panes reconciled.

## What each part owns

| Part | Owns | File |
|---|---|---|
| Session model | record, actors, state machine, events, lineage, receipt shape, invariants | `01-session-model.md` |
| Command surface | the `omarchy agent session` commands, JSON output, Herdr calls, the marker line | `02-command-surface.md` |
| Sessions panel | the shell plugin: widget, panel, rows, actions, keyboard, states | `03-sessions-panel.md` |
| Permission modes | personal, shared, restricted; harness flag table; the bypass deny list | `04-permission-modes.md` |
| Receipts and artifacts | receipt computation, artifacts directory, capture, rendering | `05-receipts-and-artifacts.md` |
| Notifications | the watcher unit, which events notify, coalescing, self-suppression, digests | `06-notifications.md` |
| Workspaces and worktrees | when a worktree is created, where, branch naming, cleanup, sharing | `07-worktrees.md` |
| Identity and attribution | actor ids, creator, owner, participants, reserved slice-2 shape | `08-identity-and-attribution.md` |
| Closed-loop surfaces | goal template, preview, captures, loop view, verdict, design artifacts | `09-closed-loop-surfaces.md` |
| Evaluation plan | the five signals as protocols, review passes, verdict rule | `10-evaluation-plan.md` |

## Principles the spec follows

1. Show state peripherally, before the panel opens.
2. Build every status view from who, what, where, when, and next.
3. Let the same session look different on different surfaces.
4. Log coordination as typed, inspectable events.
5. Time a notification to the task it would interrupt.
6. Mark every automated reading with its own confidence.
7. Keep a manual path beside every automated one.
8. Name every actor and never erase history.

The evidence behind each is in `findings/cscw-insights.md`.

## Slice map

| Slice | Relationship | What lands |
|---|---|---|
| 1 | one user, many agents | this spec set |
| 2 | user to agent control, and a second person | visibility, access list, suggest, approval ledger, presence; OpenClaw gateway spike at this gate |
| 3 | agent to agent | delegation protocol on the marker line, structured results, isolated agent identities |
| 4 | user to user across machines | remote placement, federation; A2A stays out of scope |

## What is proposed and what is live

Everything in `spec/` is proposed until the rig runs it. Each file ends with a "Verify on rig" list; `setup/rig-questions.md` gathers them. The first rig session revises the session model first, because every other file depends on it.
