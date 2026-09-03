# Signal 4: zero polling, states arrive as notifications

Status: hands-on, `live`, run 1 on 2026-09-02, unofficial aarch64 port. Verdict: **pass, flagged**: one qualifying event in the run, delivered through the Herdr subscription path in 0.36 s.

## Method as run

The panel stayed closed from the start of the run until the step-8 capture at 01:57:24Z and again until the final capture. Every `status.changed` event across the five sessions was listed from their event logs and compared with the toasts the shell recorded.

## Evidence

`captures/evaluation-run1_hands-on_arm-port_2026-09-02/signal4-state-changes.txt`: eighteen transitions, of which one enters the notify set, `eval-shared working -> blocked` at 01:56:49Z. No session entered `waiting`, `done`, or `failed`; `eval-a` was stopped, which by `spec/06-notifications.md` does not notify. The shell recorded `eval-shared needs you` at 01:56:49.356Z (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/timeline.txt`), 356 ms after the event's second, before the reconciler's five-second sweep could have run, so the Herdr nudge path delivered it. The crash toast at 01:52:21.847Z is Omarchy's own path and is listed for completeness (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/crash-notification.json`).

## Threshold

Every event into the notify set produced a notification with no prior panel open: met for the one event that occurred. The plan says a sweep-produced notification is flagged rather than passed; this one came through the subscription. The flag here is thinness: one event across three sessions, and no `done` or `failed` transition was exercised, because Personal sessions end `idle` and were stopped rather than finishing.

## Next

A run that lets a session finish (`done`) and one that fails (`failed`, for example a harness killed with SIGKILL while working) would exercise the other two rows of the urgency table.
