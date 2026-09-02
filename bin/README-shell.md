# Shell and service pieces for omarchy-multiplayer slice 1

Proposed, 2026-09-01. Nothing here has touched the Omarchy VM. Everything
below is locally checkable only: syntax and unit-test level, not behavior
against Herdr, Hyprland, or a real `omarchy-notification-send` D-Bus call.

## Files

**`bin/omarchy-agent-session-<cmd>`** (17 files, one per subcommand: `new`,
`list`, `show`, `open`, `send`, `stop`, `rename`, `assign`, `goal`, `log`,
`receipt`, `capture`, `artifact-add`, `preview`, `mode`, `done`, `reconcile`).
Each is a thin `exec omarchy-agent-session-core <cmd> "$@"` wrapper with the
`omarchy:summary=`/`omarchy:args=`/`omarchy:examples=` headers Omarchy's own
`bin/omarchy-agent-crash` uses. 13 of the 17 (everything but `artifact-add`,
`preview`, `mode`, `done`) have their `omarchy:examples=` line copied
verbatim from an explicit `Example:` line in `spec/02-command-surface.md`.
The other 4 are defined in `spec/04-permission-modes.md` or
`spec/09-closed-loop-surfaces.md`, neither of which gives a literal
`Example:` line, so those four examples are synthesized from that file's
prose and flagged as such in the script's own comment.

**`bin/omarchy-agent-session`**: the bare group entry. Always prints a usage
listing of the 17 subcommands and exits 2 (the shared usage-error code).
Omarchy resolves `omarchy agent session <cmd>` straight to the sibling
`omarchy-agent-session-<cmd>` binary, so this script only runs for a
genuinely bare `omarchy agent session` call; kept to just that, per the task.

**`bin/omarchy-agent.proposed`, `bin/omarchy-agent-prompt.proposed`,
`bin/omarchy-agent-crash.proposed`**: modified copies of the real upstream
scripts (fetched from `omacom/omarchy`, branch `quattro`, 2026-09-01). Each
carries a `# proposed change for omarchy-multiplayer, 2026-09-01; diff
against quattro` header line.

- `omarchy-agent.proposed`: the entire per-agent `case "$agent" in ...` block
  that builds `command=(...)` is untouched, byte-for-byte, because `--inline`
  still uses it exactly as today (see Assumptions). Only the final
  `if [[ $inline == true ]] ... else ... fi` block's else-branch changes:
  instead of `exec omarchy-launch-tui --app-id=org.omarchy.agent
  "${command[@]}"`, it now calls `omarchy-agent-session-core new --agent
  "$agent" --mode personal [-- "$prompt"]`, then `omarchy-agent-session-core
  open <id>`.
- `omarchy-agent-prompt.proposed`: **no functional change**. It only forwards
  `--prompt` to `omarchy-agent`, and that's where the new behavior lives per
  `02-command-surface.md`'s own framing ("omarchy agent prompt ... calls
  session new ..., then open"), so once `omarchy-agent` is the proposed
  version this file needs nothing further. Kept as its own reviewable copy
  with a comment explaining why the diff is otherwise empty.
- `omarchy-agent-crash.proposed`: **does** need new logic, because
  `session new --name "crash-<pid>" --goal "..."` needs flags `omarchy-agent`
  has no way to pass through. It calls `omarchy-agent-session-core` directly
  instead of delegating, which means it also repeats omarchy-agent's own
  default-agent resolution, not-installed check, and `~/Work` cd rule (copied
  verbatim, commented as copied).

**`systemd/omarchy-agent-session-watch.service`**: a user unit. `[Unit]
PartOf=`/`After=graphical-session.target`, `[Service] Type=simple`,
`Restart=always`, `[Install] WantedBy=graphical-session.target` are copied
from the real `omarchy-crash-watch.service` (also fetched from quattro). The
file's own header comment states every field that's copied vs. assumed;
see Assumptions below for the two real deviations (`RestartSec`, `ExecStart`).

