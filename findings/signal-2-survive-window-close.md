# Signal 2: closing every terminal kills zero sessions, reattach restores the transcript

Status: hands-on, `live`, run 1 on 2026-09-02, unofficial aarch64 port. Verdict: **pass** on three sessions.

## Method as run

Three sessions had terminal windows attached (`eval-a`, `eval-b`, `crash-134897`; window classes `org.omarchy.session.<id>`, `captures/evaluation-run1_hands-on_arm-port_2026-09-02/windows-before-close.txt`). All three windows were closed through the compositor (`hyprctl dispatch 'hl.dsp.window.close()'`, 01:58:46Z to 01:59:18Z). Eight seconds later the records were read, the pane processes listed, and each session reattached with `open`.

## Evidence

- Records after close: all five session records present, `session.ended` count 0 for every one, `runtime` still bound to the same pane (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/records-after-close.txt`).
- Processes: the same shell and harness pids before and after the close and after the reattach, for example `eval-a` shell 131773, `claude --permission-mode auto` 131922 (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/panes-before-close.txt`, `panes-after-close.txt`, `panes-after-reattach.txt`).
- Transcripts: line counts and last messages identical before and after the reattach, 27 lines for `eval-a` ending in "Created `hello.html` ... committed it as hello page (9fcab2e)", 68 for the crash session (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/transcripts-before-reattach.json`, `transcripts-after-reattach.json`).
- Reattach: three new terminal windows on the same panes (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/timeline.txt`, step 13; `captures/screenshots/signal2-reattached-terminals_hands-on_arm-port_2026-09-02_live-run1.jpg`, where the reattached terminals render as empty frames, a known rendering fault of this rig, so the transcript check rests on the files and the pids).

## Threshold

All three records survive with no `session.ended`, every reattach continues without a gap or a fresh prompt: met. The pane never died, so "continues" here means the same process with the same transcript file; the terminal emulator's close did not signal the harness, which the plan lists as the confound to watch.

## Limits

The windows were closed by the compositor from a script, the reattach ran the `open` command the panel's Enter runs, and `eval-b` had an empty transcript for a reason unrelated to this signal (`evaluation-run1-2026-09-02.md`, defect 1).
