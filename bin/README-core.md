# Core: session store, command surface, Herdr client

Proposed, 2026-09-01. Nothing here has touched Herdr, Hyprland, or a real
Omarchy install. `omarchy-agent-session-core` is what every
`bin/omarchy-agent-session-<cmd>` shell wrapper execs into
(`omarchy-agent-session-core <cmd> "$@"`); this directory is the one place
the session record, event log, receipt, permission-mode table, and Herdr
client live. Python 3 standard library only.

## Running the tests

```
cd build/core
python3 -m unittest discover -s tests -v
```

Final line from this build's own run:

```
Ran 53 tests in 4.095s

OK
```

Tests were run against the sandbox's Python 3.10.12 (no 3.11+ interpreter
was available here). The code avoids anything 3.11-exclusive (no `tomllib`,
no `except*`, no `Self`), so it runs unchanged on 3.10 or 3.11+; nothing in
it depends on a 3.11-only stdlib feature.

Most tests call `core.main([...])` in-process (env vars set per test,
stdout/stderr captured via `contextlib.redirect_std*`) instead of spawning
a subprocess, so `tests/fake_herdr.py`'s threaded Unix-socket server , 
running as a thread in the same test process, can be inspected directly
afterward (`server.calls("agent.prompt")` etc.) without going through a
file or pipe. One test (`TestCliIsExecutable`) spawns the file as a real
subprocess, to prove the shebang and executable bit work end to end and not
just the import path.

## What's verified locally vs. VERIFY ON RIG

**Verified locally** (by the test suite, or by manual smoke-testing beyond
it, see below):

- The full session lifecycle for `new`, `list`, `show`, `send`, `rename`,
  `assign`, `goal`, `preview`, `mode`, `capture`, `artifact-add`, `receipt`,
  `done`, `stop`, `reconcile` against a fake Herdr server answering this
  build's assumed wire protocol.
- `new` prints the created session's id on stdout on success, and the full
  record with `--json`.
- The state machine's valid/invalid transition table, event `seq`
  monotonicity (including across a simulated process restart, i.e. a fresh
  `SessionStore` instance reading the same directory), and that
  `state_version` never decreases.
- Invariant 5 (deny-list refusal, exit 5) for a smuggled Personal-mode
  bypass flag under `shared`, for a harness with no safe expression of a
  mode at all (`hermes` + `restricted`), and for Codex's
  `--ask-for-approval never` without `--sandbox read-only` "looks safe
  alone" combination, including the case where the mode's own cell already
  contributes one `--ask-for-approval` and a smuggled extra argument adds a
  second one later in argv (a real bug this build's own smoke-testing
  caught: the first implementation only inspected the first occurrence).
- Invariant 6 (never share a worktree unless both sides say
  `created_by_session: false`), directly against `check_invariant6`.
- The inter-agent marker line's exact format, delivered all the way through
  to the fake server's recorded `agent.prompt` call (not just checked as a
  string in isolation), including stripping embedded `]` and newlines from
  the origin name.
- Receipt computation (`commits`, `diff_stat`, `dirty`, `unpushed`) against
  a real temporary git repository with two commits on a session branch off
  `main`, git user configured locally in that repo; also the dirty-worktree
  case, and `done`'s end-to-end write of a terminal receipt plus a `verdict`
  artifact.
- The worktree cleanup keep/remove table (`decide_worktree_cleanup`) against
  a real `git worktree add`ed directory: keeps a dirty worktree, keeps a
  clean worktree that is neither merged nor pushed, removes a clean worktree
  merged into `base_branch` while keeping the branch (invariant 7), never
  touches a worktree this session didn't create, and is actually wired into
  `stop` (confirmed end to end: the directory disappears, and
  `workspace.worktree_removed`/`worktree_removed_reason` persist in
  `session.json`, which is also how they reach the receipt). This was a real
  gap this build's own review caught after the first pass: `stop`/`done`
  initially never called any cleanup at all.
