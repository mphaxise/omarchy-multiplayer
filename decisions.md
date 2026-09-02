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
