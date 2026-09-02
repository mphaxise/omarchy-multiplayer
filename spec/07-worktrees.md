# Workspaces and worktrees

Status: proposed, 2026-09-01. Slice 1.

## When a session gets a worktree

`session new` creates a worktree by default whenever the current directory sits inside a git repository and `--no-worktree` is absent. A session started from `~/Work`, or any directory outside a git repo, gets a plain directory instead: `workspace.repo_root` is `null`, `worktree_path` is that directory itself, and `branch` and `base_branch` are both `null`, since there is no history to branch from. `--no-worktree` gets the same plain-directory treatment even inside a repo, for a session that means to work on the checkout directly.

## Where worktrees live

New worktrees go under Herdr's own `worktrees.directory`, default `~/.herdr/worktrees`, instead of a location Omarchy invents. Herdr already groups a worktree it opens as a workspace under its parent in the sidebar, so reusing its directory means a session's worktree shows up there for free, and one setting controls the location for both tools.

The cost is discoverability from the shell. Omarchy's own `ga` helper creates a worktree and branch beside the repo, so `cd ../repo-feature` finds it without knowing any convention. A worktree under `~/.herdr/worktrees` is a `cd` away from nowhere obvious; a person has to ask the session panel or `herdr` where it put things. Claude Code's own `-w`/`--worktree` flag adds a third convention, `<repo>/.claude/worktrees/<name>`, which does not apply here because Omarchy creates the worktree itself before it execs the harness. The harness never gets to pick.

## Branch and record

The branch is `session/<name>`, `<name>` being the session's own name run through git's ref-name rules. `base_branch` is whatever branch was checked out in the original repo at the moment `session new` ran, captured before the worktree exists.

`workspace` in `session.json` is filled once, before `session.created` fires: `repo_root` from the git top level of the starting directory, `worktree_path` from where the worktree landed, `branch` and `base_branch` as above, and `created_by_session` set `true` because this session's own creation made the worktree.

## Sharing a worktree

A worktree is shared only through `--worktree <path>` at `session new`, and only when both the session that made the worktree and the session joining it record `created_by_session: false`. That is invariant 6 from `01-session-model.md`: two sessions never share a worktree unless both name the same `worktree_path` and both say `false`. Neither side ever claims ownership, on purpose: cleanup at `stop` and `done`, below, only ever touches a worktree its own session created, so a shared worktree is never removed out from under the session still using it. Sharing therefore starts from a worktree nobody's `session new` auto-created, made ahead of time by hand or inherited from a session that has since ended.

## Cleanup at stop and done

Cleanup runs only when `created_by_session` is `true`. The branch is always kept, in every case, matching invariant 7: deleting history is not a thing any slice 1 command does.

| Worktree state | Action |
|---|---|
| Uncommitted changes present | Keep the worktree, keep the branch |
| Committed but not pushed to any remote and not merged into `base_branch` | Keep the worktree, keep the branch |
| Clean, and merged into `base_branch` or pushed to a remote | Remove the worktree, keep the branch |

This mirrors OpenClaw's managed-worktree rule, which also only cleans up a worktree that is clean and pushed, and Herdr's own `worktree.remove`, which runs `git worktree remove` without deleting the branch already. Ours adds one thing: a merge into `base_branch` counts as safe to remove even without a push, since the work already reached the branch it started from. What happened, kept or removed and why, is written into the receipt as `workspace.worktree_removed` and a one-line reason, alongside the fields below.

## The receipt's commits and diff stat

Both are computed against `base_branch`, not against whatever the remote thinks main is. `commits` walks the range from `base_branch` to `branch` and records each `{sha, subject, author}`. `diff_stat` diffs `branch` against the merge base with `base_branch` and reports files changed, insertions, and deletions. `dirty` reflects whether the worktree has uncommitted changes at the moment the receipt is written, and `unpushed` reflects whether `branch`'s tip commit exists on any configured remote. A partial receipt written mid-session recomputes all four the same way, so a crash leaves numbers that were true a moment ago, not stale ones from creation.

## Relationship to `ga`/`gd` and Herdr

When the runtime backend is Herdr, the launcher calls Herdr's `worktree.create` at `session new`, `worktree.open` when `session open` re-binds an orphaned session to a new pane, and `worktree.remove` at cleanup. When there is no Herdr backend, the launcher does the same three things by hand: `git worktree add <path> -b session/<name> <base_branch>`, a plain `cd` for reopen, and `git worktree remove <path>` for cleanup, keeping the branch exactly as Herdr's own call would.

`ga` and `gd` stay a person's own tool, untouched by any of this. They create and remove worktrees beside the repo for manual work that never becomes a session. The one rule worth stating: `gd` deletes the branch it removes, so it should never be pointed at a worktree a session owns. Stop the session first; the cleanup table above is what should delete that worktree, not `gd`.

## Crash diagnosis

A crash-diagnosis session gets no worktree by default. It reads the system, coredumps, `journalctl`, process state, not a checkout, so `workspace.repo_root` and `worktree_path` are both `null` and it runs from wherever `omarchy-agent-crash` points it, typically `~/Work`, the same default `omarchy-agent` itself falls back to, or the crashed program's own project if the crash names one. If the diagnosis turns into an actual patch to a repository, that session can still request a worktree the normal way; it just does not start with one.

## Verify on rig

- Herdr's `worktrees.directory` key name and its default path on the installed version.
- Whether `worktree.remove` leaves the branch alone on every backend Herdr supports, beyond the common ones already checked.
- `git branch -r --contains <sha>` cost as the unpushed check on a large repo with many remotes.
- Whether git ref-name sanitizing for `session/<name>` needs a stronger rule than replacing illegal characters, for names with unicode or emoji.
- Whether `omarchy-agent-crash`'s working directory choice matches what the diagnose-crash skill actually expects when no project is named.

## Sources

Herdr, worktree and workspace concepts, herdr.dev/docs, observed 2026-09-01. OpenClaw, managed worktrees, docs.openclaw.ai, observed 2026-09-01. Omarchy `bin/omarchy-agent`, crash flow, and the `ga`/`gd` shell functions, branch quattro, observed 2026-09-01, as read into the context pack. Claude Code, `-w`/`--worktree`, code.claude.com/docs/en/cli-reference, observed 2026-09-01. `01-session-model.md`, this project, for the record shape and invariants 1, 6, and 7.
