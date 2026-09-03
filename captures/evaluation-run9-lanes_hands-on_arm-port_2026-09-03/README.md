# Evaluation run 9, agent lanes: raw evidence

Run 9 on 2026-09-03, 08:38 to 08:44 PDT (UTC 15:38Z to 15:44Z in the files), driven over ssh with `wtype` pressing the keys, on `slice-2/lanes`. Findings: `findings/evaluation-run9-lanes-2026-09-03.md`.

| File | What it is |
|---|---|
| `timeline.txt`, `ids.txt` | the step log; the session id (`lanes-page`, a worktree of the spike repo from `session/loop-hello`) |
| `lanes-after-add.json` | `lanes --json` after the second agent was added from the panel: `main` and `claude`, both working |
| `events.jsonl`, `loop-view.txt`, `receipt.txt`, `receipt.json` | the session's log, its loop view after the verdict, and its receipt with the Lanes section |
| `panel-add-typed.jpg`, `panel-after-add.jpg` | the `a` field with the task typed; the row after Enter ("agent added") |
| `panel-lanes-row.jpg`, `panel-lane-selected.jpg`, `panel-lane-send.jpg` | the lane line under the goal; `w` selecting the lane; `s` opening "Send to lane claude…" |
| `panel-conflict-needs-you.jpg` | the toast "lanes-page · copy needs you", the badge, the session under Needs you with "copy needs you", the lane line in urgent |
| `run9.sh` | the step script (`setup/run9-lanes.sh`) |

Every capture is cropped to the panel and the bar. Two fixes landed during the run and are in the branch: `Array.isArray` is false for a QVariantList in a delegate, so lane lines never showed until the check became a length test; and `l` is an arrow key in the shell's key catcher, so the lane walker moved to `w`. A third change followed the run: watch notices stopped reporting `runtime.bound` and working/idle flips, which had started a turn on the session's own agent for each one.
