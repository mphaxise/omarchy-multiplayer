# Command surface

Status: proposed, 2026-09-01. Slice 1.

One command group, `omarchy agent session`, plus three existing commands that become wrappers over it. Each subcommand is its own binary, `bin/omarchy-agent-session-<cmd>`, with `# omarchy:summary=`, `# omarchy:args=`, `# omarchy:examples=` headers, matching the convention `omarchy agent crash` already uses. All commands read and write the record and event log from `01-session-model.md`; event types below are exactly that file's set.

Shared exit codes:

| Code | Meaning |
|---|---|
| 0 | ok |
| 2 | usage error |
| 3 | no session matches the id or name |
| 4 | a Herdr call failed or Herdr is unreachable |
| 5 | conflict: name taken, depth/children limit, or the session's state forbids the operation |

A session is viewed through its own terminal window, not Herdr's UI, so every workspace/tab/pane call below passes `focus:false`. Herdr's own "session" means a server namespace (`herdr session list/attach/stop/delete`); slice 1 stays on Herdr's default session and never overloads that word for an Omarchy session.

Herdr agent aliases must match `[a-z][a-z0-9_-]{0,31}`; `new` derives one from the session's free-text `name` (lowercase, non-matching runs become `-`, prefix `s-` if the result would not start with a letter, truncate to 32). A collision with a live Herdr agent name gets the last four id characters appended, once. `rename` re-derives the slug and calls `agent.rename` so Herdr's sidebar tracks the panel.

## Inter-agent marker

`send --from <origin-id>` marks another session, not a human, as author. Delivery prefixes exactly this, then a blank line, then the instruction text unchanged:

```
[omarchy-session-message from=<origin_session_id> name=<origin_session_name>]

<instruction text>
```

`name` has newlines and `]` stripped before insertion. A human-typed instruction carries no marker. The harness must treat the marker line as inert provenance data, never as an instruction to execute or an approval.

## `--json` shape

`list --json`:

```json
{ "sessions": [
  { "id": "01J...", "name": "api-refactor",
    "agent": { "kind": "claude" },
    "status": { "state": "waiting", "since": "2026-09-01T18:04:11Z", "source": "herdr-hook", "detail": null },
    "owner": { "kind": "human", "id": "praneet@rig", "label": "praneet" },
    "workspace": { "branch": "worktree/api-refactor" },
    "needs_attention": true, "children": 0, "state_version": 17,
    "goal": "ship the v2 auth endpoint", "mode": "shared", "resumable": true,
    "created_by": { "kind": "human", "label": "praneet" },
    "project": "omarchy" }
] }
```

`needs_attention` is true exactly when `status.state` is `waiting` or `blocked`, the two states `01-session-model.md` names as asking for a person. The panel row (`03-sessions-panel.md`) reads the rest: `goal` is the first non-empty line of the goal text, cut to 120 characters, or `null`; `mode` is the record's; `resumable` is true when `agent.harness_session_ref` is a non-empty string, so `open` can resume the transcript; `created_by` carries the creator's `kind` and `label`; `project` is the basename of `workspace.repo_root`, else of `started_with.cwd`, else `null`; `status.source` and `status.detail` are the record's. `show --json` wraps one such object as `"session"`, adding the full `goal`, `runtime`, `lineage`, `created_at`, the full `created_by`, `mode`, `started_with`, plus `"recent_events"`: the last 20 `events.jsonl` lines.

## Commands

### `new`
`new --agent <kind> [--mode personal|shared|restricted] [--name <text>] [--goal <text>] [--prompt <text>] [--base <ref>] [--worktree <path>] [--no-worktree] [--from <session>] [--owner <actor>] [--cwd <path>] [--pick] [-- <agent args>]`

`--prompt` delivers its text through `agent.prompt` once the harness is ready, after an `agent.wait`, instead of as a harness argument: Herdr refuses argv it cannot encode for the shell, which the multi-line crash prompt is (rig, 2026-09-02).

