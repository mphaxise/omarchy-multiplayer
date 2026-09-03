# Experiment report: slice 1

Status: draft of 2026-09-02 evening, hands-on, `live`. Build: commit 980d4f2 on the rig, Omarchy quattro at `0b3f1b7` (2026-08-29) on the unofficial aarch64 UTM port, Herdr 0.8.2, Claude Code 2.1.252, software rendering. This report separates what was measured from what I judge; the closed-loop pass has not run, and the verdict below says so. Late-evening revision: the stopwatch protocol for signal 1 is withdrawn and the signal restated as a capture-verified criterion (`decisions.md`); the rig's package update bumped Claude Code to 2.1.259 and left Omarchy at `0b3f1b7`.

## Bottom line

A durable session object plus a shell panel is live on Omarchy, and four of the five success signals hold on evidence gathered from the rig in one day: sessions survive every terminal closing and a reboot, receipts carry the work, state changes reach the desktop as notifications in under a second, and no session launches with a bypass flag outside Personal mode. The fifth, that the waiting session is the first thing named on every surface, holds by capture: toast, badge, hero, and first row all pointed at the blocked session in run 1; I withdrew the five-second stopwatch version of it tonight, for the reason in `decisions.md`. Under the plan's rule as restated, the hypothesis is supported on this rig, with two conditions attached: the panel's keys had a quick pass by me and no recorded run, and the picker prompt has not been exercised.

The day's larger yield is the defect list. Two review passes and two scenario runs found nineteen defects in a slice that passed every happy path; sixteen are fixed and tested, one belongs to Herdr, two are cosmetic and listed. Several of them were invisible without a capture or a log, the cursor that was never painted first among them. That is the closed-loop claim in practice: the surface got better because something looked at it with evidence in hand.

## What was built

Seventeen commands (`omarchy-agent-session-new` through `reconcile`) over a Python core with 109 tests; a record per session under `~/.local/state/omarchy/sessions/<id>/` with an append-only event log and a receipt; Herdr as the runtime, so the process outlives the terminal; a watcher that turns state changes into Omarchy notifications and runs the reconciler every five seconds and on every Herdr event; a bar widget and keyboard panel as a user plugin (`praneet.agent-sessions`); the keybinding and the crash toast rewired to create sessions; permission modes enforced by a deny-list before exec. Specs in `spec/00` to `spec/10`; the build diverges from them where the rig forced it, and each divergence is written down.

## Evidence per signal

| # | Signal | Measured | Where |
|---|---|---|---|
| 1 | The waiting session is the first thing named on every surface (restated; the five-second stopwatch is withdrawn) | Pass by capture: toast at 0.36 s, urgent glyph with badge of 1, hero naming the session, first row set larger with the state word in urgent. | `signal-1-identify-waiting.md`, `signal1-panel-blocked-leads_…_live-run1_crop.png` |
| 2 | Closing every terminal kills zero sessions; reattach restores the transcript | Pass. Three windows closed by the compositor; every record kept its pane, zero `session.ended`, harness pids identical before, after, and after reattach, transcripts byte-identical. | `signal-2-survive-window-close.md`, `captures/evaluation-run1_…` |
| 3 | A completed session shows a receipt | Pass. Every required field populated (worktree, `9fcab2e hello page`, diff stat, end state, start command), written 2 s after the stop. | `signal-3-receipt.md`, `signal3-receipt.json` |
| 4 | States arrive as notifications, no polling | Pass. `blocked`, `done`, and `failed` each raised a toast 0.3 to 0.9 s after the event through the Herdr subscription, panel closed throughout; `waiting` cannot fire until Herdr tells a question from a permission prompt. | `signal-4-notifications.md`, runs 1 and 2 |
| 5 | No bypass launch outside Personal | Pass, flagged. Shared ran `claude --permission-mode default`; Personal ran `--permission-mode auto`, Omarchy's own flag. Personal was chosen on the command line; the picker prompt never appeared. | `signal-5-permission-mode.md`, `process-info-after-create.txt` |

