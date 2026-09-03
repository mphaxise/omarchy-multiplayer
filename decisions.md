# Decisions

Dated log. Each entry records the decision, the alternatives considered, the reason, and what would reopen it.

## 2026-09-01

**Shape: design-led prototype on the ARM rig.** Alternatives: working prototype first; research and upstream proposal only. Reason: the load-bearing claim (the session is the durable object, a terminal attaches to it) needs a running system to test, and the design work is what makes the test fair. Reopens if the rig cannot host the slice.

**First slice: one user, many agents.** Alternatives: agent to agent; user to user; user to agent control. Reason: testable on one VM with one identity, and the session object it produces is the dependency for the other three.

**Session engine: half-day OpenClaw spike before choosing.** Alternatives: adopt OpenClaw as given; Omarchy-native from the start. Reason: no evidence yet that the OpenClaw Gateway runs on aarch64 Arch in 8 GiB beside Hyprland. Decision rule is written in `PLAN.md`, Phase 2, before the spike starts.

**Repository: public from the first commit, MIT.** Reason: findings-style discipline from Omarchy-UX, and the outbound artifact is a proposal other Omarchy users can install or read.

**Dev seat: build and verify from the Mac over ssh into the VM.** Alternative: run Claude Code inside the Omarchy VM as the development seat. Reason: the guest's 8 GiB belongs to the sessions under test, the OpenClaw spike's free-memory rule needs a quiet guest, and ssh sidesteps the UTM synthetic-input quirks. Claude Code inside the VM is used for the baseline and walkthrough sessions only, because those sessions are evidence.


## 2026-09-01, evening, after the research phase

**Runtime: Herdr, through its socket API.** Alternatives: OpenClaw Gateway as the session engine; an Omarchy-native layer on tmux or abduco. Reason: Omarchy quattro already ships Herdr, bound to Super+Ctrl+Return, with a background server that survives window close, per-pane agent status detection, an events stream, and worktree support; building a second runtime beside it would duplicate what the distribution already installs. Fallback if Herdr is absent or broken on the ARM image: the x86-64 rig for one more half day, then a degraded mode on `git worktree` plus tmux with status limited to running or exited. Reopens if the Herdr spike (`setup/rig-questions.md`, items 2 to 10) fails on both rigs.

**OpenClaw: pattern source, install spike deferred.** The twelve catalog entries in `patterns/` carry its session, attribution, event, permission, and trust patterns into the spec. The Gateway install spike moves to the slice 2 gate, where a second person needs a gateway. Reopens if slice 2 starts.

**Session identity lives in Omarchy state.** Records under `~/.local/state/omarchy/sessions/<id>/`; Herdr's transient agent alias mirrors the session name. Reason: Herdr keeps no durable session identity beyond the harness's own resume id, and the experiment's object must outlive panes and reboots.

**Audience: AI-native product people who design and build.** Slice 1 adds a light closed-loop layer (`spec/09-closed-loop-surfaces.md`): goal template, registered preview, labeled captures, loop view, verdict. Reason: the essay this experiment rests on and the product-people landscape both point at a loop record no tool owns. Reopens if the closed-loop pass in evaluation shows the layer adds cost without legibility.