`--base` names the branch a new worktree starts from (default: the current branch); `--worktree <path>` joins an existing worktree instead of creating one (both records mark `created_by_session: false`, invariant 6); `--no-worktree` runs in the working directory; `--from <session>` records lineage and flips the default mode to `shared` (`04-permission-modes.md`); `--pick` opens the agent picker; `--owner` at creation is folded into `session.created` and writes no `owner.assigned` event.
Without `--name`, the name is derived: the first four words of `--prompt`, else the basename of `--cwd`, else the agent kind, slugified like the alias (lowercase, runs outside `[a-z0-9]` become `-`, cut to 28 characters, `s-` prefixed when it would not start with a letter), then `-2`, `-3`, ... appended until no session on disk, ended ones included, has that name. An explicit `--name` must be unused by any live session (exit 5).
Allocates the id, resolves the worktree per `07-worktrees.md`, starts the harness. Writes `session.created`, `runtime.bound`, `goal.set` if `--goal` given; `status` opens `starting`, moves to `working` on Herdr's confirmation.
Herdr: `worktree.create`/`worktree.open` (or `workspace.create` with no worktree), `focus:false`; then `agent.start` with the derived alias, `--kind`, the new pane, and the flags `04-permission-modes.md` maps from `--mode`, plus any `-- <agent args>`.
Exit: 0, 2, 4, 5.
Example: `omarchy agent session new --agent claude --mode personal --name api-refactor`

### `list`
`list [--state <state>] [--mine] [--json]`
Writes nothing. Reads local `session.json` files only; status is the last `status.changed` event. No Herdr call, so the panel never polls Herdr to render.
Herdr: none.
Exit: 0.
Example: `omarchy agent session list --state waiting --json`

### `show`
`show <id-or-name> [--refresh] [--json]`
Writes nothing by default; `--refresh` writes `status.changed` if live state disagrees with the record.
Herdr: none by default; `--refresh` calls `agent.get` (or `pane.get` if unbound).
Exit: 0, 3.
Example: `omarchy agent session show api-refactor --refresh`

### `open`
`open <id-or-name>`
Bound and live: launch or focus a terminal at app id `org.omarchy.session.<id>` via `omarchy-launch-or-focus-tui`, running `herdr agent attach <alias>` inside it. Orphaned with `harness_session_ref`: open the worktree, `agent.start` the harness with that kind's resume flag and id (for example `claude --resume <id>`, `codex resume <id>`, from Herdr's native-resume table), then attach; writes `runtime.bound`, `status.changed` to `working`. Orphaned with no ref: start fresh in the same worktree; writes `runtime.bound`, `status.detail = "no transcript to resume"`.
Herdr: `agent.get`/`pane.get` to check the binding, then `worktree.open`, `agent.start`, `agent.focus`; `agent attach` (CLI) for the terminal itself.
Exit: 0, 3, 4.
Example: `omarchy agent session open api-refactor`

### `send`
`send <id-or-name> <text> [--from <origin-id>] [--wait] [--until <state>]... [--timeout <ms>]`
Writes `instruction.queued`, then `instruction.delivered` or `instruction.dropped` with a reason (`agent_blocked`, unbound, ended).
Herdr: `agent.prompt` with the marker-prefixed text when `--from` is set; `--wait`/`--until`/`--timeout` pass straight through to the same `agent.prompt` flags. No pane bound: the instruction stays in `queue`, delivered on the next `open`.
Exit: 0, 3, 4, 5.
Example: `omarchy agent session send api-refactor "add a regression test" --wait --until done`

### `stop`
`stop <id-or-name> [--keep-children] [--reason <text>]`
Writes `status.changed` to `stopped`, `session.ended`, `runtime.unbound`. Without `--keep-children`, every child stops first, depth-first, each with its own `session.ended` (`reason: "parent_stopped"`); with it, children keep running and keep `lineage.parent_id` for history.
Herdr: if `working`, `agent.send_keys` a `ctrl+c` as a courtesy (whether this cleanly exits a given harness kind is verify on rig), then `pane.close` regardless. No call if already orphaned.
Exit: 0, 3, 4.
Example: `omarchy agent session stop api-refactor --keep-children`

