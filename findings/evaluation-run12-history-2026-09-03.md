# Evaluation run 12: history and resume

Status: hands-on, `live`, 2026-09-03, 14:29 to 14:33 PDT, on `slice-4/history` (specs amended at `e9870bd`, core at `a97d43c`, the plugin in the commit after), Omarchy `0b3f1b7`, Herdr 0.8.2, Claude Code 2.1.259, driven over ssh by `setup/run12-history.sh`. Raw evidence: `captures/evaluation-run12-history_hands-on_arm-port_2026-09-03/`. The change under test comes from Praneet's question that afternoon, after starting the VM: where are yesterday's agents. The record had all of them (52 directories, none deleted); the panel showed ended sessions for a day and nothing pointed past it, and `open` refused a session a person had stopped even with its transcript on disk (`decisions.md`, 2026-09-03, "History is kept and reachable"). This run checks the three pieces built for that: the panel's window, History, and Resume.

## The result

All three hold. The panel reads through `list --ended-within 24h --json` and still shows the day: "31 DONE TODAY", two rows and "29 more · →". Under the last section it now says "18 earlier · e", and `e` opens History in a TUI window beside the terminals, the fourteen days grouped by day, each ended session with its end time, state, detail, duration, agent, and project, and "resumes" on the ones `open` would bring back. The `restart-page` row, stopped since 09:23 with a transcript, read "stopped · resumes conversation" with ⏎ Resume and r Receipt; `open`, the command Enter runs, took it stopped → orphaned → working in the same second and idle eight seconds later, with the same harness ref (`86cfa28c…`), and the pane showed the morning's turn above a fresh prompt: the conversation resumed. The stop's cleanup had removed the worktree (the branch was merged), and `open` put it back at the same path from the branch before the harness started, which is what the detail "resumed after a stop; worktree re-created" records.

The bug the window defuses is measured: the list without the window was 54,453 bytes at 52 records, 11 KB under the panel's 64 KB cap, past which the panel shows one error row and no sessions. With the window it was 35,345 bytes for the 31 sessions of the last day.

| Time (UTC) | Step | Evidence |
|---|---|---|
| 21:29:36 | Shell restarted; the refresh probe answers; `list --ended-within 24h --json` 35,345 bytes, 31 sessions, 18 earlier; without the window 54,453 bytes | `timeline.txt` |
| 21:29:40 | The panel: "31 DONE TODAY", `restart-page` with ⏎ Resume, "18 earlier · e" | `panel-done-today-earlier.jpg` |
| 21:29:42 | → expands Done today | `panel-done-expanded.jpg` |
| 21:30:06 | `open restart-page`: stopped → orphaned "resumed after a stop; worktree re-created" → working; idle at 21:30:14; harness ref unchanged; Herdr lists the agent idle in `wF:p1` | `timeline.txt`, `events.jsonl` |
| 21:30:19 | The panel: `restart-page` under Working | `panel-resumed-working.jpg` |
| 21:30:5x | The pane: "Say hello in one line and nothing else." and "Hello!" above the prompt | `pane-after-resume.txt` |
| 21:31:00 | `e` from the panel: the History window, "Thursday 2026-09-03 · 9 ended" | `history-window.jpg`, `history.txt` |
| 21:33:37 | `stop`; the rig as found | `timeline.txt`, `loop-view.txt` |

## Two things seen on the way

One Quickshell crash, at 21:29:23, in the instance that had run the branch's first plugin build for a minute: it crashed while exiting on the restart's IPC request, the supervisor restarted it, and the crash dialog stayed on the rig's screen (`~/.cache/quickshell/crashes/ew64dz4tkt`, Quickshell 0.3.1, Qt 6.11.2, no symbols in the journal's trace). The seven restarts earlier that day, on the previous plugin build, exited cleanly, and the two restarts after this run, on the branch's final build, exited cleanly too. One teardown crash in three restarts of the branch's code against none in seven of the previous build is a thing to watch, and this run cannot say which side it belongs to.

The History read over ssh said 46 ended and the window on the rig said 48. Two identities: `omarchy@_gateway` over ssh, and the rig's own user at the panel, who alone can see the two private drafts run 10 created. That is the run-10 visibility rule, and it also means a person over ssh reading history sees less than the person at the machine.

## What this run cannot claim

That a resumed session picks up a turn that was in flight when it was stopped: this one was idle at both stops, and a harness interrupted mid-turn resumes its transcript and loses the turn, which is the harness's behaviour. That a Codex session resumes the same way: `RESUME_FLAGS` maps `codex` to `resume`, untested on the rig. That the panel stays under 64 KB on any day: at about 1.1 KB per session the window allows roughly 58 sessions in a day, and a day of evaluation runs has reached 39; a compact payload is the next lever if that is ever crossed. That a person finds "18 earlier · e" or presses `e`: this run pressed the keys from a script, and whether the footer reads as the way back to yesterday's agents is the sitting's to say.