**Upstream framing corrected.** The morning plan called the upstream white space clean; two discussions (#5433, #8463) ask for parts of this with zero replies, and community plugins (Maestro, omarchy-hermes-sessions, Passpage) cover pieces. The outbound artifact acknowledges that lineage.

**Spec status: proposed.** Every file in `spec/` is proposed until the first rig session revises the session model. Nothing is live.

## 2026-09-02

**Runtime confirmed: Herdr.** The spike in `spikes/herdr-on-rig.md` met the decision rule from PLAN.md Phase 2: Herdr 0.8.2 is installed on the ARM image, its socket API lists panes and streams events to an external subscriber, `agent.start` launched Claude Code, metadata survives a config reload, and worktrees work. The Claude Code turn with `working`, `blocked`, and `done` transitions was observed after the in-VM login, so the rule is met in full. The degraded tmux fallback is retired.

**Wire format settled from the rig.** The core and the watcher now follow the observed protocol: `{"id", "method", "params"}` requests, `{"id", "result": {"type": ...}}` replies, `events.subscribe` with a `subscriptions` list of dotted types, underscored event names in the stream, and `session.snapshot` as the snapshot method. The full schema for protocol 20 is stored in `spikes/`.

**Review verdicts, afternoon.** From the `/ux-review` and `/design-qa` passes (`findings/evaluation-slice1-2026-09-02.md`): P1 blocks a public push; Option B, craft-first, for the open findings; stop-ship until the bar glyph and the state dots pass 3:1, because WCAG AA is the floor for anything carrying the Omarchy-UX method. All three are built (bad8373, cbac0e9). The feeling question the review asked (calm, control, or safety) stays open; the build treats control as the tie-breaker.

**The guest Claude stays plain.** The public design skill pack is installed in the VM under `~/.claude/skills/`; my private personal overlay is not, and anything that needs it runs from the Cowork seat on the Mac. Reason: private material stays out of the guest.

**Evaluation run 1 counts as evidence, not as the verdict.** The scenario ran over ssh without a stopwatch or a person; signals 2, 3, and 5 pass, 4 passes on one event, 1 is unmeasured (`findings/evaluation-run1-2026-09-02.md`). The verdict waits for a run that uses the panel's own keys and the stopwatch.

**The stopwatch is withdrawn from signal 1.** Late evening. I will not run the three five-second trials. Signal 1 is restated in `PLAN.md` as a capture-verified criterion: the waiting session is the first thing named on every surface (toast, badge, hero, first row), and runs 1 and 2 hold that evidence. Reason: one person with a stopwatch on a software-rendered VM measures the VM as much as the panel, and what the design controls is the cue chain, which the captures show. Consequence: the verdict rule in `spec/10` reads "measured by capture" for signal 1; the report says so.

**The rig stays on Omarchy 0b3f1b7.** `omarchy-update` ran on the aarch64 image at 20:22 and updated nine Arch packages, Claude Code among them (2.1.252 to 2.1.259 through mise), and nothing of Omarchy itself: `/usr/share/omarchy` is a root-owned git checkout no package owns, and `omarchy-update-dev` exits without pulling when the path is `/usr/share/omarchy`. The port's package repo carries an `omarchy` 4.0.1-2 package, which is its intended update path and is not installed. Nothing the plugin depends on changed upstream, so the evaluation stays consistent on one Omarchy commit with one harness bump, recorded here. Installing the package is a root action for a snapshot first, and the gap goes to the port maintainer.

**The panel closes itself to take a capture.** Late evening, run 4 (`findings/closed-loop.md`). Feedback typed into a row's Send field while a preview is registered goes out as `send --with-capture`, and the capture is of the preview window's geometry, which the panel overlay would cover. So the panel closes, the command starts 400 ms later, a failure nobody can see goes out as a toast, and the row's loop count is the evidence of delivery. The alternative, capturing with the panel in the picture, would hand the agent an image with a session list over the thing the feedback is about. The legend caps at six entries, esc first to go, because "p preview" as a seventh elided "→ more".

**The closed loop is verified from a script, and the sitting is Praneet's.** Runs 3 and 4 exercised every spec/09 surface the panel exposes, with pre-written instructions and, in run 4, `wtype` pressing the keys. That verifies the mechanism and nothing about a designer's judgment. The one sitting spec/09 section 8 asks for stays open until Praneet runs it at the rig; no script will stand in for it.

**Phase 6 is drafted, and every outbound choice stays Praneet's.** Late evening. `outbound/` holds the marketplace listing package (README, install and uninstall scripts, preview, a build script that assembles the listing repository and that `omarchy plugin validate` accepts on the rig), the submission text in the marketplace's own form, a discussion post for omacom/omarchy, and one issue text per upstream candidate. Both the listing and the post are drafted so the choice between them is made on the texts. The plugin id is left as built, `praneet.agent-sessions`, with the build able to apply `io.github.mphaxise.agent-sessions`, because the marketplace makes ids permanent and a rename touches the plugin directory, the IPC target, and the bindings on every machine that has it. Nothing is created or posted on GitHub until he approves the exact text and target.

**The plugin is Keepalive.** Late evening, Praneet's pick from five names (Keepalive, Still Running, Standing Agents, Agent Keep, Long Run). "Agent Sessions" named the object; Keepalive names the promise, coding agents that stay running on the desktop after the terminal is gone. The listing id is `io.github.mphaxise.keepalive`, the listing repository `mphaxise/omarchy-keepalive`; the commands stay `omarchy-agent-session-*` because they describe the object. The dev checkout and the rig keep `praneet.agent-sessions` until the rig runs one session under the listing id, a rename that touches the rig's bindings and waits for a go.
