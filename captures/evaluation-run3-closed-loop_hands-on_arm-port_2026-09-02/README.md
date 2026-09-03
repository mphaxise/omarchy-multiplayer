# Evaluation run 3, the closed loop: raw evidence

Run 3 on 2026-09-02, 21:00 to 21:10 PDT (UTC 04:00Z to 04:10Z in the files), driven over ssh. Findings: `findings/closed-loop.md`.

| File | What it is |
|---|---|
| `started_at`, `timeline.txt`, `ids.txt` | run start, the step log with UTC times, the session id |
| `events.jsonl` | the session's full event log |
| `loop-view.txt` | `show --loop` after the verdict: intent, preview, every instruction with its `about` reference, every capture, commit, state change, and the ending, in order |
| `receipt.txt`, `receipt.json` | the receipt after `done --verdict kept` |
| `artifacts/` | the six captures (fullscreen, as JPEG here) with their sidecars, the verdict note, and the iteration-1 record correction |
| `loop_iter.sh` | the helper that ran one iteration: capture, `send --about`, relaunch the preview, capture |
