# Receipts and artifacts

Status: proposed, 2026-09-01. Slice 1. Builds on the record and event log in `01-session-model.md`.

A session's receipt is the only proof of what happened once the terminal closes. This file makes that proof automatic, fixed in shape, and durable from the first checkpoint to the last.

## Lifecycle

A checkpoint writes a partial receipt every 5 minutes while a session is `working`, and immediately on every transition into `waiting`, `blocked`, or `idle`. A partial receipt has `end_state: null`, `end_reason: null`, `ended_at: null`; every other field reflects the session at that instant, including `duration_s`, measured to the checkpoint's own timestamp.

A terminal receipt writes once, at the transition into `done`, `failed`, or `stopped`, and fills in the three end fields. Both write the way `session.json` does: temp file, then rename. A crash between checkpoints loses at most 5 minutes of currency and no history: `events.jsonl` is append-only, and the receipt is only ever a projection of it.

## Fields and how each is computed

`receipt.json` carries exactly the fields defined in `01-session-model.md`:

| Field | Computed from |
|---|---|
| `session_id`, `name`, `agent`, `owner`, `created_by` | copied from `session.json` at write time |
| `started_at` | `session.json.created_at` |
| `ended_at` | timestamp of the terminal `session.ended` event; `null` on a partial receipt |
| `duration_s` | `ended_at` minus `started_at` in whole seconds; on a partial receipt, to the checkpoint |
| `end_state`, `end_reason` | `state` and `reason` from the `session.ended` event; `null` on a partial receipt |
| `started_with`, `goal`, `workspace` | copied from the matching `session.json` fields |
| `commits` | `git log --no-merges --reverse --format=%H%x1f%s%x1f%an <base_branch>..<branch>` in `worktree_path` |
| `diff_stat` | `git diff --shortstat <base_branch>...<branch>` in `worktree_path`, parsed into files, insertions, deletions |
| `dirty` | `true` when `git status --porcelain` in `worktree_path` prints anything |
| `unpushed` | `true` when `git rev-list <branch> --not --remotes` prints a sha, or the worktree has no remote at all |
| `artifacts` | one `{path, label, added_by, added_at}` entry per file in `artifacts/`, read from each sidecar, in add order |
| `instructions` | counted over `instruction.delivered` and `instruction.dropped` events; authors are the distinct `author` values delivered |
| `approvals` | counted over `approval.requested` and `approval.resolved` events, grouped by `decision` |
| `children` | `lineage.children`, joined with the `state` from each child's last `child.completed` event |
| `harness_session_ref` | `session.json.agent.harness_session_ref` |
| `state_version` | the last `seq` in `events.jsonl` at write time |

Commits use a two-dot range: what is on this branch that is not on base. Diff stat uses three dots, against the merge base, so a base branch that moved after the fork does not inflate the diff with changes the session never made.

## Artifacts directory

Every artifact is two files under `artifacts/`: the artifact itself, named `<ulid>-<label>.<ext>`, and a sidecar with the same stem and a `.json` extension. The ULID orders artifacts chronologically by filename; the label makes a listing readable unopened. A capture labeled `after-nav-fix` lands as `artifacts/01J8Z3K9QY7NX8V2H5T6M4R1WB-after-nav-fix.png` beside `artifacts/01J8Z3K9QY7NX8V2H5T6M4R1WB-after-nav-fix.json`.

The sidecar carries:

| Field | Meaning |
|---|---|
| `label` | the human label, matching the filename |
| `added_by` | the actor who added it |
| `added_at` | RFC 3339 timestamp |
| `kind` | `capture`, `file`, `url`, or `note` |
| `source` | what produced it: window or region for a capture, original path for a file, the URL for a url, `typed` for a note |
| `state` | `proposed` or `live`, set by the capture rules below |

`session.json` never lists artifacts. `events.jsonl` records each addition as `artifact.added`, and the receipt's `artifacts` field is the durable index a person or a script reads later.

## Capture

`capture --screenshot` produces the `capture` kind, with `--window` (default), `--region`, or `--fullscreen` choosing the mode, both shelling out to Omarchy's screenshot path: the manual documents `omarchy capture screenshot windows` (snap to a window or monitor rectangle), `region` (freeform drag), and `fullscreen` (skip the picker, grab the focused monitor), each taking a second `save` or `copy` argument. `--window` calls `windows` and `--region` calls `region`, both with `save`, `OMARCHY_SCREENSHOT_DIR` redirected to a scratch path; the PNG then moves into `artifacts/` under its ULID name. A session with a registered `preview` window (`09-closed-loop-surfaces.md`) makes `--window` target that window instead of whatever has focus.

Whether `windows` completes without a person clicking to confirm the highlighted rectangle, so an unattended call actually returns a file, is not settled by the manual: verify on rig. If it cannot run unattended, `--window` falls back to `fullscreen`, which the manual confirms skips the picker, and the sidecar's `source` records `monitor` so a full-screen grab is never mistaken for a tight crop.

A url artifact (`session artifact add <id> --kind url --source <url>`) stores the URL as the artifact body and fetches the page title as the default `label` when none is given; a failed fetch leaves the label as the bare URL. A note (`session artifact add <id> --kind note`) stores the given text verbatim. Neither touches the compositor or needs a rig check.

