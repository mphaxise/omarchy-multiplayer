# Agent lanes: several agents on one goal inside one session

Status: proposed 2026-09-03 (slice 2a); the core and its tests exist as of the same day, the panel and the rig run follow. Builds on `01-session-model.md` (lineage), `07-worktrees.md`, `05-receipts-and-artifacts.md`, and `03-sessions-panel.md`. The question it serves is in `PLAN.md`, slice 2a: when two agents work one goal inside one session, each with its own task, does the person stay oriented and in control from the panel, and does the work land on one branch with the record showing which agent did what?

## The model

A session gains lanes. A lane is one agent with one task inside the session. The session keeps its goal, mode, owner, preview, and receipt; the lanes carry the agents.

On disk a lane is a child session, so no record migrates and every existing consumer (the watcher, the reconciler, the receipt, the loop view) already understands it. The child carries:

```
"lane":    {"name": "tests", "parent_id": "<session id>", "parent_name": "api-refactor"}
"lineage": {"parent_id": "<session id>", "children": [], "spawn_reason": "lane"}
"goal":    {"text": "<the task>", ...}
"name":    "api-refactor.tests"
```

The session's own agent is the lane named `main`. `lanes <session>` lists `main` first, then each added lane in the order it was added. A session with no added lanes is a slice-1 session, unchanged. Slice 1's depth limit of 3 and children limit of 5 apply: a session holds at most five added lanes, and a lane may spawn its own children within the depth limit.

## Runtime

Every lane runs as its own Herdr agent in its own pane inside the session's one Herdr workspace: `pane.split` beside the session's pane (direction `right` by default, `down` on request) with the lane's worktree as `cwd`, then `agent.start` in the new pane, then `pane.report_metadata` with the child's session id, the lane name, and the parent's id in `tokens`. Attaching the session shows the lanes side by side in one terminal window; `open --lane <name>` attaches that pane alone.

A lane needs a running session: `add` refuses when the session has ended or has no runtime (an orphaned session revives first, with Enter).

## Workspaces and attribution

Each lane gets its own worktree on the branch `session/<name>--<lane>`, cut from the session's branch, so two agents never edit one tree at once. The branch sits beside the session branch rather than under it because git refs cannot nest below an existing branch name. The worktree is made with plain git, on purpose: Herdr's `worktree.create` opens a workspace per worktree, and a lane lives as a pane inside the session's one workspace.

`--share-worktree` puts the lane in the session's own worktree for tasks that cannot collide (a copy pass and a build pass on different files); the record marks it `shared_with_session` and nothing merges at the end. A session with no branch of its own (created with `--no-worktree`, or outside a repository) can only hold shared lanes.

Commits are attributed by the lane they were made in, from the branch, at merge time, and the receipt lists them per lane. Trailers written by an agent are unverifiable, so attribution comes from the lane's worktree. A verified human identity stays a slice 3 concern (`08-identity-and-attribution.md`).

## Ending a lane

`done <session> --lane <name> --verdict kept|reverted|needs-person --note "<text>"` ends one lane. `kept` merges the lane's branch into the session's branch, in the session's worktree, with `git merge --no-edit`: a clean merge records `lane.merged` on the session with the commits and the range, and the lane ends as `done` the way a session does (verdict note, receipt, pane closed, worktree cleaned when it is clean and merged). A conflict aborts the merge, leaves both trees as they were, and puts the lane in `blocked` with the detail "merge conflict; open the lane to resolve", which routes through the existing needs-you path; the lane is not ended and the command exits 5. `reverted` and `needs-person` end the lane without merging.

Every ending, by verdict, by `stop`, or by the reconciler, runs the completion path the session model promised: the parent records `child.completed` with the lane's name and end state, and when the parent's own harness is live it receives a marked instruction, "lane <name> finished: <state> (<reason>)", so its agent learns the outcome without polling. A lane stopped because its parent stopped does not notify the parent.

`stop <session>` stops the session's own agent and every lane unless `--keep-lanes` (the existing `--keep-children`); `stop <session> --lane <name>` stops one lane. `pause <session>` pauses the lanes first and then the session's own agent, each with its own events and checkpoint receipt; `pause <session> --lane <name>` pauses one lane and leaves the session running. Resuming the session brings back its own agent only; a paused lane's line reads "paused" and resumes on its own Enter, through `w` (2026-09-03).

