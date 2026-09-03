# Evaluation run 1: raw evidence

Run 1 of the 16-step scenario in `spec/10-evaluation-plan.md`, driven over ssh from the Mac on 2026-09-02, 18:51 to 19:06 PDT (timestamps inside the files are UTC, 2026-09-03T01:51Z to 02:06Z). Build: commit cbac0e9 plus the rig's live copy. Provenance: hands-on, `live`, unofficial aarch64 port, software rendering. No stopwatch and no human at the keyboard; the findings say what that excludes.

| File | What it is | Signal |
|---|---|---|
| `started_at`, `timeline.txt`, `ids.txt` | run start, the step log with UTC times, the five session ids | all |
| `events/<id>.jsonl` | each session's event log at the end of the run | 2, 4 |
| `signal4-state-changes.txt` | every `status.changed` per session, from the event logs | 4 |
| `signal4-notifs.txt`, `notifications/`, `crash-notification.json` | toasts recorded by the shell during the run window (the `eval-shared needs you` toast at 01:56:49.356Z is in `timeline.txt`; its history file had been rotated by the time the folder was copied) | 1, 4 |
| `sessions-before-close.json`, `records-before-close.txt`, `panes-before-close.txt`, `windows-before-close.txt` | state before every terminal window was closed | 2 |
| `sessions-after-close.json`, `records-after-close.txt`, `panes-after-close.txt` | state after the windows were closed: records, `session.ended` counts, pane and harness pids | 2 |
| `transcripts-before-reattach.json`, `transcripts-after-reattach.json`, `panes-after-reattach.txt` | Claude transcript line counts and last message before and after reattach; pids after | 2 |
| `signal3-receipt.json`, `stop-issued-epoch`, `receipt-mtime-epoch` | the receipt written by step 14 and its write time against the stop | 3 |
| `process-info-after-create.txt`, `omarchy-agent-flags.txt`, `core-flags.txt` | the harness argv per session from Herdr's pane process info, Omarchy's own launch flags, the core's mode table | 5 |
| `send.out` | step 10's result | 1, 4 |
| `sessions-final.json` | the list at the end | all |
| `eval_transcripts.py` | the helper that produced the transcript snapshots | 2 |

Screens for this run are in `../screenshots/*_2026-09-02_live-run1*` and `evaluation-run1-final-panel_*`.
