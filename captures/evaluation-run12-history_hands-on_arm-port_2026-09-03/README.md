# Evaluation run 12, history and resume: raw evidence

Run 12 on 2026-09-03, 14:29 to 14:33 PDT (UTC 21:29Z to 21:33Z in the files), on `slice-4/history` at `a97d43c` plus the plugin commit that followed, Herdr 0.8.2, Claude Code 2.1.259, driven over ssh by `setup/run12-history.sh`. Findings: `findings/evaluation-run12-history-2026-09-03.md`. The rig had no live sessions and no Herdr agents before the run; it was left the same way.

| File | What it is |
|---|---|
| `timeline.txt`, `sid` | the step log; the session id (`restart-page`, run 11's session: stopped at 09:23 PDT with a transcript, a worktree of the spike repo) |
| `panel-done-today-earlier.jpg` | the panel after the shell restart: "31 DONE TODAY", the `restart-page` row "stopped · resumes conversation" with ⏎ Resume and r Receipt, "29 more · →", and under the section "18 earlier · e" |
| `panel-done-expanded.jpg` | the same panel after →: Done today expanded, the list scrolling |
| `panel-resumed-working.jpg` | the panel 13 s after `open`: `restart-page` under Working, idle |
| `events.jsonl`, `loop-view.txt` | the session's log and loop view: stopped → orphaned "resumed after a stop; worktree re-created" → working → idle on `open`, then stopped again at the end of the run |
| `pane-after-resume.txt` | the resumed pane, read through Herdr: the 09:22 turn ("Say hello in one line and nothing else." and "Hello!") above a fresh prompt, in `~/.herdr/worktrees/restart-page`, the same harness ref (`86cfa28c…`) |
| `history.txt` | `omarchy-agent-session-history` over ssh, cut after the Thursday block |
| `history-window.jpg` | the History window `e` opened from the panel, cropped to the header and the Thursday block |

Every capture is cropped to the panel or to the History window's first block. The Wednesday block of the history, 39 sessions, is cut from both the text and the capture because it lists sessions of Praneet's own beside the evaluation ones. `list --ended-within 24h --json` was 35,345 bytes for 31 sessions during the run; the same list without the window was 54,453 bytes, against the panel's 64 KB cap. The history read over ssh says 46 ended and the window on the rig says 48: the two are different identities (`omarchy@_gateway` over ssh, the rig's own user at the panel), and two private drafts from run 10 belong to the rig's user alone, which is the run-10 visibility rule doing its job.
