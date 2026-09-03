# Session model

Status: proposed, 2026-09-01. Slice 1. Every other spec file builds on the objects and events defined here; a change here is a change everywhere.

## The object

A session is an Omarchy-owned durable record of one unit of agent work. It outlives the terminal that started it, the Herdr pane that runs it, and a reboot. It carries who started it, who is responsible for it now, what it is trying to do, where it may write, how much it may do without asking, what state it is in, and what it produced.

Herdr already keeps the process alive and reports what the agent is doing. Omarchy adds the identity, the intent, the authority, the lineage, and the receipt. Herdr's agent name is a transient alias cleared when the agent exits; the stored `agent_session` in Herdr is the harness's own resume id. The session record is the durable name that survives both.

## Record

Stored at `~/.local/state/omarchy/sessions/<id>/session.json`, written atomically (temp file, rename). One directory per session:

```
~/.local/state/omarchy/sessions/<id>/
  session.json      the record below
  events.jsonl      append-only typed event log, one JSON object per line
  receipt.json      written when the session ends; partial receipts at checkpoints
  artifacts/        captures, exports, notes attached to this session
```

`session.json` fields, all required unless marked optional:

| Field | Type | Meaning |
|---|---|---|
| `id` | string | ULID, assigned at creation, never reused |
| `name` | string | human label; editable; unique among live sessions, enforced at rename |
| `created_at` | RFC 3339 | creation time |
| `created_by` | actor | immutable creator (see actors below) |
| `owner` | `{actor, assigned_at, assigned_by}` | responsible party now; defaults to creator; reassignable |
| `participants` | list of `{actor, first_input_at, last_input_at}` | every actor whose instruction reached the session; bounded to 32 entries |
| `agent` | `{kind, harness_session_ref, version}` | harness kind (`claude`, `codex`, `opencode`, and the rest of Omarchy's list); the harness's own resume id when known; harness version string when known |
| `mode` | `personal` / `shared` / `restricted` | permission mode; see `04-permission-modes.md` |
| `workspace` | `{repo_root, worktree_path, branch, base_branch, created_by_session, worktree_removed?, worktree_removed_reason?}` | where the agent may write; the two optional fields are written at cleanup; see `07-worktrees.md` |
| `runtime` | `{backend, session, workspace_id, tab_id, pane_id, agent_id}` or `null` | binding to the live Herdr pane; `null` when no pane is bound |
| `status` | `{state, since, source, detail}` | current state; see the state machine |
| `lineage` | `{parent_id, children, spawn_reason}` | parent session when spawned by another session; children it spawned |
| `goal` | `{text, set_by, set_at}` or `null` | the durable goal, distinct from any single instruction |
| `queue` | list of instruction | instructions waiting to be delivered |
| `state_version` | integer | sequence number of the last event in `events.jsonl` |
| `labels` | list of string, optional | free tags |
| `preview` | `{kind: url | app_id, value}` or `null` | the running product this session works on; see `09-closed-loop-surfaces.md` |
| `started_with` | `{command, cwd, env_summary}` | the exact launch, for the receipt |

### Actors

Every field that records who did something uses an actor:

```
{ "kind": "human" | "agent" | "system", "id": "<string>", "label": "<display>" }
```

Slice 1 identities: `human:<username>@<hostname>` for the OS user, `agent:<session-id>` for an agent acting from its own session, `system:omarchy` for reconciler and launcher actions. Slice 2 adds gateway profile ids and verified GitHub identities without changing the shape.

Ownership assigns responsibility and nothing else. Access in slice 1 is the OS user's access. A later slice grants access separately, and the record shape leaves room for it.

### Instructions

```
{ "id": "<ulid>", "text": "...", "author": actor, "queued_at": "...", "delivery": "steer" | "followup", "origin_session": "<id>" | null }
```

`origin_session` is set when another session sent the instruction. Delivery to the harness prefixes such an instruction with a fixed marker line naming the origin session, so the model reads it as inter-agent traffic and never as the user typing. The marker text is fixed in `02-command-surface.md`.

## State machine

States: `starting`, `working`, `waiting`, `blocked`, `idle`, `done`, `failed`, `stopped`, `orphaned`.

| From | To | Trigger | Source |
|---|---|---|---|
| (new) | `starting` | `session new` | omarchy |
| `starting` | `working` | Herdr confirms the agent appeared | herdr |
| `working` | `waiting` | Herdr reports the agent is asking the user something | herdr |
| `working` | `blocked` | Herdr reports the agent needs an approval | herdr |
| `waiting`, `blocked` | `working` | an instruction or approval is delivered | omarchy, herdr |
| `working` | `idle` | Herdr reports idle with no pending question | herdr |
| `idle` | `working` | new instruction delivered | omarchy |
| any live | `done` | harness exited cleanly, or owner marks complete; the reconciler applies this when Herdr's agent list no longer has the agent while its pane lives on and the session was idle, waiting, or blocked (detail `harness exited`), except from `starting`, where the harness is still booting; the pane is closed with it | herdr, human, reconciler |
| any live | `failed` | harness exited with error; Herdr exposes no exit status, so the reconciler applies this when the agent vanished while the session was `working` (detail `harness exited while working`, run 2 on 2026-09-02); a person who kills a harness mid-turn on purpose gets `failed` too, and the receipt says why | herdr, reconciler |
| any live | `stopped` | `session stop` | human, agent, system |
| any live | `orphaned` | Herdr pane gone with no exit event; or the pane is the fresh shell Herdr opened when its server restarted after the binding (a reboot), detail "Herdr restarted; Enter revives" (rig, 2026-09-02) | reconciler |
| `orphaned` | `working` | `session open` re-binds a pane and resumes the harness session | omarchy |
| `done`, `failed` with detail "harness exited…" and a transcript | `orphaned`, then `working` | `session open` on an end the reconciler inferred, which nobody decided; the receipt from that end stays in the record (rig, 2026-09-02) | omarchy |
| `stopped` with a transcript | `orphaned`, then `working` | `session open` on a session a person stopped, detail "resumed after a stop": stop reads as "stop for now" to the person who pressed it, and the transcript is on disk, so it resumes the way an orphan does; the receipt from the stop stays in the record (decision of 2026-09-03). A `stopped` session without a transcript, and a `done` closed with a verdict, stay closed: exit 5 | omarchy |

Herdr reports `blocked`, `working`, `done`, `idle`, `unknown`. Omarchy maps Herdr `done` to `idle` when the pane is alive and to `done` when the harness process has exited, and maps `unknown` to the previous state with `status.detail = "unknown"` and a timestamp. Herdr's detection is authoritative for six harnesses with lifecycle hooks and heuristic for the rest; `status.source` records which, so the panel can show a confidence hint.

`waiting` and `blocked` are the two states that ask for a person. They are the states the panel counts, the notifier announces, and the first success signal measures.

## Events

`events.jsonl` is the source of truth for history. `session.json` is a projection of it plus mutable fields. Each line:

```
{ "seq": 17, "ts": "2026-09-10T18:04:11Z", "type": "status.changed", "actor": actor, "data": { ... } }
```

`seq` is monotonic per session; `state_version` in the record equals the last `seq`. A reader that holds a cursor can ask for events after it.

Event types in slice 1:

| Type | Data |
|---|---|
| `session.created` | the initial record |
| `session.renamed` | `from`, `to` |
| `owner.assigned` | `from`, `to`, `assigned_by` |
| `mode.changed` | `from`, `to`, `changed_by`; see `04-permission-modes.md` |
| `preview.set` | `kind`, `value` |
| `runtime.bound` | the runtime binding |
| `runtime.unbound` | reason |
| `status.changed` | `from`, `to`, `source`, `detail` |
| `goal.set` | `text` |
| `instruction.queued` | the instruction |
| `instruction.delivered` | `instruction_id`, `delivery` |
| `instruction.dropped` | `instruction_id`, `reason` |
| `child.spawned` | `child_id`, `agent.kind`, `spawn_reason` |
| `child.completed` | `child_id`, `state`, `receipt_summary` |
| `approval.requested` | `operation`, `requested_by` |
| `approval.resolved` | `operation`, `decision`, `resolved_by` |
| `artifact.added` | `path`, `label`, `added_by` |
| `receipt.written` | `receipt_summary` |
| `session.ended` | `state`, `reason` |

Notification rules, coalescing, and self-suppression read this log and nothing else; see `06-notifications.md`.

## Lineage

A session created by another session records `lineage.parent_id` and `spawn_reason`; the parent records the child in `lineage.children` and receives a `child.completed` event, delivered as a marked instruction into its queue so the parent agent learns the outcome without polling. Stopping a parent stops its children unless `--keep-children` is given, and every stop is an event on both sides. A child without a reachable parent is still a valid session; the panel shows it under the parent when the parent exists and at top level otherwise.

Depth is limited to 3 and children per session to 5 in slice 1. Both are configuration, both are enforced at `session new`.

## Receipt

`receipt.json` is written at `done`, `failed`, and `stopped`, and refreshed at checkpoints while the session runs so a crash leaves a partial receipt.

| Field | Meaning |
|---|---|
| `session_id`, `name`, `agent`, `owner`, `created_by` | identity, copied |
| `started_at`, `ended_at`, `duration_s` | timing |
| `end_state`, `end_reason` | how it ended |
| `started_with` | the exact command and working directory |
| `goal` | the durable goal at end, if set |
| `workspace` | repo, worktree, branch, base |
| `commits` | list of `{sha, subject, author}` on `branch` since `base_branch` |
| `diff_stat` | files changed, insertions, deletions, against `base_branch` |
| `dirty` | uncommitted changes present at end |
| `unpushed` | commits not on any remote |
| `artifacts` | list of `{path, label, added_by, added_at}` |
| `instructions` | count delivered, count dropped, distinct authors |
| `approvals` | count requested, approved, denied |
| `children` | list of `{id, end_state}` |
| `harness_session_ref` | the harness's own resume id, for reopening the transcript |
| `state_version` | last event seq |

The receipt answers success signal 3 in `PLAN.md`: a completed session shows workspace, branch, commits, diff summary, status, and the command that started it.

## Binding to Herdr

Omarchy creates the pane and starts the harness through Herdr's socket API, then records the returned ids in `runtime`. Omarchy subscribes to Herdr's `pane.agent_status_changed` events and writes `status.changed` events from them. When Herdr's per-agent lifecycle hooks are available for the harness, the status source is `herdr-hook`; otherwise `herdr-manifest`. Herdr's own agent name is set to the session name so the Herdr sidebar and the Omarchy panel agree. Herdr's custom state and metadata channel carries the session id so a Herdr-side view can link back.

The reconciler runs every 5 s from the watcher and on every Herdr nudge: it lists Herdr panes and agents, compares with bound sessions, marks missing panes `orphaned`, ends sessions whose agent left Herdr's list while the pane lives on (`done`, or `failed` when it vanished mid-turn, unbound, receipt written; rig, 2026-09-02) unless the Herdr server started after the session's binding, in which case the pane is the restored shell after a restart and the session is `orphaned` instead (a reboot at 22:30 on 2026-09-02 ended two working sessions before this rule existed; the server's start is read from its socket's mtime, with a two-second margin), adopts a Herdr agent pane with no session record as a session created by `system:omarchy` named after the Herdr agent, so agents started outside the launcher still appear, and rewrites `index.json` with the Herdr state (`03-sessions-panel.md`). When Herdr itself is unreachable it orphans every bound live session and exits 4. It also sweeps the workspaces its own `runtime.bound` events name for any ended or orphaned session, closing their empty shell panes, never an adopted agent's workspace and never one with a live agent in it; Herdr restores every workspace with a fresh shell after a server restart, and by run 2 nine dead panes sat in its list.

## Invariants

1. A session record exists before its pane, and persists after it.
2. Every event has an actor. `system:omarchy` is an actor, and a human is never inferred from an agent's action.
3. `state_version` never decreases.
4. `created_by` never changes. `owner` changes only through `owner.assigned`.
5. A session in `shared` or `restricted` mode is never bound to a harness launched with a bypass-permissions flag.
6. Two sessions never share a worktree unless both records name the same `worktree_path` and `workspace.created_by_session` is false for both.
7. Deleting a session directory is the only way to lose history, and no command does it.

## Retention

Records are kept for as long as the directory exists. Nothing ages out on its own: an ended session stays on disk with its events, receipt, artifacts, and harness resume reference until a person deletes the directory. A `prune` command, explicit and never scheduled, is the only deletion this model will ever add, and it is not built.

What changes with age is which surface shows a record, and that is a property of the surface, never of the record (`03-sessions-panel.md`): the bar panel shows what is live plus what ended in the last day, and `history` shows what ended in the last fourteen days by default, further back on request. On 2026-09-03 the rig held 52 records, every one of them ended, 42 of them stopped by a person, and the panel showed none of the previous evening's; that is the day this section was written.

## Open questions for the rig

- Whether Herdr's stored per-agent resume reference (named `agent_session` in its docs) and its custom state and metadata channel exist as documented on the installed version, and what their exact field names are.
- How Herdr's five reported states (`blocked`, `working`, `done`, `idle`, `unknown`) map onto this model's `waiting` versus `blocked`: the docs describe `blocked` as needing the user, and the split between a question and an approval may need the harness's own hooks or screen text. Until the rig answers, the panel treats both as "needs you".
- Whether Herdr on the ARM image exposes the socket API at the documented path and whether `events.subscribe` streams reliably to a long-lived reader started from the Quickshell process.
- Which harness flags produce `waiting` versus `blocked` distinctions in Herdr's detection for Claude Code and Codex on the rig; the mapping table in `04-permission-modes.md` carries a verify-on-rig mark per row.
- Whether Herdr's custom metadata channel survives a Herdr server reload-config, which Omarchy triggers on theme change.

## Sources

Herdr concepts, session state, socket API, and agents pages at herdr.dev/docs (observed 2026-09-01). OpenClaw multi-user model, session state awareness, and sub-agents pages at docs.openclaw.ai (observed 2026-09-01), for the creator-owner-participants split, the state-version cursor idea, spawn receipts, and marked inter-agent messages. Omarchy `bin/omarchy-agent` on branch quattro for launch flags.