**`bin/omarchy-agent-session-watch`**: the notification daemon, Python 3
standard library only (`argparse`, `json`, `socket`, `subprocess`,
`threading`, `collections`, `dataclasses`, `pathlib`). Tails every session's
`events.jsonl` under `OMARCHY_SESSIONS_DIR`, with a cursor per session
persisted in `OMARCHY_SESSIONS_DIR/.watch-cursors.json`; optionally starts a
background thread that connects to `HERDR_SOCKET` purely to wake the tail
loop sooner (never to decide what to notify, `events.jsonl` stays
authoritative, per the spec). Implements the notify-worthy event table, the
text templates, `--urgency`/`--exec` via `omarchy-notification-send`,
10-second per-session coalescing via `--replace-id`/`--print-id`,
self-suppression via `hyprctl activewindow -j`, a fullscreen hold-and-flush,
and the more-than-3-in-60s digest. `--dry-run` prints the argv instead of
calling the binary. Two flags beyond the spec, added for testability:
`--once` (one scan pass, exit) and `--sessions-dir` (override the env var).

**`tests/test_watch.py`**: 18 unit tests, all passing (see below), covering
event classification, coalescing, the digest (including its distinct-session
counting and window reset), self-suppression, the fullscreen hold/flush, and
cursor persistence across a simulated restart.

## Verified locally

- `bash -n` on all 20 shell scripts (17 subcommand wrappers + the group
  script + the 3 `.proposed` files): all pass.
- `shellcheck`: **not available in this environment** (`which shellcheck`
  found nothing); not run. `bash -n` is the only shell-syntax check applied.
- `python3 -m py_compile` on `bin/omarchy-agent-session-watch` and
  `tests/test_watch.py`: both pass.
- `python3 -m unittest test_watch -v`: **18/18 pass**, 0.008s. Summary:

  ```
  test_coalescing_is_per_session ... ok
  test_event_after_10s_does_not_replace ... ok
  test_second_event_within_10s_replaces_the_first ... ok
  test_cursor_file_is_valid_json_on_disk ... ok
  test_restart_does_not_replay_already_seen_events ... ok
  test_digest_resets_after_a_full_quiet_window ... ok
  test_fifth_event_updates_the_same_digest_by_distinct_session_count ... ok
  test_fourth_distinct_session_in_60s_becomes_one_digest ... ok
  test_dry_run_prints_the_argv_instead_of_calling_the_real_binary ... ok
  test_child_completed_names_parent_and_child ... ok
  test_failed_is_critical_with_detail ... ok
  test_orphaned_is_a_status_changed_variant ... ok
  test_waiting_and_blocked_notify_at_normal ... ok
  test_working_idle_and_instruction_delivered_do_not_notify ... ok
  test_a_second_event_held_during_fullscreen_overwrites_the_first ... ok
  test_focused_session_is_never_notified ... ok
  test_fullscreen_holds_the_notice_until_fullscreen_ends ... ok
  test_unfocused_session_still_notifies_when_a_different_window_is_active ... ok

  Ran 18 tests in 0.008s
  OK
  ```
- A manual smoke test of the real CLI entry point (not just the test
  harness): `OMARCHY_SESSIONS_DIR=<tmp> omarchy-agent-session-watch --once
  --dry-run` against one hand-written `session.json` + `events.jsonl`
  correctly printed one notification argv and wrote a valid
  `.watch-cursors.json`; `--help` renders correctly.
- Confirmed against the real `bin/omarchy-notification-send` source (fetched
  from quattro, not from the spec, which only guesses here): `--urgency`
  really does accept `low`/`normal`/`critical`; `-r`/`--replace-id <id>` and
  `-p`/`--print-id` really do exist. This resolves two of
  `06-notifications.md`'s own "verify on rig" bullets at the source-code
  level, the flags exist, while the runtime/D-Bus behavior on the rig
  (does a replace actually update the visible toast) is unchanged, still
  VERIFY ON RIG.

## VERIFY ON RIG (carried from the spec, or newly identified)