- `reconcile` marking an orphan when a bound session's pane disappears from
  Herdr's lists, leaving a still-present one alone, adopting an unmatched
  live Herdr agent as a new `system:omarchy` session, and exiting 4 when
  Herdr is unreachable.
- `list --json`'s exact shape (key set, `children` as a count not a list,
  `needs_attention` true exactly for `waiting`/`blocked`).
- ULID format (26-char Crockford base32, no `I`/`L`/`O`/`U`) and
  lexicographic time-ordering; atomic writes (temp file + `os.replace`,
  with no leftover temp file after two successive writes).
- The plain-git worktree fallback (`create_worktree`/`remove_worktree` with
  `herdr=None`): confirmed to actually create a `git worktree`, check out
  the session branch, and remove the worktree while keeping the branch , 
  smoke-tested manually, not by an automated test in `tests/`.
- `open`'s four branches, each an automated test: bound-and-live (confirms
  `agent.get` is called), orphaned with a `harness_session_ref` (confirms
  the resume flag is prepended to argv and the session moves back to
  `working`), orphaned with no ref (fresh start, `detail: "no transcript to
  resume"`), and "nothing to open" (no runtime, not orphaned) refusing as a
  conflict. A fifth, bound-but-Herdr-down, confirms exit 4.
- Manual smoke-testing beyond the automated suite (not committed as tests,
  but exercised end-to-end against the fake server while writing this):
  `new` with a real worktree request (confirms `worktree.create` is called
  with the assumed param shape), `show --json`/`show --loop`, `goal`
  set/show/clear, `assign`+`rename` (confirms `agent.rename` receives the
  re-derived alias), `capture --file`, `artifact-add` for `note`/`url`,
  `receipt` display vs. `--write`, `send --wait --until`, `mode` (confirms
  `pane.close` then a second `agent.start` on a live relaunch), and `log`.

**VERIFY ON RIG** (carried from the spec files, or newly identified by this
build):

- Everything under "Herdr's wire-protocol assumptions" below, none of it
  has ever talked to a real Herdr socket.
- Every "Verify on rig" item already listed in `spec-01`, `spec-02`,
  `spec-04`, `spec-05`, and `spec-07` that this build didn't have to
  resolve to write this code (per-harness exit sequences, the compositor
  screenshot binary's real name and unattended behavior, the exact
  resume-id string format per harness, `git rev-list --not --remotes`
  cost on a large multi-remote repo, unicode/emoji in `git_safe_ref`,
  etc.), unchanged, not re-litigated here.
- Whether `omarchy-launch-or-focus-tui` and `herdr agent attach` (called by
  `open` for a bound-and-live session) behave as `02-command-surface.md`
  assumes; wrapped in `contextlib.suppress(FileNotFoundError, OSError)`
  here since neither binary exists in this sandbox, so `open`'s own record
  work (checking the binding, resuming an orphan) is exercised, but the
  actual terminal-attach step is not.
- Whether `omarchy capture screenshot windows save` completes unattended,
  and whether `fullscreen` is the right fallback target name
  (`do_screenshot_capture`); neither binary exists in this sandbox, so this
  path is implemented defensively (try windows, fall back to fullscreen,
  raise a clear `CaptureError` if both fail) but never actually exercised
  against a compositor.
- Whether `agent.read` (used by `log --transcript`) is really the right
  method name and whether it really returns `agent_not_idle` the way
  `02-command-surface.md` describes; `log`'s own exit-code table (0, 3 , 
  no 4) is honored literally here, so any Herdr trouble during
  `--transcript` degrades to a printed line and exit 0 instead of a hard
  failure.

## Herdr wire-protocol assumptions

Every one of these lives in `HerdrClient`'s own docstring
(`omarchy-agent-session-core`, class `HerdrClient`), marked
`VERIFY ON RIG` there; this is the same list, gathered in one place per the
task:

1. **Transport**: a Unix domain socket at the path named by `HERDR_SOCKET`
   (default `~/.config/herdr/herdr.sock`), one fresh connection per call
   (except `events_subscribe`, which holds one connection open).
