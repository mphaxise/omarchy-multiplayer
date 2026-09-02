# Decisions

Dated log. Each entry records the decision, the alternatives considered, the reason, and what would reopen it.

## 2026-09-01

**Shape: design-led prototype on the ARM rig.** Alternatives: working prototype first; research and upstream proposal only. Reason: the load-bearing claim (the session is the durable object, a terminal attaches to it) needs a running system to test, and the design work is what makes the test fair. Reopens if the rig cannot host the slice.

**First slice: one user, many agents.** Alternatives: agent to agent; user to user; user to agent control. Reason: testable on one VM with one identity, and the session object it produces is the dependency for the other three.

**Session engine: half-day OpenClaw spike before choosing.** Alternatives: adopt OpenClaw as given; Omarchy-native from the start. Reason: no evidence yet that the OpenClaw Gateway runs on aarch64 Arch in 8 GiB beside Hyprland. Decision rule is written in `PLAN.md`, Phase 2, before the spike starts.

**Repository: public from the first commit, MIT.** Reason: findings-style discipline from Omarchy-UX, and the outbound artifact is a proposal other Omarchy users can install or read.

**Dev seat: build and verify from the Mac over ssh into the VM.** Alternative: run Claude Code inside the Omarchy VM as the development seat. Reason: the guest's 8 GiB belongs to the sessions under test, the OpenClaw spike's free-memory rule needs a quiet guest, and ssh sidesteps the UTM synthetic-input quirks. Claude Code inside the VM is used for the baseline and walkthrough sessions only, because those sessions are evidence.
