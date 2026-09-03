# Evaluation run 9: agent lanes on the rig

Status: hands-on, `live`, 2026-09-03, 08:38 to 08:44 PDT, on `slice-2/lanes` at Omarchy `0b3f1b7` (the aarch64 image), Herdr 0.8.2, Claude Code 2.1.259, driven over ssh with `wtype` pressing the keys. Raw evidence: `captures/evaluation-run9-lanes_hands-on_arm-port_2026-09-03/`. The spec is `spec/11-agent-lanes.md`; the signals are `PLAN.md`, slice 2a.

## The result

All five slice-2a signals hold on this rig for two Claude Code lanes, with the mechanism as the thing measured: the second agent came in from the panel's `a` field alone, the lane's state and task showed on the row and a blocked lane was named first on every surface, one lane merged onto the session branch and the other conflicted into a visible `blocked` with nothing lost, `send` reached one lane or every lane as asked, and the session survived, ended, and left a receipt with a Lanes section. Three defects surfaced and are fixed in the branch. What the run cannot say is whether a person stays oriented on this; the instructions were scripted and the sitting is still ahead.

## What happened

Session `lanes-page`, a worktree of the spike repo from `session/loop-hello`, intent "hello.html gains a footer and a test file, from two agents / README.md stays untouched / Both lanes land on the session branch".

| Time (UTC) | Step | Evidence |
|---|---|---|
| 15:38:35 | `new`, one agent, idle at 15:38:41 | `timeline.txt` |
| 15:39:00 | Panel: `a`, the task typed ("claude Add a file tests.md …"), Enter | `panel-add-typed.jpg`, `panel-after-add.jpg` |
| 15:39:09 | `lanes`: `main` and `claude`, both working; Herdr lists `lanes-page` in `w2:p1` and `lanes-page-claude` in `w2:p2` | `lanes-after-add.json`, `timeline.txt` |
| 15:41:11 | Panel: the lane line "claude · claude · working · Add a file tests.md t…" under the goal; `w` selects it; `s` opens "Send to lane claude…" | `panel-lanes-row.jpg`, `panel-lane-selected.jpg`, `panel-lane-send.jpg` |
| 15:42:46 | `send --lane claude`: one delivery to the lane. `send` without `--lane`: one to main, one to the lane | `timeline.txt`: main 4 delivered, lane 3 delivered |
| 15:43:01 | `add --lane copy` with a task that edits README.md; main edited README.md too; `done --lane copy --verdict kept` | exit 5, "CONFLICT (content): Merge conflict in README.md"; the lane `blocked` with "merge conflict; open the lane to resolve" |
| 15:43:45 | The toast "lanes-page · copy needs you", the badge, the session first under Needs you with "copy needs you", the lane line in urgent | `panel-conflict-needs-you.jpg` |
| 15:44:12 | `done --lane claude --verdict kept`: `lane.merged`, one commit, `f7d9519..bd1baac` into `session/lanes-page`; the parent got `child.completed` and a marked instruction | `loop-view.txt` |
| 15:44:13 | `done --verdict kept` on the session; the receipt's Lanes section: `claude done, 1 commit merged`, `copy stopped, nothing merged` | `receipt.txt` |

## Against the signals

1. **A second agent from the panel with the `a` field and nothing else.** Held. The field, Enter, "agent added", the lane running in the session's workspace as a second pane beside the first (`w2:p1`, `w2:p2`).
2. **Each lane's state and task on the cursor row; a lane that asks is named first everywhere.** Held. The lane line under the goal; on the conflict, the toast, the badge, the hero's section, the row's state slot, and the lane line all said "copy" and "needs you".
3. **Both lanes' commits on the session branch through `done --lane`; a conflict as a blocked lane, never silent loss.** Held for one lane merged and one conflicted; the merge aborted cleanly, both commits survived in their branches, and the receipt says which lane merged what.
4. **`send` with `--lane` reaches one lane; without it, every live lane and main, each recorded.** Held, by the delivery counts in both records.
5. **Every slice-1 signal still passes on a session with lanes.** Held for the parts this run exercised: the session and both lanes survived the panel closing and the shell restarts during the run, the receipt was written, `blocked` and `done` toasts arrived, no bypass flag outside Personal (both lanes Personal, as the session). A reboot with lanes was not run.

The `spec/11` "verify on rig" list: Herdr's status detection read the right pane with two agents in one workspace (the lane went blocked and idle on its own timeline while main stayed idle); `pane.split` returned the pane under `pane` with the workspace id; `herdr agent attach` on the session's own agent was not exercised (no terminal was attached during the run); the row budget with five lanes is untested.

## What the run found

1. **Lane lines never showed.** `Array.isArray` is false for a QVariantList, which is what a delegate's `session.lanes` is once the row object has passed through the model; the legend, reading the same data as a JS object, said "l lane" while the row stayed bare. Fixed: a length test.
2. **`l` is an arrow.** The shell's `PanelKeyCatcher` takes h, j, k, and l as arrows before `onTextKey`, so `l` expanded Done today. The lane walker is `w`.
3. **Watch notices were noise.** Every `runtime.bound` and working/idle flip on a lane became a marked instruction to the session's own agent, and each started a turn there (the loop view shows main flipping to working after each). Watchers now hear about the states that need a person or end the work, artifacts, merges, and endings, coalesced as before.

## Judgment

The parent agent hearing about its lanes is the right default for a session whose own agent coordinates; for a session whose main agent has its own task, the notices are interruptions. That is a mode question for the sitting: whether `main` should be told at all when the person is the coordinator.

## What this run cannot claim

That a person stays oriented on a two-lane session: the sitting is ahead. That five lanes fit the row. That attaching the session shows both panes side by side. That Codex works as a lane: the second harness has no login on the rig.
