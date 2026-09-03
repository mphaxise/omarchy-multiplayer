# Evaluation run 4, the loop from the panel: raw evidence

Run 4 on 2026-09-02, 21:25 to 21:36 PDT (UTC 04:25Z to 04:36Z in the files), driven over ssh with the argv the panel runs, then through the panel itself with `wtype` pressing the keys. Findings: `findings/closed-loop.md`, "Run 4".

| File | What it is |
|---|---|
| `timeline.txt`, `ids.txt` | the step log with UTC times; the id of the session that ran the loop (`loop-panel2`; the first attempt, `loop-panel`, branched from `main`, which never had `hello.html`, so the agent asked where the footer should go and went `blocked`, the right behaviour and the wrong scenario; it was stopped and the run restarted from `session/loop-hello`) |
| `events.jsonl` | the session's full event log |
| `loop-view.txt` | `show --loop` after the verdict: intent, preview, both instructions with their `about` capture, every capture, commit, state change, and the ending, in record order |
| `receipt.txt`, `receipt.json` | the receipt after `done --verdict kept`: two commits, 313 s |
| `artifacts/` | the five captures (JPEG here) with their sidecars and the verdict note: `before-footer` (`capture --preview`), `feedback-2` (taken by `send --with-capture` from the script), `after-footer`, `feedback-4` (taken by `send --with-capture` from the panel's Send field, the panel having closed itself first), `verdict.txt` |
| `panel-row.jpg`, `panel-row-legend.jpg` | the panel open on the `loop-panel2` row: loop count leading line 2, the Preview button, the legend before and after the six-entry cap |
| `after-open.jpg` | the screen after `open`: preview at left, the session's terminal at right and focused |
| `run4.sh` | the step script |

Also on screen in the captures and not part of the run: the keyring modal (`gcr-prompter`) and five stale critical toasts from earlier runs; both are rig housekeeping for Praneet.
