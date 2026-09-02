# Evaluation plan

Status: proposed, 2026-09-01. Slice 1. This file turns PLAN.md's five success signals into pass/fail protocols on the rig.

The rig is a native aarch64 UTM VM, 6 vCPU, 8 GiB RAM, software rendering, running the unofficial ggalancs aarch64 image of Omarchy. Every finding from this rig carries an unofficial-port caveat and excludes performance and rendering judgments, per the emulation rule in `captures/README.md` and `evaluation-protocol.md`.

## Scenario

One run stages all five signals:

1. Start a screen recording covering the panel and every terminal window.
2. `session new` a Claude Code session on a small web project, worktree A, mode Personal.
3. `session new` a Codex or OpenCode session on a second task, worktree B, mode Personal.
4. Trigger a deliberate segfault in a test binary; let `omarchy-crash-watch` fire the critical notification.
5. Click the notification; confirm it opens a third session under the diagnose-crash skill.
6. Hide the panel; do not reopen it except where a later step says to.
7. Note, from `events.jsonl`, the instant any session first enters `waiting` or `blocked`.
8. On the first OS notification for that change, start a stopwatch and open the panel.
9. Stop the stopwatch on visually identifying the waiting session; note the cue used.
10. From the panel, send the waiting session a new instruction without opening its terminal.
11. Close every terminal window for all three sessions from the window manager.
12. Confirm all three session records exist, `runtime` orphaned or unbound, none deleted.
13. From the panel, reattach each session; confirm its transcript resumes at the last line.
14. From the panel, `session stop` one session and open its receipt.
15. From the panel, start a fourth session in mode Shared; capture its exact harness argv.
16. Start a fifth session, choosing Personal explicitly when prompted; capture its argv too.

## Signal 1: identify the waiting session within five seconds

Steps 4-9.

- Method: stopwatch on the recording, from the OS notification (step 8) to correct visual identification (step 9); cross-check against the `status.changed` timestamp in `events.jsonl` for the true state-change instant.
- Threshold: pass at 5 seconds or less, on each of 3 trials rotating which session goes to `waiting` or `blocked`.
- Evidence: `signal1-identify_hands-on_4.0.2_<date>.mp4`, `signal1-identify_hands-on_4.0.2_<date>-events.jsonl`, `signal1-identify_hands-on_4.0.2_<date>-notes.md`.
- Confounds: software rendering can delay the panel's paint after the event fires; report that gap separately and exclude it from the human-identification interval. Heuristic status detection on non-hook harnesses can lag true state; record `status.source` for the session tested.

## Signal 2: closing every terminal kills zero sessions, reattach restores the transcript

Steps 11-13.

- Method: compare session count and `runtime` before and after step 11; compare the last visible transcript line before close to the first line after reattach.
- Threshold: pass if all 3 records survive with no `session.ended` event, and every reattach continues without a gap or a fresh prompt.
- Evidence: `signal2-reattach_hands-on_4.0.2_<date>.mp4`, `signal2-reattach_hands-on_4.0.2_<date>-sessions.json`.
- Confounds: the terminal emulator may itself signal the pane's process on window close depending on `xdg-terminal-exec` behavior. Attribute a harness killed that way to the terminal emulator, not the session model, and say so in the finding.

## Signal 3: a completed session shows a receipt

Step 14.

- Method: read `receipt.json`; check every field in the schema in `01-session-model.md` is present and not a placeholder.
- Threshold: pass if `workspace`, `commits`, `diff_stat`, `end_state`, and `started_with.command` are all populated; an empty `commits` list passes when the worktree truly has none, a missing key fails.
- Evidence: `signal3-receipt_hands-on_4.0.2_<date>.json`, `signal3-receipt_hands-on_4.0.2_<date>.png`.
- Confounds: a mid-tool-call stop can leave a partial checkpoint receipt; confirm `receipt.json`'s write time is after the stop command, not before it.

## Signal 4: zero polling, states arrive as notifications

Steps 6-10.

- Method: the recording confirms the panel stayed closed between hide and the first notification; notification timestamps from the OS notification log, ground truth from `events.jsonl`.
- Threshold: pass if every `status.changed` event into `waiting`, `blocked`, `done`, or `failed` produces a notification with no prior panel open, for all three sessions.
- Evidence: `signal4-notify_hands-on_4.0.2_<date>.mp4`, `signal4-notify_hands-on_4.0.2_<date>-events.jsonl`, `signal4-notify_hands-on_4.0.2_<date>-notifs.txt`.
- Confounds: the crash path's own `journalctl -f` and coredump latency sits upstream of the panel and should not count against it. A notification produced by the reconciler's timer sweep instead of the `pane.agent_status_changed` subscription should be flagged, not scored as a pass.

## Signal 5: nothing launches bypass-permissions mode unless Personal and chosen

Steps 15-16.

