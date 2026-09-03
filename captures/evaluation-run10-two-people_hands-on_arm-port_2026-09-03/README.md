# Evaluation run 10, two people in proxy form: raw evidence

Run 10 on 2026-09-03, 09:00 to 09:17 PDT (UTC 16:00Z to 16:17Z in the files), on `slice-3/two-people`. Three passes on three sessions: `a` (`shared-page`) is the scripted run, `b` (`shared-page-b`) repeats it after the naming fix so the panel's captures carry the fixed names, `c` (`shared-page-c`) captures the hero after its reorder and the `d` dismiss path. Findings: `findings/evaluation-run10-two-people-2026-09-03.md`.

The second person is the Mac driving the rig over ssh, which the commands see as `human:omarchy@_gateway` from `SSH_CONNECTION`; the owner's steps run with `OMARCHY_ACTOR=human:omarchy@omarchy`, which is the identity the panel's own processes carry. Both are the same OS user on the same store: the proxy tests the mechanics and claims nothing about isolation (`spec/12`).

| File | What it is |
|---|---|
| `timeline.txt` | the step log for all three passes, each line tagged with the identity that ran it (`[human:omarchy@omarchy]` the owner, `[local]` the ssh identity) |
| `errors.txt` | empty: no command wrote to stderr through the script's error file |
| `toasts-replayed.txt` | the watcher's notification argv for passes `a` and `b`, replayed after the fact from a copy of the two records with `--once --dry-run`, so the owner shown is the final one |
| `a/events.jsonl`, `a/loop-view.txt`, `a/receipt.txt`, `a/sid` | pass `a`: the log, the loop view, and the receipt re-rendered after the run from the same record (`receipt --write`), so they carry the loop rows and the People group that landed during the run |
| `a-panel-suggests-before-naming-fix.jpg` | pass `a`, the panel as the owner saw the suggestion before the fix: "omarchy suggests", the second person's label indistinguishable from the owner's |
| `a-panel-accepted.jpg` | pass `a`, after `y`: the row under Working with "accepted, sent" |
| `a-panel-blocked-owned-by.jpg` | pass `a`, the agent's question one second after the assignment: Needs you, the badge on the bar, "needs you · 2m", the Answer button; the row does not yet name the owner (fixed in `b`) |
| `b/events.jsonl`, `b/loop-view.txt`, `b/receipt.txt`, `b/sid` | pass `b`: the log, the loop view with the two-people rows, the receipt with People |
| `b-panel-suggests.jpg` | pass `b`: "omarchy@_gateway suggests" on the hero and the row, the suggestion quoted, `y Accept` and `d Dismiss`; the hero's tail elided ("Y ACCEP…"), fixed in `c` |
| `b-panel-accepted.jpg` | pass `b`, after `y` |
| `b-panel-owned-by.jpg` | pass `b`, after the assignment: the row reads "owned by omarchy@_gateway" |
| `c/events.jsonl`, `c/loop-view.txt`, `c/sid` | pass `c`: a suggestion dismissed with `d`, recorded as `suggestion.dismissed` by the owner with the suggester's name |
| `c-panel-suggests.jpg` | pass `c`: the hero reads "omarchy@_gateway suggests · y accepts · just n…", the action ahead of the age |
| `c-panel-dismissed.jpg` | pass `c`, after `d`: nothing needs you |

Every capture is cropped to the panel and the bar's right end (412 by 545 from the 1920 by 1200 screen). The step script is `setup/run10-two-people.sh`; pass `c` was six commands typed at the ssh prompt and logged into the same timeline.

What changed during the run and is in the branch: the reconciler's sweep matches panes by `tokens.session_id` instead of workspace id, because Herdr reuses workspace ids after a restart and the sweep had closed a new session's workspace five seconds after creation (the two refused starts before pass `a`); `display_name` gives a person `user@host` when their label would read as the viewer's own; the loop view renders suggested, accepted, dismissed, access, owner, and visibility rows; the receipt gains a People group; presence is cleared when a session ends; the panel names an owner who is someone else and puts "y accepts" ahead of the age on a suggestion's hero line.