### `rename`
`rename <id-or-name> <new-name>`
Writes `session.renamed` (`from`, `to`); enforced unique among live sessions.
Herdr: `agent.rename` on the bound alias with the freshly derived slug; skipped if unbound.
Exit: 0, 3, 5.
Example: `omarchy agent session rename api-refactor api-refactor-2`

### `assign`
`assign <id-or-name> <owner-actor>`
Writes `owner.assigned` (`from`, `to`). Ownership is responsibility, not access, so there is nothing for Herdr to do.
Herdr: none.
Exit: 0, 3.
Example: `omarchy agent session assign api-refactor human:praneet@rig`

### `goal`
`goal <id-or-name> (set <text> | clear | show)`
`set`/`clear` write `goal.set`; the session model defines only that one event type, so `clear` writes it with `text` empty, not a new event type. `show` writes nothing.
Herdr: none.
Exit: 0, 3.
Example: `omarchy agent session goal api-refactor set "ship the v2 auth endpoint"`

### `log`
`log <id-or-name> [--since <seq>] [--type <event-type>] [--follow] [--json] [--transcript <n>]`
Writes nothing. Prints `events.jsonl` from `--since` (default all); `--follow` tails new lines.
Herdr: none by default; `--transcript <n>` calls `agent.read` (`--source recent-unwrapped --lines <n>`), which returns `agent_not_idle` while `working`/`blocked`/`unknown` for a full-screen harness, so it only works once the session is `idle` or `done` (verify on rig how often that matters in practice).
Exit: 0, 3.
Example: `omarchy agent session log api-refactor --follow`

