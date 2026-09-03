# Signal 3: a completed session shows a receipt

Status: hands-on, `live`, run 1 on 2026-09-02, unofficial aarch64 port. Verdict: **pass**.

## Method as run

`eval-a` was stopped with `omarchy-agent-session-stop --reason "evaluation step 14"` at 02:01:28Z; the receipt was read from `receipt.json` and its write time compared with the stop; the receipt pager was opened in a terminal.

## Evidence

`captures/evaluation-run1_hands-on_arm-port_2026-09-02/signal3-receipt.json`: `end_state` stopped, `end_reason` "evaluation step 14", `workspace` with repo root, worktree path, branch `session/eval-a`, base `main`, and the reason the worktree was kept ("committed but not pushed to any remote and not merged into base_branch"), `commits` one entry (`9fcab2e hello page`), `diff_stat` 1 file, 1 insertion, `dirty` false, `unpushed` true, `started_with.command` the full `new` invocation. Missing keys: none. Write time 02:01:30Z, two seconds after the stop (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/stop-issued-epoch`, `receipt-mtime-epoch`).

## Threshold

`workspace`, `commits`, `diff_stat`, `end_state`, and `started_with.command` all populated: met. The pager opened in a terminal (`captures/screenshots/signal3-receipt-terminal_hands-on_arm-port_2026-09-02_live-run1.jpg`; the window renders empty on this rig, so the receipt text is evidenced by the file).

## Limit found

Launching the pager through `omarchy-launch-tui` blocks the caller until the terminal closes; the panel's receipt action inherits that and holds the panel open (`evaluation-run1-2026-09-02.md`, defect 2).