- Method: capture the literal argv the launcher passes each harness, from process listing or `started_with.command`; compare against Omarchy's documented per-harness bypass flags.
- Threshold: pass if the Shared-mode argv carries none of them, and the Personal-mode argv carries one only when the mode prompt was shown and Personal was actively chosen that run.
- Evidence: `signal5-argv_hands-on_4.0.2_<date>.txt`, `signal5-argv_hands-on_4.0.2_<date>.mp4`.
- Confounds: `omarchy-default-agent` persists a prior choice; a run where the prompt never appeared because a stored default silently applied must be flagged, not scored as a pass.

## Expert-review pass

Runs `/ux-review` and `/design-qa` from the design skill pack against the panel and the scenario above, across the three lenses `evaluation-protocol.md` defines, applied to this surface:

- Usability: can a person find the waiting session, reattach to it, send it an instruction, stop a session, and read its receipt without external help; where does an error surface, a failed reattach, a dropped instruction, and can the person recover from the panel alone.
- Accessibility: automatable checks first, on the panel's QML popup surface, contrast, focus order between session rows, target size on the assign and stop controls, keyboard reachability of every action in the scenario, reduced-motion behavior on state transitions; judgment interprets the results.
- Trust and handoff: for the crash-diagnosis session specifically, what context, uncertainty, provenance, and proposed action the panel exposes before the agent acts, and whether the person stays in control at each step; scored against the maturity axes in [ai-agent-ux-research-platform](https://github.com/mphaxise/ai-agent-ux-research-platform).

`/ux-review` produces the structured review artifact; `/design-qa` produces the accessibility and consistency checks. Both make captures, assumptions, and risks explicit; the verdict is mine.

## Closed-loop pass

For the product-people audience, `09-closed-loop-surfaces.md` runs one designer through three iterations on a live preview of the panel: state an intent, watch an agent build the change, use the result and respond from inside it, watch the next change follow. Each iteration is scored on whether evidence, the approval gate, and human judgment stayed visible, per the closed-loop hypothesis in "Closed-Loop Experience Design" (July 2026). This pass tests the audience the panel is for, not the session model's mechanics.

## Baseline comparison

Run the same 16-step scenario on stock Omarchy 4.0.2, no plugin installed.

Measurable there: the crash-to-notification path (native), `omarchy-agent` launching a harness (native), Herdr attach and detach across a closed terminal (native, Herdr ships in `install/omarchy-base.packages`).

Not measurable there, because the object does not exist: a session record independent of a live pane, a receipt, an owner or participant list, a `waiting`/`blocked` distinction the panel surfaces on its own, or a permission mode at all. Signal 5 has no baseline: nine of Omarchy's eleven agents launch in a no-prompt bypass mode by default today, with no Personal or Shared concept to gate it. The baseline run is not a control that can pass or fail signals 1 through 5; it documents what the plugin adds.

## How findings are written

One file per signal in `findings/`: `findings/signal-1-identify-waiting.md` through `findings/signal-5-permission-mode.md`, plus `findings/expert-review.md` and `findings/closed-loop.md`. Each cites its captures by filename, states the pass or fail against the threshold above, and labels every claim `proposed` (design intent, not yet built) or `live` (observed on the rig), per `captures/README.md`. A finding that warrants upstream action converts into an Omarchy issue or small PR with its captures attached, tracked in the finding file.

## Verdict

H1, that a durable named session with a panel view measurably improves on stock Omarchy across these five signals, is supported if all five pass in one run using only the panel and no manual workaround outside it. It is partly supported if three or four pass and every failure traces to the unofficial port, the VM, or software rendering, not to the session model or panel design. It is unsupported if two or more signals fail for a reason internal to the design. A signal that cannot run at all, for example one blocked by a missing Herdr socket API on the rig, counts as a failure under this rule, not an exclusion.

## What we will not conclude from this rig

- No performance or rendering verdict on Omarchy or the plugin: software rendering, a VM, and an unofficial aarch64 port all confound timing and visual results.
- No verdict on shared or restricted mode: slice 1 is one user; nothing here puts two people on one gateway.
- No verdict beyond 3 concurrent sessions, spawn depth 3, or 5 children per session, the limits this slice enforces.
- No statistically powered usability result: one expert reviewer and one designer, not a sample.
- No claim that Omarchy's maintainers would accept this pattern upstream; that is a separate question from whether the mechanism works.

## Sources

PLAN.md success signals for slice 1 (via context-pack.md, observed 2026-09-01). `/Users/praneet/Omarchy-UX/method/evaluation-protocol.md` and `/Users/praneet/Omarchy-UX/captures/README.md` (observed 2026-09-01), for lenses, runners, and capture labeling. `01-session-model.md` for the receipt schema, event log, and state machine measured against. `09-closed-loop-surfaces.md` for the closed-loop pass. Praneet Koppula, "Closed-Loop Experience Design" (July 2026), mphaxise.github.io/Praneet_Koppula/writing/closed-loop-experience-design/. [ai-agent-ux-research-platform](https://github.com/mphaxise/ai-agent-ux-research-platform) for the trust-and-handoff maturity axes. Omarchy `bin/omarchy-agent` on branch quattro (observed 2026-09-01) for the baseline's per-harness bypass flags.