Two measured facts sit outside the table. The revive path: a session whose pane was killed behind its back was orphaned within seven seconds, revived with `--resume`, and answered a code word set before the kill; after a reboot every session came back `orphaned` and Enter revived it. The Herdr-down path: with the server stopped, the reconciler orphans every bound session and the panel shows "Herdr is not running" over them (`sessions-panel-herdr-down_…_live.jpg`).

## What the review passes found

`/ux-review` and `/design-qa` from my design skill pack, run against the morning's build with its captures, the QML, and the notification copy as evidence, found no P0 and four P1s (`evaluation-slice1-2026-09-02.md`). A fresh capture taken during the pass found a fifth that neither review could see from the code alone: the keyboard cursor had never been painted, because my row component shadowed the shell's `hasCursor` property. Decisions from the pass: P1 blocks a public push; craft-first fixes; stop-ship until every state color the panel chooses clears 3:1. All three were built before the evening (`decisions.md`).

The reviews also corrected a claim in my own spec: it promised 4.5:1 for every state color and a control floor of `Style.space(4)`; the build had 3.60:1 caption text, 1.91:1 dots, and a floor that evaluated to 4 px. The spec now carries the measured numbers.

## Defects the runs found

Run 1 found an instruction lost when delivered before the harness accepted input, and a receipt action that held the panel open until the pager closed. Run 2 found no producer for `failed`, two sessions started five seconds apart in one directory sharing one transcript id, and dead workspaces piling up in Herdr after every server restart. Each is fixed and has a test; each is described with its evidence in `evaluation-run1-2026-09-02.md` and `evaluation-run2-2026-09-02.md`. Two rig facts changed the working method: the shell's hot reload leaves the live widget on old code, so every QML change needs `omarchy-restart-shell`; and that script's two-second readiness window fails under load on this VM.

## Judgment calls

These are mine, and the evidence above does not decide them.

Herdr reports a question and a permission prompt as one state, so every surface says "needs you"; a true label beats a specific wrong one. A harness that vanishes while `working` is recorded as `failed`, one that vanishes while idle as `done`, because Herdr exposes no exit status; the receipt says which rule fired. Orphaned sessions rank above working ones and turn the bar glyph foreground without a badge, since the badge counts agents that are asking and an orphaned one is silent. The panel's calm state reads "Nothing needs you" over real counts, because the review's taste question came down to control, and control needs an honest baseline. The crash session runs in Personal mode because Omarchy's own crash path does; whether a diagnosis should ask first is the strategic question the reviews escalated and I have not answered.

## What this report cannot claim

No five-second number, by decision. No recorded run from the panel's own keys: the runs drove the commands the keys run, and my quick keyboard test at the rig confirmed the keys work without recording which. No second harness: Codex is installed on the rig without a login, OpenCode is untested. No `waiting` state until the harness hook distinguishes it. No rendering or performance judgment, per the emulation rule. No closed-loop pass yet, so the audience claim in PLAN.md is untested.

## Next

One session through the agent picker, which closes signal 5's flag. The closed-loop pass, one designer, three iterations on a live preview. Omarchy itself: tonight's `omarchy-update` updated packages only, because the aarch64 image ships Omarchy as a root-owned checkout no package owns; the port's `omarchy` 4.0.1-2 package is the real path, and installing it is a deliberate, snapshotted step before the marketplace listing. Then Phase 6.

## Sources

`PLAN.md` for the signals and the verdict rule; `spec/10-evaluation-plan.md` for the protocols; `findings/signal-1` to `signal-5`, `evaluation-slice1-2026-09-02.md`, `evaluation-run1-2026-09-02.md`, `evaluation-run2-2026-09-02.md`; `captures/evaluation-run1_…` and `evaluation-run2_…` for raw files; `captures/screenshots/*2026-09-02_live*`; `captures/sessions/2026-09-02_phase4-first-run.md` for the day's session note; `decisions.md` for the dated decisions.