`state` is `proposed` when the capture is taken against the session's own worktree or preview, before `branch` merges into `base_branch`. It is `live` when taken against something running `base_branch` itself: a baseline shot before any change, or a confirmation shot after the merge. The label is set at capture time and never edited afterward.

## In the receipt and the panel

The receipt's `artifacts` field lists `{path, label, added_by, added_at}` for every artifact, in add order. `kind`, `source`, and `state` stay in each sidecar, so the receipt stays a compact index and the sidecar stays the record for that one artifact. The renderer below joins the two, so reading a receipt never requires opening a JSON file by hand.

On the panel, a session row with artifacts carries an artifact count in its detail area; expanding the row lists each capture as a thumbnail labeled with its `state` and `added_at`. The collapsed row shows only the status indicator success signal 1 depends on. Artifacts are a detail, never a reason to look twice at a row that is not waiting on anyone.

## Human-readable rendering

`omarchy agent session receipt <id>` prints a fixed-order plain-text receipt: the same groups, in the same order, every time, whether or not a group has anything in it. A person never hunts for a field; a script piping the output through `grep` can rely on a line's position.

Example, for a Claude Code session that produced two commits and one capture:

```
Session    fix-nav-focus-trap  01J8Z3K9QY7NX8V2H5T6M4R1WB
Agent      claude   harness ref 8f6e2d1c (verify on rig: exact resume-id format)
Owner      human:praneet@rig   created by human:praneet@rig
Status     done (clean)   2026-09-10T18:42:03Z -> 2026-09-10T19:07:52Z, 25m49s
Started    omarchy-agent --app claude --prompt "fix the nav focus trap"   cwd ~/Work/omarchy-multiplayer
Goal       Keyboard focus never leaves the open nav on Tab.
           Must not change nav DOM ids or the design tokens.
           A passing focus-trap capture is the evidence that closes this.

Workspace  omarchy-multiplayer   worktree fix-nav-focus-trap   branch fix/nav-focus-trap   base quattro
Commits    2
  a1b2c3d  Trap focus inside the open nav panel
  e4f5061  Restore focus to the toggle button on close
Diff       3 files changed, 42 insertions(+), 6 deletions(-)
Dirty      no
Unpushed   yes, 2 commits on no remote

Artifacts  1
  after-nav-fix.png   capture, proposed   2026-09-10T19:06:40Z   agent:01J8Z3K9QY7NX8V2H5T6M4R1WB

Instructions  3 delivered, 0 dropped, 1 author (human:praneet@rig)
Approvals     1 requested, 1 approved, 0 denied
Children      none

Receipt    state_version 41, written 2026-09-10T19:07:52Z
```

## Crash-diagnosis receipts

A crash-diagnosis session has no worktree: `omarchy-agent-crash` spawns it against the running system, and there is no repository. `workspace`, `commits`, `diff_stat`, `dirty`, and `unpushed` are all `null`; nothing is computed. `started_with` carries the exact prompt the crash flow built, citing `default/agents/skills/diagnose-crash/SKILL.md`, and the crash facts, pid, comm, exe, signal, live in `goal.text`, set at creation. The receipt schema does not change per session type.

When the harness writes a conclusion, the diagnosis skill should close its run by adding a `note` artifact holding it, so the conclusion lands in the receipt's `artifacts` list like any other note. A run that writes no such note simply has an empty `artifacts` list; the receipt still shows the crash facts, the end state, and the duration. Fields that do not apply are `null`, nothing more.

## Retention

Receipts are never deleted by anything here. `session.json`, `events.jsonl`, `receipt.json`, and `artifacts/` persist under `~/.local/state/omarchy/sessions/<id>/` for as long as the directory exists, and invariant 7 in `01-session-model.md` guarantees no command removes it. A `sessions prune` command is reserved: the name is claimed so retention can be added without a naming collision, but it has no implementation and no schedule, and `01-session-model.md`'s Retention section (2026-09-03) says it will never be scheduled. What ages is only which surface shows a receipt: the panel shows a day of ended sessions and `history` shows fourteen, and both open the same `receipt`.

## Portfolio evidence

This is success signal 3, answered directly: a completed session shows workspace, branch, commits, diff summary, status, and the command that started it, and the rendering above is that answer in the form a person reads. It is also what a case study needs and nothing else currently provides: a `live` capture and a `proposed` capture, each labeled, each dated, each tied to the commit that produced the difference between them. Writing about the work later means citing the receipt's artifact list and the two paths in it. The dates and the diff stat are already computed, already attached to one specific session, not reassembled afterward from whatever screenshots survived.

## Verify on rig

- Whether `omarchy capture screenshot windows` completes without an interactive click, for an unattended `capture --screenshot --window` call.
- The exact resume-id string format each harness returns, for `harness_session_ref` and the receipt's Agent line.
- Whether `git rev-list <branch> --not --remotes` is the right unpushed test on the rig's git version, and how a repo with no remote at all should be flagged.

## Sources

- Omarchy manual, Screenshots & Recording, omarchy.org/manual/screenshots-recording/, observed 2026-09-01.
- Omarchy `bin/omarchy-agent-crash` and `default/systemd/user/omarchy-crash-watch.service`, branch quattro, observed 2026-09-01.
- `01-session-model.md`, this project, 2026-09-01, for the session record, event log, and receipt fields.
- PLAN.md, this project, for success signal 3.