2. **Framing**: newline-delimited JSON, one JSON object per line, both
   directions.
3. **Request shape**: `{"id": <int>, "method": "<name>", "params": {...}}`.
4. **Reply shape**: `{"id": <int>, "result": <any>}` on success, or
   `{"id": <int>, "error": {"code": ..., "message": ..., "data": ...}}` on
   failure, one reply line per request line, in the same order.
5. **Method names**: `agent.list`, `pane.list`, `agent.get`, `agent.start`,
   `agent.prompt`, `agent.rename`, `pane.close`, `worktree.create`,
   `events.subscribe`, `snapshot`, the ten this build's `HerdrClient` names
   as methods, per the task's own list. `worktree.open`, `worktree.remove`,
   `agent.send_keys`, `agent.focus`, and `agent.read` are named by
   `02-command-surface.md`/`07-worktrees.md` but were not in that required
   list; this build reaches them through `HerdrClient.call(method, params)`,
   a generic escape hatch, with the same framing assumption.
6. **`agent.start` params**: assumed to accept `alias`, `kind`, `cwd`,
   `flags` (list of argv strings), `env` (dict), and `focus`; assumed to
   return a result containing `session`, `workspace_id`, `tab_id`,
   `pane_id`, and `agent_id`, mapped directly onto `session.json`'s
   `runtime` shape.
7. **`worktree.create` params**: assumed to accept `repo`, `path`,
   `branch`, `base`, and `focus`.
8. **`agent.prompt` params**: assumed to accept `alias`, `text`, `wait`,
   `until` (list), and `timeout_ms`.
9. **`agent.rename` params**: assumed to accept `agent_id` and `new_alias`.
10. **`pane.close`/`agent.get` params**: assumed to accept `pane_id` and
    `agent_id` respectively as the sole identifying field.
11. **`agent.list`/`pane.list` results**: assumed to be plain JSON arrays of
    objects, each carrying at least `agent_id` (or `pane_id`) plus `kind`
    and `name` when known, `reconcile` matches these against a session's
    stored `runtime.agent_id`/`runtime.pane_id`.
12. **Errors vs. unreachability**: a connect failure (missing socket, refused
    connection, timeout) is treated as `HerdrUnavailable` (exit 4 territory,
    or a fallback to plain git for worktree operations); a well-formed
    `{"error": {...}}` reply is treated as `HerdrError`, a real Herdr-side
    rejection that is never silently swallowed into a fallback.
13. **`events_subscribe`**: assumed to be the same request/reply framing for
    its initial subscribe, then an unsolicited stream of further JSON lines
    on the same connection. Nothing in this build actually drives a
    long-lived subscriber loop, see "No persistent event subscriber" below.

## Other assumptions the spec didn't settle

Kept short here; the full reasoning for each is in the code as a comment at
the point it mattered. See also `spec-02`'s cross-reference table: `preview`,
`done`, `artifact-add`, and `send --about` are only defined by
`09-closed-loop-surfaces.md`, which was not part of this build's reading set
(only `spec-00/01/02/04/05/07`), so all four are implemented from
`02-command-surface.md`'s cross-reference table and prose alone.