## Instructions

`send <session> "<text>"` on a session with live lanes goes to the session's own agent and every live lane, each as its own instruction record and delivery; `--lane <name>` targets one lane (`main` for the session's own agent). Feedback with a capture works per lane the way it works per session. A lane that asks a question or hits a permission prompt is the session's needs-you, named "<session> · <lane> needs you" on the toast, the badge, the hero, and the row.

## Permissions

A lane inherits the session's mode and may be stricter, never looser: a Personal session can hold a Shared or Restricted lane, a Shared session cannot hold a Personal one (`MODE_RANK`). The deny-list check runs per lane before exec, and signal 5's rule extends to every lane.

## Commands

| Command | What it does |
|---|---|
| `omarchy-agent-session-add <session> --agent <kind> --task "<text>" [--lane <name>] [--mode …] [--share-worktree] [--direction right\|down]` | pulls another agent in; the task is the lane's goal and its first instruction; the lane name defaults to the agent kind, made unique with `-2`, `-3` |
| `omarchy-agent-session-lanes <session> [--json]` | `main` first, then each lane: name, kind, state, task, branch, worktree |
| `omarchy-agent-session-open <session> --lane <name>` | attaches one lane's pane |
| `omarchy-agent-session-send <session> "<text>" [--lane <name>]` | one lane, or every live lane and `main` |
| `omarchy-agent-session-done <session> --lane <name> --verdict … --note …` | ends one lane; `kept` merges |
| `omarchy-agent-session-stop <session> [--keep-lanes] [--lane <name>]` | as above |
| `omarchy-agent-session-pause <session> [--lane <name>]` | lanes first, then the session; `--lane` for one lane |

`list --json` carries `lane` on a lane's entry (`{name, parent_id, parent_name}`) and `lanes` on a session's entry (the added lanes with state, task, kind, branch). The panel groups lane entries under their session and never shows them as top-level rows.

## Events

`lane.added` on the session (`lane`, `child_id`, `agent.kind`, `task`, `mode`); `lane.merged` on the session (`lane`, `child_id`, `branch`, `into`, `commits`, `range`); `child.spawned` and `child.completed` as the session model defines, with `lane` in the data. The loop view renders them as `lane <name> added (<kind>): <task>`, `lane <name> merged <n> commit(s) <range> into <branch>`, and `lane <name> ended <state> (<reason>)`. The receipt of a session gains `lanes`, one entry per added lane with its end state and merged commits; the receipt of a lane names its session.

## The panel

A session row with lanes gains one line per lane under the goal: dot, lane name, agent kind, state, the task elided. `w` walks the cursor through a session's lanes so Enter, `s`, `x`, and `p` act on a lane; the legend shows "w lane" only when the cursor row has lanes (`l` is an arrow key in the shell's key catcher). `a` on a live session opens a field, "Add an agent: <kind> <task>", with the default agent prefilled, in the same place the `n` field opens. The hero counts lanes that need you across sessions, and needs-you ranking names the lane. A session with lanes stays one row until the cursor is on it, so signal 1's first row is unchanged.

## Success signals

The five in `PLAN.md`, slice 2a, measured on the rig with captures: a lane pulled in from the panel with `a` and nothing else; each lane's state and task on the cursor row, and a lane that asks named first everywhere with the lane's name in the text; both lanes' commits on the session branch through `done --lane` with the receipt listing commits per lane and a forced conflict shown as a blocked lane; `send` with and without `--lane` recorded per delivery; every slice-1 signal still passing on a session with lanes.

## Verify on rig

- Whether Herdr's status detection reads the right pane when two agents share one workspace; if it does not, lanes fall back to separate workspaces (`PLAN.md`, decision 1).
- Whether `pane.split` returns the new pane's `tab_id` and `workspace_id` in the shape assumed here (`pane` or top level).
- Whether `herdr agent attach <alias>` on the session's own agent shows the lane panes beside it, or only its own pane.
- The row budget with five lanes on the cursor row at 640 px.