- Whether `session new` prints the created session's id to stdout, see
  Assumptions; this is load-bearing for both `.proposed` launchers and isn't
  settled by anything I read.
- The exact `hyprctl activewindow -j` field for app id (`initialClass` vs.
  `class` vs. something else) and for fullscreen (int vs. bool, which
  values), spec's own open item, coded as a best-guess in
  `is_session_focused`/`is_fullscreen`, wrapped in try/except so a wrong
  guess degrades to "never suppress" instead of crashing or over-suppressing.
- `HERDR_SOCKET`'s transport and protocol entirely: whether it's a Unix
  domain socket, whether `events.subscribe`/`pane.agent_status_changed` are
  the right method/filter names, whether the stream really is
  newline-delimited JSON. Wrapped in try/except with backoff; a wrong guess
  only costs latency since the local `events.jsonl` tail is authoritative.
- Whether `omarchy-notification-send -r/--replace-id` actually replaces the
  visible toast in place on the rig's notification daemon (flags confirmed
  to exist in source; D-Bus-level effect unconfirmed).
- Whether a Wayland/compositor precondition (like crash-watch's
  `ConditionEnvironment=WAYLAND_DISPLAY`) should gate the systemd unit, since
  self-suppression and the fullscreen hold both need `hyprctl` to mean
  anything.
- `RestartSec=2` on the systemd unit vs. crash-watch's real `RestartSec=5` , 
  see Assumptions.
- Every "verify on rig" item already listed in `spec/02-command-surface.md`,
  `spec/04-permission-modes.md`, `spec/05-receipts-and-artifacts.md`,
  `spec/06-notifications.md`, and `spec/07-worktrees.md` that this build
  didn't have to resolve to write these files (worktree/Herdr resume
  mechanics, per-harness exit sequences, etc.), unchanged, not re-listed
  here.

## Assumptions the spec didn't settle

1. **`session new`'s stdout contract.** `02-command-surface.md` gives `new`
   no `--json` flag and states no stdout contract at all. Both
   `.proposed` launchers need the new session's id to chain into `open`, so
   they assume `new` prints the id to stdout on success (exit 0) and treat
   an empty result as an error. This is the single biggest assumption in
   this build, everything about "create, then open" depends on it, and is
   worth confirming with whoever owns `omarchy-agent-session-core` before
   either `.proposed` file is taken further.

2. **`--inline` is untouched, deliberately.** Neither
   `02-command-surface.md`'s wrapper section nor any other file read for
   this task mentions `--inline`, and a session's `open` always attaches a
   *new terminal window*, there's no session-model equivalent of "run in the
   current shell, no window." Instead of inventing one, `omarchy-agent.proposed`
   keeps `--inline` exactly as it works today (direct exec of the harness,
   bypassing the session system entirely), and only rewires the
   keybinding/menu (non-inline) path. This is why the whole per-agent
   `command=(...)` case statement stays in the file unchanged.

