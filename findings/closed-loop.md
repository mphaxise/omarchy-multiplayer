# Closed-loop pass

Status: hands-on, `live`, 2026-09-02, unofficial aarch64 port, Omarchy `0b3f1b7`, Claude Code 2.1.259. Three parts: the loop surfaces from `spec/09-closed-loop-surfaces.md` run mechanically over ssh as run 3 (raw evidence in `captures/evaluation-run3-closed-loop_hands-on_arm-port_2026-09-02/`), the same loop run from the panel as run 4 later the same evening (`captures/evaluation-run4-panel-loop_hands-on_arm-port_2026-09-02/`), and the three iterations I ran as the designer earlier in the day, which went through this chat and never touched the surfaces. The measurement in spec/09 section 8 wants a designer and the surfaces in one sitting; that sitting has not happened.

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

## Run 4, the loop from the panel

Same day, 21:25 to 21:36 PDT, after the two build items the run-3 findings named: the panel's Send field runs `send --with-capture` on a row with a registered preview, and `open`, `p`, and a Preview button focus the preview. Evidence in `captures/evaluation-run4-panel-loop_hands-on_arm-port_2026-09-02/`.

Session `loop-panel2`, a worktree of the spike repo branched from `session/loop-hello` so the page from run 3 was there to change; intent "hello.html gets a footer line, sent from the panel with a capture of the page / README.md and everything else stay untouched / The capture that travels with the instruction is the evidence". `preview --focus` with no window said `launched` and a Chromium app window came up on the page; a second call said `focused` and the compositor's active window was that one. `capture --preview` returned a 1896 by 1150 image, the window's geometry, not the screen.

| Iteration | Sent how | Capture it was about | Change |
|---|---|---|---|
| 1 | the panel's argv over ssh: `send <id> "<text>" --with-capture` | `feedback-2`, 04:31:17Z | `07cf1c5 hello, footer from the panel`, 04:31:29Z |
| 2 | the panel itself: `s`, the text, Enter, keys pressed by `wtype` | `feedback-4`, 04:33:52Z | `70307b5 hello, italic footer`, 04:34:01Z |

Between the two, `open` put the preview at the left half of the screen and the session's terminal at the right, focused (`after-open.jpg`), which is section 2 as written. `p` on the row focused the preview. Verdict `kept` at 04:35:57Z; the receipt lists both commits; `loop-view.txt` lists intent, preview, every capture, both instructions with their `[about: feedback-n]`, both commits, and the ending.

What the run found:

1. **The capture must not include the panel.** The Send field sits in an overlay that would cover part of the preview in a capture of its geometry. The panel now closes itself before the command starts (400 ms later); a failure nobody can see goes out as a toast, and a delivery shows on the row's loop count the next time the panel opens. The row's five-second result text is the casualty; the loop count is the evidence.
2. **The legend overflowed.** "p preview" as a seventh entry pushed "→ more" into an ellipsis at 400 px. The legend holds six entries; esc, every panel's close key, gives way first.
3. **The loop view sorted by kind inside a second.** The capture an instruction is about was listed after the instruction when both landed in the same second. Rows now sort by the record's own sequence; commits lead their second. Tests: 121.
4. **A scenario error is a blocked session, correctly.** The first attempt branched from `main`, which never had `hello.html`; the agent asked where the footer should go, Herdr reported `blocked`, the row would have said "needs you". The scenario was wrong and the surfaces were right; noted here because it is the first unplanned `blocked` the record has carried.
5. **Feedback labels count captures, not feedback.** `feedback-2` is the second capture on the session, not the second piece of feedback. The number is honest and the word is loose; leaving it, since the `about` reference is by path and the label is for a person scanning the artifact list.

What the run still cannot claim: that a designer's own judgment ran the loop. The two instructions were mine, written into the script; `wtype` pressed the keys a person would press. The keys and the argv are now the same path a person at the panel takes, so the sitting in section 8 has nothing left to build for and is the next thing to do with Praneet at the rig.

## Against spec/09, section by section

The goal as a three-line intent record: built and shown in the loop view and the receipt (section 1). The preview as shared canvas: `preview` registers it, `preview --focus` launches or focuses it, `open` focuses it beside the terminal, `capture --preview` grabs its geometry without a person picking a region (section 2, run 4). Situated feedback with `--about`: built and used three times in run 3; `send --with-capture` takes the capture and ties the instruction to it, from the panel's Send field in run 4 (section 3). The evidence trail: captures carry `proposed` by default, the loop view joins the event log and the git log (section 4; the `live` relabeling of a capture is a manual sidecar edit today). Approval gates and the verdict: `done --verdict` writes the note as a `verdict` artifact and the receipt carries it (section 5); Personal mode asked nothing, as designed. Design artifacts as links: untested (section 6). The panel's Preview button, `p`, and the loop count leading each row's second line: built and captured (section 7, run 4).

## What this pass cannot claim

That a designer's situated judgment survives the surfaces: the run-3 and run-4 instructions were pre-written, and in run 4 a script pressed the keys. That the loop holds for an app-id preview (a native window rather than a URL): untested. The audience claim in PLAN.md, that product people who design and build can drive this, is still an inference from the mechanism, now a mechanism with no terminal step left in it.

## Next

One sitting at the rig with Praneet as the designer: three rounds of feedback typed into the panel's Send field while looking at the preview, `open` and `p` in the flow, nothing scripted. Everything the sitting needs is built and verified as of run 4.
