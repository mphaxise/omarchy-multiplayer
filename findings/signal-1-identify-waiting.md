# Signal 1: identify the waiting session within five seconds

Status: hands-on, `live`, run 1 on 2026-09-02, unofficial aarch64 port. Verdict: **unmeasured**. The mechanism ran; the stopwatch and the person did not.

## What ran

A Shared-mode session (`eval-shared`) asked to create a file blocked on the write at 01:56:49Z (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/signal4-state-changes.txt`). The shell recorded the toast `eval-shared needs you · claude · Shared-mode write test · Click to open and answer` at 01:56:49.356Z (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/timeline.txt`). The panel, opened over IPC 35 s later for the capture, led with that session: hero `eval-shared · needs you · just now · Enter opens`, the Needs-you row set larger than every other row with the state word in the urgent color, the bar glyph urgent with a badge of 1 (`captures/screenshots/signal1-panel-blocked-leads_hands-on_arm-port_2026-09-02_live-run1_crop.png`).

## Threshold

Pass at 5 s or less from the notification to correct visual identification, on each of three trials rotating which session blocks. No trial ran: there was no recording, no stopwatch, and no person looking. The plan's confound about the panel's paint delay under software rendering also went unmeasured.

## What the run adds

The cue chain a person would use is on screen and honest: toast, badge, hero, first row. The cue that was missing this morning (the row's state word at 3.60:1, the cursor never painted) is fixed in cbac0e9 and visible in the capture. The three trials remain the next keyboard session's job.
