# Evaluation run 13, pause and prune: raw evidence

Run 13 on 2026-09-03, 15:07 to 15:09 PDT (UTC 22:07Z to 22:09Z in the files), on `slice-4/pause` (specs at `2e82366`, core at `84cd60f`, the plugin in the commit after), Herdr 0.8.2, Claude Code 2.1.259, driven over ssh by `setup/run13-pause.sh` with the panel's own identity set through `OMARCHY_ACTOR`, so the panel's keys act with own access. Findings: `findings/evaluation-run13-pause-2026-09-03.md`. The rig had no live sessions and no Herdr agents before the run; it was left the same way.

| File | What it is |
|---|---|
| `timeline.txt`, `sid` | the step log; the session id (`pause-page`, a worktree of the spike repo from `session/loop-hello`, one instruction answered before the pause) |
| `panel-live-row.jpg` | the panel with the cursor on the live row: ⏎ Open, s Send, a Add, z Pause, x Stop; the hero "1 idle" |
| `panel-paused.jpg` | five seconds after `z`: a PAUSED section, the row "paused" with a hollow dot, ⏎ Resume, s Send, x Stop; the hero "1 paused" |
| `receipt-checkpoint.json` | the receipt written at the pause: `end_state` null, 18 s of duration, no commits yet |
| `panel-resumed.jpg` | after Enter on the paused row: the session under Working, idle |
| `pane-after-resume.txt` | the resumed pane, read through Herdr: the 3:07 PM turn ("Say hello in one line and nothing else." and "Hello!") above a fresh prompt, the same harness ref (`eaebfe84…`) |
| `events.jsonl`, `loop-view.txt` | the session's log and loop view: idle → paused → working → idle → stopped |
| `prune-dry-run-30d.txt`, `prune-dry-run-one.txt`, `prune-refusals.txt` | `prune --older-than 30d` (nothing that old; four kept as someone else's), `prune --session rig-smoke` ("would delete … 3 KB; add --yes to delete", nothing deleted, 53 records before and after), the refusals for a live session (5) and for `2h` (2) |

Every capture is cropped to the panel. The four "kept" lines name evaluation sessions that belong to the ssh identity from runs 10 to 12, which is run 10's ownership rule at work: prune from one identity never takes another's records.
