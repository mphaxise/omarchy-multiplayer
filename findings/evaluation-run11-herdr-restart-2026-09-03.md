# Evaluation run 11: a Herdr restart with a live session

Status: hands-on, `live`, 2026-09-03, 09:22 to 09:24 PDT, on `main` at `8703e9a` (slice 3 merged), Omarchy `0b3f1b7`, Herdr 0.8.2, Claude Code 2.1.259, driven over ssh. Raw evidence: `captures/evaluation-run11-herdr-restart_hands-on_arm-port_2026-09-03/`. The rule under test is the one Praneet's reboot forced on 2026-09-02 (`decisions.md`, "A Herdr restart orphans; it never ends"), which had been verified only on a session ended before the rule existed. This run restarts the server under a live session. The rig had no live sessions of his and no Herdr agents when it ran.

## The result

The rule holds. A session idle under Herdr went `orphaned` with the detail "Herdr restarted; Enter revives" two seconds after `systemctl --user restart omarchy-agent-session-herdr`, never `failed`. `open`, the command the panel's Enter runs, brought it back as `working` then `idle` in eight seconds with the same harness ref, and the revived pane showed the earlier turn above a fresh prompt: the conversation resumed. The panel read "1 orphaned · Enter revives" and the row "orphaned · resumes conversation" with a Revive button.

| Time (UTC) | Step | Evidence |
|---|---|---|
| 16:22:16 | `new`, idle at 16:22:22; one instruction, answered by 16:22:34 | `timeline.txt`, `loop-view.txt` |
| 16:22:48 | `systemctl --user restart omarchy-agent-session-herdr`; the unit active again | `timeline.txt` |
| 16:22:50 | Reconciler: idle → orphaned "Herdr restarted; Enter revives", runtime unbound | `events.jsonl` |
| 16:23:05 | The panel: "1 orphaned · Enter revives"; the row with Revive | `panel-orphaned.jpg` |
| 16:23:17 | `open`: orphaned → working at 16:23:18, idle at 16:23:25, harness ref unchanged (`86cfa28c…`) | `timeline.txt` |
| 16:23:33 | The pane shows "Say hello in one line" and "Hello!" above the prompt; `stop` | `pane-after-revive.txt` |

## What this run cannot claim

That a reboot behaves the same: a reboot also drops the runtime directory and restarts the shell, which the earlier reboot exercised and this run did not. That a session `working` at the moment of the restart resumes mid-turn: this one was idle; a harness interrupted mid-turn resumes its transcript and loses the turn in flight, which is the harness's behaviour and not the session's.
