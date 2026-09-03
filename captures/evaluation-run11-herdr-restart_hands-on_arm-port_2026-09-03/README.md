# Evaluation run 11, a Herdr restart with a live session: raw evidence

Run 11 on 2026-09-03, 09:22 to 09:24 PDT (UTC 16:22Z to 16:23Z in the files), on `main` after the slice-3 merge, Herdr 0.8.2 as the user unit `omarchy-agent-session-herdr.service`. Findings: `findings/evaluation-run11-herdr-restart-2026-09-03.md`. The rig had no live sessions and no Herdr agents before the run, which is the condition `CLAUDE.md` sets for restarting the server.

| File | What it is |
|---|---|
| `timeline.txt`, `sid` | the step log; the session id (`restart-page`, a worktree of the spike repo from `session/loop-hello`) |
| `events.jsonl`, `loop-view.txt` | the session's log and loop view: idle → orphaned "Herdr restarted; Enter revives" two seconds after the restart, orphaned → working on `open`, idle, stopped |
| `pane-after-revive.txt` | the revived pane, read through Herdr: the earlier turn ("Say hello in one line" and "Hello!") above a fresh prompt, the same harness ref |
| `panel-orphaned.jpg` | the panel after the restart: hero "1 orphaned · Enter revives", the row "orphaned · resumes conversation" with Revive, Send, Stop |

The capture is cropped to the panel and the bar's right end. The row reads "owned by omarchy@_gateway" because the session was created over ssh without the owner override, so the panel, running as the rig's own user, names the ssh identity as the owner; that is the run-10 rule doing its job, not a defect. The restart was `systemctl --user restart omarchy-agent-session-herdr`; the revive was `omarchy-agent-session-open`, the command the panel's Enter runs.