- **"Live" for name-uniqueness** (`session.json`'s `name` field is "unique
  among live sessions") is read as "not yet in a terminal state"
  (`done`/`failed`/`stopped`); `orphaned` counts as live since it can still
  be reopened.
- **`--from <session>` on `new`** is accepted even though
  `02-command-surface.md`'s own signature line for `new` omits it;
  `04-permission-modes.md` names it explicitly ("The default flips to
  shared the moment `--from <session>` is set"), so this build treats that
  as the authoritative source for the flag's existence and wires it to
  `lineage.parent_id`, the depth/children limits, and the mode default.
- **No persistent event subscriber.** This is a CLI, not a daemon: nothing
  here runs `events_subscribe` in a loop. `new`/`open` treat a *successful*
  `agent.start` reply as standing in for "Herdr confirms the agent
  appeared" and move straight from `starting` to `working`. A session whose
  `agent.start` never returns (Herdr unreachable) is left in `starting`
  with `runtime: null` and is never pushed into `failed`, no event
  fabricates a report neither Herdr nor a human actually made.
- **`capture --screenshot` maps to `capture window`**, not `capture region`
  (the shell layer's `README-shell.md` explicitly left this mapping as
  "core's decision"), falling back to `fullscreen` if the compositor call
  fails or produces no file.
- **An adopted session's mode** (`reconcile` finding a live Herdr agent with
  no Omarchy record) defaults to `shared`, since Personal's trust model, a
  human already watching, can't be asserted for a pane Omarchy didn't
  launch.
- **`ori`, bare (no wrapped harness)** is treated exactly like `pi` (refuse
  for shared/restricted, nothing needed for personal), per
  `04-permission-modes.md`'s own "treat it like pi until the rig says
  otherwise." This build has no syntax for naming a *wrapped* harness
  (`ori claude`) since `--agent <kind>` is a single token in
  `02-command-surface.md`; wrapped-`ori` resolution is unimplemented.
- **`verify_on_rig` granularity**: the task asked for this flag "on the
  rows the spec marks." `04-permission-modes.md` marks specific *cells*
  (e.g. only Codex's Personal cell, not its Shared/Restricted cells), so
  this build sets `verify_on_rig` per (harness, mode) cell instead of per
  harness row, the finer-grained reading, and the one the deny-list logic
  actually needs. The literal `(verify on rig)` markers plus every harness
  named in `04-permission-modes.md`'s own bottom "Verify on rig" list are
  both folded in (see the `HARNESS_TABLE` entries for `codex`, `crush`,
  `grok`, `agy`, `omp`, `hermes`, and `pi`).
- **`send`'s stored instruction text stays unmarked.** The marker line is
  applied only to the string actually sent to Herdr's `agent.prompt`, not
  written into the queued instruction's own `text` field in
  `events.jsonl`/`session.json`; `origin_session` already carries the
  provenance in structured form, and `01-session-model.md` frames the
  marker as something delivery adds, not something the stored instruction
  carries.
- **A dropped-on-delivery instruction always uses reason `agent_blocked`.**
  `02-command-surface.md` names three drop reasons (`agent_blocked`,
  unbound, ended) without saying which applies when Herdr is reachable but
  answers `agent.prompt` with an error; this build's only such path (a
  `HerdrError` from `agent.prompt`) uses `agent_blocked` and exits 5, since
  `send`'s own exit table includes 5 ("the session's state forbids the
  operation"). A `HerdrUnavailable` (socket gone) is treated differently:
  the instruction is left queued (not dropped) and the command exits 4, on
  the theory that the harness's own state is simply unknown, not blocking.
- **Exit codes for `preview`, `artifact-add`, and `done`** (defined outside
  `02-command-surface.md`, which gives no Exit line for them) are chosen by
  analogy to the closest sibling command already in that file's table
  (`preview`/`artifact-add` mirror `capture`'s 0/2/3; `mode` uses 0/3/5 plus
  4 when a bound relaunch needs Herdr; `done` uses 0/2/3).
- **`env_summary`'s shape** (`started_with.env_summary`) is undefined by
  `01-session-model.md`; kept to two harmless keys (`shell`, `term`) rather
  than a full environment dump, on purpose.
- **Herdr's configured `worktrees.directory`** is never queried, there is
  no method for it in the required `HerdrClient` list, so
  `herdr_worktrees_directory()` always uses the documented default
  (`~/.herdr/worktrees`, overridable here only via a test-only
  `HERDR_WORKTREES_DIR` env var this build invented, not part of the spec).
- **`git_safe_ref`** is a plain ASCII-oriented sanitizer, not a full
  `git check-ref-format` reimplementation; unicode/emoji names are
  `07-worktrees.md`'s own open question, unchanged here.
