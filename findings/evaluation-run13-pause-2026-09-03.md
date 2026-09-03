# Evaluation run 13: pause and prune

Status: hands-on, `live`, 2026-09-03, 15:07 to 15:09 PDT, on `slice-4/pause` (specs at `2e82366`, core at `84cd60f`, the plugin in the commit after), Omarchy `0b3f1b7`, Herdr 0.8.2, Claude Code 2.1.259, driven over ssh by `setup/run13-pause.sh`. Raw evidence: `captures/evaluation-run13-pause_hands-on_arm-port_2026-09-03/`. The change under test comes from Praneet's question once history was in (`decisions.md`, 2026-09-03, "Pause is a state"): do we need a pause, and should everything a person has not killed stay until cleaned up. This run checks the three pieces built for that: the `paused` state and the panel's `z`, Resume from a paused row, and `prune` as the one explicit deletion.

## The result

All three hold. With the cursor on a live row the panel offered ⏎ Open, s Send, a Add, z Pause, x Stop, five buttons on one line at 400 px. One press of `z` paused the session: the harness exited (Herdr's agent list went from one to none), the pane closed, the record went idle → paused with no runtime, a checkpoint receipt was written with `end_state` null, and the worktree stayed at `~/.herdr/worktrees/pause-page`. The panel moved the row into a PAUSED section, "paused" with a hollow dot, ⏎ Resume, s Send, x Stop, and the hero read "1 paused · 30 done today". Enter on that row resumed it: paused → working in the same second, idle seven seconds later, the same harness ref (`eaebfe84…`), and the pane showed the 3:07 PM turn above a fresh prompt. `stop` then ended it with no Herdr call, as it must with no pane to close.

`prune` behaved as a deletion should. `--older-than 30d` found nothing that old, listed four sessions kept as someone else's (the ssh identity's, from runs 10 to 12), and deleted nothing. `--session rig-smoke` printed one "would delete" line with its size and "add --yes to delete", and the record count stayed at 53. A live session was refused with exit 5 and `--older-than 2h` with exit 2. Deletion itself is unit-tested (`tests/test_core.py`, `TestPrune`), and this run did not delete on the rig on purpose: every record there is evidence.

| Time (UTC) | Step | Evidence |
|---|---|---|
| 22:07:06 | `new` with one prompt; idle at 22:07:16 | `timeline.txt`, `loop-view.txt` |
| 22:07:19 | The panel, cursor on the live row: five buttons | `panel-live-row.jpg` |
| 22:07:19 | `z`: idle → paused, runtime unbound, Herdr agents 0, checkpoint receipt, worktree present | `timeline.txt`, `events.jsonl`, `receipt-checkpoint.json` |
| 22:07:24 | The panel: PAUSED, ⏎ Resume | `panel-paused.jpg` |
| 22:08:02 | Enter: paused → working; idle at 22:08:09; the same harness ref; the pane shows the earlier turn | `timeline.txt`, `pane-after-resume.txt` |
| 22:08:14 | The panel: the session under Working | `panel-resumed.jpg` |
| 22:09:11 | `prune`: the dry runs and the refusals; 53 records before and after | `prune-*.txt` |
| 22:09:11 | `stop`; the rig as found | `timeline.txt` |

## What this run cannot claim

That a paused session survives a reboot untouched: nothing in the model reaches it (it is unbound, the reconciler compares bound sessions only, and run 11's restart rule concerns bound ones), and this run did not reboot. That a paused lane resumes on its own Enter through `w`: the lane path is unit-tested and the run paused a session without lanes. That the Flow wraps well when a row has a preview and lanes too (seven buttons): this row had five. That `z` reads as pause to a person, or that one press with no confirmation is the right weight: the keys came from a script, and the sitting is where that is answered.
