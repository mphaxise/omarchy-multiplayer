# Evaluation run 2: the done and failed rows, and three more defects

Status: hands-on, `live`, 2026-09-02 19:20 to 19:31 PDT (timestamps in the evidence are UTC, 02:20Z to 02:31Z), unofficial aarch64 port, software rendering. Build: c854559 plus this run's fixes, deployed in place. Raw evidence: `captures/evaluation-run2_hands-on_arm-port_2026-09-02/`. Driven over ssh, no person at the keyboard.

## The result

Signal 4's two untested rows now have witnesses. A session that finished on its own (`/exit` typed into its pane) went `done` within a second and raised "run2-done finished · claude · Finish on its own: the done row · Click to open the receipt" at low urgency; the toast's click opened the receipt pager in a terminal (`captures/screenshots/signal4-done-toast-click-receipt-window_…_live-run2.jpg`). A session whose harness was killed mid-turn went `failed` in the same second and raised "run2-failed failed · claude · harness exited while working · Click to open the receipt" at critical urgency. Both arrived through the Herdr nudge, 0.3 to 0.9 s after the event, with the panel closed throughout. Every prompt in this run reached its harness, so run 1's lost-instruction defect is fixed by the `interactive_ready` wait.

The run also found three more defects, fixed and deployed before it ended.

## What ran

1. `run2-done` and `run2-failed` created five seconds apart in the same directory with prompts; both transcripts written (14 lines each, `transcripts-after-create.json`).
2. `run2-failed`'s harness (pid 154757) killed with SIGKILL while `working` on a long write at 02:21:25.48Z; the reconciler ended it as `failed` at 02:21:25Z and the toast was recorded at 02:21:25.79Z (`events/01M1JH3AGRWDMXHK3MGW8FTS6B.jsonl`, `notifications/1788402085793-1.json`).
3. `/exit` sent to `run2-done` at 02:21:59Z through `send`; harness gone, pane alive; `idle -> done` at 02:22:00Z, toast at 02:22:00.87Z, low urgency, exec is the receipt pager (`notifications/1788402120870-2.json`).
4. `run2-ref-c` and `run2-ref-d` created five seconds apart in the same directory; each got its own transcript ref and answered its own prompt (CHARLIE, DELTA), which run 2's first pair had failed (`transcripts-refs-test.json`).
5. `/exit` to `run2-ref-c`: `done` in under two seconds and its Herdr pane closed with it (`panes before` nine, `after` eight, `timeline.txt`).
6. The done toast's exec argv run by hand: a terminal with class `org.omarchy.session-receipt` appeared and was closed.
7. A reconcile sweep closed the empty workspaces earlier sessions had left in Herdr; the one workspace a failed morning launch had created without a session was closed by hand. Herdr's list ended the run with only the person's `spike` workspace.

## Defects found and fixed

1. **No producer for `failed`.** The reconciler ended every vanished harness as `done`. Herdr exposes no exit status, so the state at the moment the harness vanished now decides: gone while `working` is `failed` (nothing finishes a turn by exiting), gone while idle, waiting, or blocked is `done`. `spec/01-session-model.md` carries the rule.
2. **Two sessions, one transcript.** `run2-done` and `run2-failed`, started five seconds apart in one directory, both recorded the same Claude transcript id, because discovery took the newest file by mtime; a revive of one would have resumed the other's conversation. Discovery now reads each transcript's first timestamp, takes the earliest file that started after the session did, and never a ref another session already holds. Verified by the second pair.
3. **Dead workspaces pile up in Herdr.** A harness that exits leaves its shell pane; a `stop` on an orphaned session has no pane to close; and Herdr restores every workspace, with a fresh shell, when its server restarts. Nine panes sat in Herdr's list at the start of this run for one live session. The reconciler now closes the pane when it ends a session, and sweeps the workspaces its own `runtime.bound` events name for any ended or orphaned session, never an adopted agent's workspace and never one with a live agent in it. Eight of the nine were gone by the end of the run.

Tests: 109, green on the Mac and the rig.

## What this run cannot say

The click on the `done` toast ran its exec argv by hand; the shell's own click path is unexercised by a person. The `failed` rule is a heuristic and will call a harness that a person kills mid-turn on purpose a failure; the receipt says why either way. Nothing here touches signal 1, the keyboard path, or the closed-loop pass.