3. **Permission mode defaults to `personal` for both `omarchy agent` and
   `omarchy agent crash`.** For `omarchy agent`, `04-permission-modes.md`
   states this explicitly ("Left unset, the default is personal for a
   keybinding launch, matching omarchy-agent today"), so that part is
   confirmed, not assumed, but `02-command-surface.md`'s own wrapper-section
   sentence, "(mode from omarchy-default-agent unless given...)", reads
   ambiguously (see #4), so the mode was set explicitly from
   `04-permission-modes.md`'s clearer rule instead of trusting that
   sentence. For `omarchy agent crash`, no file read for this task states a
   mode at all; personal was chosen by analogy (a notification click is a
   person present, same as a keybinding).

4. **What "(mode from omarchy-default-agent unless given...)" means.**
   `02-command-surface.md`'s literal text for `omarchy agent`'s wrapper
   behavior is ambiguous: `omarchy-default-agent` is the existing shell
   function that names an *agent kind* (claude, codex, ...), not a
   personal/shared/restricted *mode*. Read here as being about agent-kind
   selection (already existing behavior, unchanged), not permission mode.
   Flagged instead of silently resolved either way.

5. **No new `<kind>` positional on `omarchy agent`.** The same sentence's
   heading, "omarchy agent [<kind>]", could be read as adding a new CLI
   argument letting `omarchy agent claude` pick a kind directly, which the
   original script never accepted. Not implemented, since the "Stays" list
   right below it names only "the eleven agent choices" (via
   `omarchy-default-agent`), not a new argument, and adding one would be a
   bigger change than the task's "smallest change" framing asked for.

6. **`session.orphaned` is `status.changed` with `data.to == "orphaned"`,
   not its own event type.** `06-notifications.md`'s notify table lists a
   row literally named `session.orphaned`, but `01-session-model.md`'s
   event-type table has no such type, and its state machine + `reconcile`'s
   own spec (`02-command-surface.md`) both describe orphaning as a
   `status.changed` transition. The watcher follows 01/02 (the session model
   and command surface are the two files that own this), and
   `test_orphaned_is_a_status_changed_variant` in `test_watch.py` pins the
   behavior down. Worth a one-line fix in `06-notifications.md` itself.

7. **Digest counts distinct sessions, not raw events.** "4 sessions need
   you: 2 waiting, 1 blocked, 1 failed" reads as a session count, and the
   watcher tracks one entry per session (most recent kind wins) instead of
   a flat log of every notify-worthy event in the window, so a single
   session flapping between states several times in one minute is still
   "1 session," not several. The spec's own worked example doesn't
   distinguish these two readings because no session repeats in it;
   `test_fifth_event_updates_the_same_digest_by_distinct_session_count`
   exercises the case where they'd disagree.

8. **Digest urgency** is the highest of critical/normal/low among the kinds
   in the current window (a burst containing a `failed` is never quieter
   than that failure alone would have been). Not stated anywhere.

9. **A digest, once started, keeps replacing itself via `--replace-id`** as
   more sessions join the same still-open 60-second window, rather than
   stacking additional digest toasts. Resets (next digest starts fresh) once
   the window decays back to 3 or fewer flagged sessions. The spec states
   the *trigger* for one digest but not what happens on a 5th, 6th, etc.
   event within the same still-open window.

10. **A second notice held for the same session during fullscreen overwrites
    the first**, rather than queuing both. Extends "one pending notice per
    session" (stated for live coalescing) into the hold queue, since nothing
    in the spec says what a second event for one session should do while
    the first is still waiting out a fullscreen window.

11. **`child.completed`'s click target and self-suppression check use the
    *parent* session's id** (whose `events.jsonl` carries the event), not
    the child's. Neither `01-session-model.md` nor `06-notifications.md`
    states which id `--exec omarchy-agent-session open <id>` should carry
    for this one event type.

12. **`capture --screenshot`'s internal granularity.** `02-command-surface.md`
    gives `capture` one `--screenshot` flag; `05-receipts-and-artifacts.md`
    describes the underlying mechanism as two distinct compositor calls,
    `capture window` and `capture region`. The wrapper only forwards
    `--screenshot` (matching 02, the authoritative command-surface file) and
    flags the mismatch rather than guessing which of window/region it should
    become, that mapping is core's decision.

13. **`RestartSec=2` and the `ExecStart` path on the systemd unit** are
    followed from the task's literal instruction and from
    `06-notifications.md`'s own literal `ExecStart` line, respectively, both
    of which differ from the real `omarchy-crash-watch.service`
    (`RestartSec=5`, `ExecStart=/usr/bin/omarchy-crash-watch`). See the
    unit file's own header comment for the full reasoning.

14. **Four wrapper examples are synthesized, not verbatim.** `artifact-add`,
    `preview`, `mode`, and `done` are defined in spec files that describe
    their syntax but give no literal `Example:` line (unlike the 13 commands
    `02-command-surface.md` documents directly); each synthesized example is
    built from that file's own prose usage and marked as synthesized in the
    script's comment.