### `receipt`
`receipt <id-or-name> [--json] [--write] [--pager]`
Prints `receipt.json`. `--write` recomputes it now (git log/diff-stat against `base_branch`, not Herdr) and writes `receipt.written`. `--pager` pipes the text rendering through `less -R` (the panel's Receipt action runs inside a TUI window, `03-sessions-panel.md`), printing plainly when `less` is missing; ignored with `--json`.
Herdr: none; receipt fields come from git and the local record.
Exit: 0, 3.
Example: `omarchy agent session receipt api-refactor --write`

### `capture`
`capture <id-or-name> (--screenshot | --file <path> | --url <url>) [--label <text>]`
Writes `artifact.added` (`path`, `label`, `added_by`). `--screenshot` runs the compositor's screenshot tool (exact binary unconfirmed in source material; verify on rig) and saves the PNG under `artifacts/`; `--file` copies the given file into `artifacts/` so the session directory stays self-contained; `--url` writes the link as a one-line file under `artifacts/`, keeping `path` a real file in every case.
Herdr: none.
Exit: 0, 2, 3.
Example: `omarchy agent session capture api-refactor --screenshot --label before`

## Commands defined in other spec files

These share the same binary convention (`bin/omarchy-agent-session-<cmd>`) and event log; their behavior lives where it is specified.

| Command | Defined in | Writes |
|---|---|---|
| `mode <id> <personal\|shared\|restricted>` | `04-permission-modes.md` | `mode.changed`; relaunches the harness with `harness_session_ref` |
| `artifact add <id> --kind capture\|file\|url\|note --source <path\|url\|text> [--label <text>]` | `05-receipts-and-artifacts.md` | `artifact.added` |
| `preview <id> <url\|app-id>` | `09-closed-loop-surfaces.md` | `preview.set` |
| `send <id> --about <artifact-id> "<text>"` | `09-closed-loop-surfaces.md` | `instruction.queued` with the artifact reference |
| `show <id> --loop` | `09-closed-loop-surfaces.md` | nothing; renders intent, instructions, changes, and captures in order |
| `done <id> --verdict kept\|reverted\|needs-person --note "<text>"` | `09-closed-loop-surfaces.md` | `artifact.added` (note labeled `verdict`), `status.changed` to `done`, `session.ended` |

## Reserved for slice 2

`bin/omarchy-agent-session-share`, `-take`, `-suggest`: reserved names, no behavior in slice 1. `share` would grant another user access to a session; `take` would claim ownership or pull a session's terminal forward; `suggest` would surface an agent-initiated suggestion to the owner. None ship before user-to-agent and user-to-user control exist.

## Maintenance: `reconcile`

`reconcile [--json]`
The command the panel-refresh and timer paths in `01-session-model.md` call; not a second mechanism. Writes `status.changed` to `orphaned` and `runtime.unbound` for a bound session whose pane is gone; writes `session.created` (actor `system:omarchy`) and `runtime.bound` for a live Herdr agent with no matching session. When Herdr is unreachable it orphans every bound live session (`runtime.unbound`, reason `herdr_unavailable`) and exits 4.
At the end of every run, reachable or not, it rewrites `~/.local/state/omarchy/sessions/index.json` atomically (temp file, rename), the liveness file the panel's `FileView` watches (`03-sessions-panel.md`): `{"generated_at": <RFC 3339 UTC>, "herdr": "running" | "unreachable", "orphaned": [ids orphaned this run], "adopted": [ids adopted this run], "counts": {"needs_attention": n, "live": n, "orphaned": n}}`. `live` counts sessions in neither a terminal state nor `orphaned`, `needs_attention` counts `waiting` and `blocked`, `orphaned` counts `orphaned`, all after this run's changes. Rows come from `list --json`, not the index. A failed index write is one stderr line and never changes the exit code or the stdout report (`{"orphaned", "adopted"}`, plus `"herdr": "unreachable"` on the outage path).
Herdr: `agent.list` and `pane.list` per workspace, compared against every session's `runtime`.
Exit: 0, 4.
Example: `omarchy agent session reconcile --json`

## Existing commands become wrappers

`omarchy agent [<kind>]` now calls `session new` (mode from `omarchy-default-agent` unless given, cwd `~/Work` as today), then `open`. Changes: the app id moves from the one shared `org.omarchy.agent` to a per-session `org.omarchy.session.<id>`, so each launch is an independent, later-reopenable window instead of one shared one. Stays: the eleven agent choices, the `~/Work` default, and the rule that a bypass-permissions launch flag appears only under Personal mode.

`omarchy agent prompt "<text>"` calls `session new --prompt "<text>"`, which delivers the text through `agent.prompt` once the harness is ready, then `open`. Changes: the prompt now has a durable, named, receipted session behind it. Stays: the prompt text itself and how it reaches the harness.

`omarchy agent crash <pid> <comm> <exe> <signal>` calls `session new --name "crash-<pid>" --goal "diagnose crash of <comm> (pid <pid>)"` with the built crash prompt passed as `--prompt`, then `open`. Changes: a crash diagnosis becomes a session with a receipt instead of an anonymous terminal. Stays: the prompt text built from `default/agents/skills/diagnose-crash/SKILL.md` and the `omarchy-crash-watch` to `omarchy-notification-send --exec omarchy-agent-crash` pipeline that triggers it.

## Verify on rig

- Whether `pane.close` terminates the harness process or only detaches Herdr's tracking of it.
- Which key sequence reliably exits each harness kind versus only interrupting one turn.
- The compositor screenshot tool's exact binary name and arguments for `capture --screenshot`.
- Whether `agent.rename` can race a second, non-Omarchy Herdr client naming an agent the same slug.
- How often `log --transcript` hits `agent_not_idle` in practice versus a genuinely idle window.

## Sources

Herdr CLI reference, Socket API, Agents, and Agent automation pages at herdr.dev/docs (observed 2026-09-01): `agent.start`/`agent.prompt`/`agent.rename`/`agent.focus`/`agent.send_keys`/`agent.wait`, the `[a-z][a-z0-9_-]{0,31}` alias rule, `worktree.create`/`open`/`remove`, `pane.close`, and the per-agent native-resume command table. `01-session-model.md` for the record, event types, and state machine used throughout. Omarchy `bin/omarchy-agent`, `omarchy-agent-prompt`, and `omarchy-agent-crash` on branch quattro for current wrapper behavior.
