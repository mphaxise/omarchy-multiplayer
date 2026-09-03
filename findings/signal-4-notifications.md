# Signal 4: zero polling, states arrive as notifications

Status: hands-on, `live`, runs 1 and 2 on 2026-09-02, unofficial aarch64 port. Verdict: **pass**: three of the four notify rows witnessed (`blocked`, `done`, `failed`), each delivered through the Herdr subscription path in under a second with the panel closed; `waiting` cannot fire until Herdr distinguishes a question from a permission prompt.

## Method as run

The panel stayed closed from the start of the run until the step-8 capture at 01:57:24Z and again until the final capture. Every `status.changed` event across the five sessions was listed from their event logs and compared with the toasts the shell recorded.

## Evidence

`captures/evaluation-run1_hands-on_arm-port_2026-09-02/signal4-state-changes.txt`: eighteen transitions, of which one enters the notify set, `eval-shared working -> blocked` at 01:56:49Z. No session entered `waiting`, `done`, or `failed`; `eval-a` was stopped, which by `spec/06-notifications.md` does not notify. The shell recorded `eval-shared needs you` at 01:56:49.356Z (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/timeline.txt`), 356 ms after the event's second, before the reconciler's five-second sweep could have run, so the Herdr nudge path delivered it. The crash toast at 01:52:21.847Z is Omarchy's own path and is listed for completeness (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/crash-notification.json`).

## Threshold

Every event into the notify set produced a notification with no prior panel open: met for the one event that occurred. The plan says a sweep-produced notification is flagged rather than passed; this one came through the subscription. The flag here is thinness: one event across three sessions, and no `done` or `failed` transition was exercised, because Personal sessions end `idle` and were stopped rather than finishing.

## Run 2

`captures/evaluation-run2_hands-on_arm-port_2026-09-02/`: a session that finished on its own (`/exit`) went `done` at 02:22:00Z and its toast "run2-done finished · claude · Finish on its own: the done row · Click to open the receipt" was recorded at 02:22:00.870Z, urgency low; a session whose harness was killed mid-turn at 02:21:25.48Z went `failed` at 02:21:25Z and its toast "run2-failed failed · claude · harness exited while working · Click to open the receipt" was recorded at 02:21:25.793Z, urgency critical. The done toast's exec argv opened the receipt pager in a terminal. Run 2 had to add the `failed` producer first; run 1's build ended every vanished harness as `done` (`evaluation-run2-2026-09-02.md`).

## Next

The `waiting` row waits on Herdr or the harness hook telling a question from a permission prompt; until then every ask is `blocked` and reads "needs you".
