# Closed-loop pass

Status: hands-on, `live`, 2026-09-02, unofficial aarch64 port, Omarchy `0b3f1b7`, Claude Code 2.1.259. Two halves: the loop surfaces from `spec/09-closed-loop-surfaces.md` run mechanically over ssh as run 3 (raw evidence in `captures/evaluation-run3-closed-loop_hands-on_arm-port_2026-09-02/`), and the three iterations I ran as the designer earlier in the day, which went through this chat and never touched the surfaces. The measurement in spec/09 section 8 wants both in one sitting; that sitting has not happened.

## The result

The loop record holds. A session with a three-line intent, a registered preview, three rounds of feedback each tied to the capture that prompted it, three commits, and a verdict shows every step in order in `show --loop` and in the receipt, with one gap that the run itself found and the code now closes. What the record cannot show is a designer looking at the preview and deciding what to say; in run 3 the instructions were mine, written in advance, and the judgment is a script's.

The designer-driven half happened anyway, three times, before the surfaces existed to carry it: I asked for feedback after confirming Stop and got the spinner; I reported dead arrow keys and got a cursor, which turned out never to have been painted; I tested the keyboard on the restarted shell and it worked. Each round had an intent stated by me, a change built, and a result I used. None of it went through `send --about`, so the record of those loops is this repository's commits and session note, which is the thing spec/09 exists to replace.

## Run 3, mechanical

Session `loop-hello` on a worktree of the spike repo, Personal mode. Intent, verbatim from `--goal`: "hello.html greets the person by name, one screen, readable at a glance / README.md and everything else in the repo stay untouched / A capture of the page after each change; the page itself is the evidence". Preview: the page's file URL, registered with `preview` and opened in a Chromium app window.

| Iteration | Before capture | Instruction (tied to the capture) | Change | After capture |
|---|---|---|---|---|
| 1 | `iter1-before` 04:04:11Z | change the greeting to "Hello, Praneet" | `b20c567 hello, greet by name` 04:04:15Z | `iter1-after` 04:06:54Z |
| 2 | `iter2-before` 04:08:37Z | add a second line with the date | `b95c2a7 hello, add the date` 04:08:43Z | `iter2-after` 04:08:57Z |
| 3 | `iter3-before` 04:09:21Z | heading and paragraph, minimal page | `2cbf90d hello, heading and paragraph` 04:09:26Z | `iter3-after` 04:09:41Z |

Verdict: `done --verdict kept` at 04:09:41Z, note "Three iterations, three commits, each tied to the capture that prompted it; the page greets by name, dates itself, and reads as a page. README untouched. Kept." The receipt: four commits on `session/loop-hello`, one file changed, eight artifacts including the verdict, 582 s. The loop view (`loop-view.txt`) lists the intent, the preview, and every instruction with its `[about: iterN-before]` reference, every capture, every commit, every state change, and the ending, in timestamp order. The last after capture shows the page as a person would see it (`captures/screenshots/closed-loop-iter3-after-preview_…_live_crop.png`).

## What the run found

1. **A wait for `idle` timed out while the work was done.** Herdr reports `done` after a turn and `idle` between turns; my `--until idle` matched neither, the 150 s wait ran out, and the record wrote `instruction.dropped` for an instruction that had produced commit `b20c567` two minutes earlier. Fixed: a wait on this record's `idle` also accepts Herdr's `done`, and a wait that runs out after the text was typed records delivery with `wait_timed_out`; only a refusal is a drop. A correction note sits in the session's artifacts, because the event log is append-only.
2. **`done` left the harness running.** The verdict marked the session done and walked away from a bound pane with Claude in it; the reconciler skips terminal sessions, so nothing would ever have closed it. Fixed: `done` records the state, unbinds, then closes the pane, the order `stop` now uses too, because closing the pane first let the reconciler orphan the session for one heartbeat before the verdict landed (visible in `loop-view.txt`: `idle -> orphaned` at 04:09:42Z, then `idle -> done`).
3. **`capture --screenshot` needs a person.** Omarchy's window capture picks a region with slurp; over ssh there is nobody to pick, and the fallback path can leave a slurp running that the next call kills before capturing. Run 3 took its captures with `grim` and attached them with `capture --file`. The screenshot flag stays untested unattended.
4. **The loop view was thin.** It printed raw events; it now renders intent, preview, instructions with their `about` label, artifacts, commits from the branch, state changes, and the ending, joined and sorted. Tests: 116.

## Against spec/09, section by section

The goal as a three-line intent record: built and shown in the loop view and the receipt (section 1). The preview as shared canvas: `preview` registers it; `open` does not yet focus it and the panel has no Preview button (section 2 and 7, open). Situated feedback with `--about`: built and used three times (section 3). The evidence trail: captures carry `proposed` by default, the loop view joins the event log and the git log (section 4; the `live` relabeling of a capture is a manual sidecar edit today). Approval gates and the verdict: `done --verdict` writes the note as a `verdict` artifact and the receipt carries it (section 5); Personal mode asked nothing, as designed. Design artifacts as links: untested (section 6). The loop count on panel rows: not built (section 7).

## What this pass cannot claim

That a designer's situated judgment survives the surfaces: the three run-3 instructions were pre-written. That the preview focus and the Preview button work: unbuilt. That a person can run this loop from the panel alone: `send --about` has no panel affordance yet, so the loop is a terminal workflow. The audience claim in PLAN.md, that product people who design and build can drive this, is still an inference from the mechanism.

## Next

One sitting at the rig, me as the designer, three rounds of feedback typed from the panel's Send field with the capture the feedback is about; the Preview button and `open` focusing the preview; the loop count on rows.
