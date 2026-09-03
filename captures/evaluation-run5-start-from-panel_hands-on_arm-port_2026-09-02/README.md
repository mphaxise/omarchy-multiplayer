# Evaluation run 5, a session started from the panel: raw evidence

Run 5 on 2026-09-02, 22:11 PDT (UTC 05:11Z in the files), driven over ssh with `wtype` pressing the keys. Praneet asked for a way to start a session from the panel; this is the first run of it.

| File | What it is |
|---|---|
| `timeline.txt`, `ids.txt` | the step log with UTC times; the id of the session the panel started (`create-a-file-named-2`, stopped after the run) |
| `panel-rest.jpg` | the panel open, the starter row under the hero at rest ("n  New session in ~/Work…"), the legend with "n new" |
| `panel-new-open.jpg`, `panel-new-typed.jpg` | after `n`: the field with its Start button and the legend "⏎ starts it in ~/Work · esc cancels"; after the prompt was typed |
| `after-start.jpg` | four seconds after Enter: the panel closed, the session's terminal mapping |
| `panel-after.jpg` | the panel reopened: the new session under Working, "1 instruction, 0 captures · Work · personal" |
| `run5.sh` | the step script |

What the agent did with the typed prompt: it wrote `~/Work/started-from-the-panel.txt` with the line "hello from the panel" 30 seconds after Enter. The file was removed after the run and the session stopped.
