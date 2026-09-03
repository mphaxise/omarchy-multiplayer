# Evaluation run 2: raw evidence

Run 2 on 2026-09-02, 19:20 to 19:31 PDT (UTC 02:20Z to 02:31Z in the files), driven over ssh. Findings: `findings/evaluation-run2-2026-09-02.md`.

| File | What it is |
|---|---|
| `started_at`, `timeline.txt`, `ids.txt` | run start, the step log with UTC times, the four session ids |
| `events/<id>.jsonl`, `events/<id>.receipt.json` | each session's event log and receipt at the end of the run |
| `notifications/*.json` | the three toasts the shell recorded in the run window: failed (critical), done (low), done (low) |
| `transcripts-after-create.json`, `transcripts-refs-test.json` | Claude transcript refs and last messages for the first pair (one shared ref, the defect) and the second pair (distinct refs, the fix) |
| `reconcile-sweep.json` | one reconcile's output after the sweep landed |
| `eval_transcripts.py` | the helper that produced the transcript snapshots |

Screen: `../screenshots/signal4-done-toast-click-receipt-window_hands-on_arm-port_2026-09-02_live-run2.jpg`.
