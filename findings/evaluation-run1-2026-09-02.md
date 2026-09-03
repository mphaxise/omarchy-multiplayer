# Evaluation run 1: the 16-step scenario, driven over ssh

Status: hands-on, `live`, 2026-09-02 18:51 to 19:06 PDT, unofficial aarch64 port, software rendering. Build: cbac0e9 on the rig. Raw evidence: `captures/evaluation-run1_hands-on_arm-port_2026-09-02/`. Per-signal verdicts: `signal-1-identify-waiting.md` through `signal-5-permission-mode.md`.

## The result

Three signals pass on this run's evidence, one is flagged as unmeasured, and one is unmeasured by design. Signal 2 (closing every terminal kills nothing, reattach continues) passes on three sessions with pid-level evidence. Signal 3 (a receipt with every required field) passes. Signal 5 (no bypass outside Personal) passes on the argv Herdr reported. Signal 4 passes on the one qualifying state change the run produced, through the Herdr nudge in 0.36 s, and is flagged because one event is thin. Signal 1 is unmeasured: the mechanism worked, the stopwatch and the person did not run.

Under the plan's own verdict rule the hypothesis is undecided rather than supported: all five have to pass in one run using only the panel, and this run used the commands the panel runs rather than the panel's keys. The run also found two defects worth more than the verdict: an instruction can be lost when it is delivered before the harness accepts input, and a panel receipt action holds the panel open until the pager closes.

## How the run differed from the plan

- No screen recording and no stopwatch; timing was excluded on purpose.
- Every "from the panel" step ran the command the panel's key runs (`open`, `send`, `stop`, the receipt pager) over ssh, with the panel opened twice over IPC for captures. The panel's own keyboard path is still owed to a person.
- Step 3 used Claude Code in worktree B: Codex 0.152.0 is installed on the rig with no auth on file, OpenCode is untested.
- Step 5 ran the crash notification's exec argv by hand with the session environment exported, since a click was unavailable. The first attempt, from a pipe-captured subprocess without that environment, hung and created nothing.
- The Shared session (step 15) was created early so that a `blocked` state existed for steps 7 to 10; Personal sessions run with the no-prompt flag and never block.
- Step 11 closed windows with `hyprctl dispatch 'hl.dsp.window.close()'` on the focused window, three times; the address form was accepted and closed one window.
- Step 16 chose Personal with `--mode personal` on the command line; the agent picker was never shown, which the plan says to flag.

## What the run produced

Five sessions: `eval-a` (Claude, worktree A, Personal) committed `hello page`; `eval-b` (Claude, worktree B, Personal) went idle with no work done, see defect 1; `crash-134897` (Personal, from the crash exec) diagnosed the segfault in 77 s; `eval-shared` (Shared, worktree) blocked on its first write at 01:56:49Z and stayed blocked; `eval-personal` (Personal, explicit) answered and went idle. Herdr's argv: Personal sessions `claude --permission-mode auto`, the Shared one `claude --permission-mode default`.

Step 10's answer: `send` to a blocked agent is refused by Herdr itself ("agent eval-shared is blocked and requires interactive input"), the core records `instruction.dropped` with `agent_blocked` and exits 5, and the panel would print "not delivered · open it and answer there". The spec's drop rule holds through Herdr rather than through the core's own check; a permission prompt needs the terminal.

## Defects found

1. **An instruction delivered too early is lost.** `eval-b`'s prompt was marked `instruction.delivered` four seconds after creation, when Herdr already reported `idle`, and Claude never received it: no transcript was written, no commit made, the session sat `idle` for the rest of the run. `eval-a`, created five seconds earlier under the same conditions, received its prompt. Herdr's agent list carries an `interactive_ready` flag the core does not wait for. Fix: after `agent.wait`, poll `agent.list` until the agent is `interactive_ready` before `agent.prompt`, bounded, and record a drop with a reason when it never becomes ready.
2. **The receipt action holds the panel open.** `omarchy-launch-tui` blocks until the terminal it launched exits, so the panel's `Process` for the receipt does not return until the pager closes, and the row reads "opening…" the whole time. Fix: launch the receipt pager detached and close the panel at once.
3. **Duplicate status events.** `eval-personal` recorded `working -> idle` twice at 02:04:32Z, once from the reconciler and once from the waited send. Cosmetic; the state is right.

## What this run cannot say

Nothing about the five-second identification; nothing about the keyboard path (arrows, Enter, `s`, `x`, Esc, inline results); nothing about Codex or OpenCode; nothing about rendering or performance. The plan's next run needs a person at the rig for the stopwatch trials and the panel keys, and a Codex login if worktree B is to be a different harness.
