# Omarchy Multiplayer

An experiment on top of [Omarchy](https://omarchy.org): make an agent session a durable, named object that terminals attach to, and give the shell a view of those sessions with their state, owner, and outputs. Omarchy 4.0.2 launches a coding agent as a terminal process from a keybinding. OpenClaw 2.0 treats an agent run as a shared session with a creator, an owner, participants, and receipts. This repository ports the parts of that model that fit Omarchy's shape, as a user shell plugin plus scripts, and measures whether they help.

## The question

One hypothesis, tested on a running system: a durable session object plus a shell panel listing sessions makes concurrent agent work legible and controllable for one user. [`PLAN.md`](PLAN.md) states the five success signals, the phases, and the gates.

## Current slice

Slice 1 covers one user, many agents, one machine. Sessions are created, listed, attached, sent instructions, and stopped; each has a workspace, a permission mode, a status, a parent when spawned, and a receipt when it ends. Two human identities, presence, remote placement, and federation are later slices.

## Status

Slice 1 is live on the ARM rig as of 2026-09-02: sessions survive window close and reboot, receipts are written, blocked and orphaned states arrive as notifications, and the bar widget and panel run as a user plugin. `findings/evaluation-slice1-2026-09-02.md` holds the `/ux-review` and `/design-qa` passes against that build, the fixes they forced, and the acceptance audit. Omarchy already ships Herdr as a durable agent runtime, so the session model sits on top of it; `findings/research-brief-2026-09-01.md` records what that changed. `findings/closed-loop.md` holds the closed-loop pass: a goal, a registered preview, feedback sent with the capture it was about, from the terminal (run 3) and from the panel (run 4), commits, a verdict, and a loop view that shows every step. The plugin ships as Keepalive: public at [mphaxise/omarchy-keepalive](https://github.com/mphaxise/omarchy-keepalive), submitted to the plugin marketplace (issue #4566), and proposed to Omarchy in discussion #9936; `outbound/` holds how those were built and six upstream issue texts still unfiled. Next: Praneet's own sitting at the panel as the designer, and whatever the marketplace's validation says.

Slices 2 and 3 as of 2026-09-03: agent lanes (`spec/11-agent-lanes.md`) held all five slice-2a signals on the rig, two Claude Code lanes on one goal with a merge and a forced conflict (`findings/evaluation-run9-lanes-2026-09-03.md`), and ship as Keepalive 0.2.0 once pushed; watchers and artifact links landed with them. Two people on one session (`spec/12-two-people.md`) held in proxy form, the Mac over ssh as the second person (`findings/evaluation-run10-two-people-2026-09-03.md`): visibility, access, a suggestion the owner accepts or dismisses from the panel, assignment, presence outside the record. What those runs cannot say is whether a person stays oriented on any of it; the sittings are ahead.

History, as of 2026-09-03 afternoon, merged from `slice-4/history` into `main`: the record keeps every session and nothing ages out (`spec/01-session-model.md`, Retention); the panel reads through a one-day window and says how many ended before it, `e` opens `history` (fourteen days by day), and a session a person stopped resumes its conversation on Enter (`findings/evaluation-run12-history-2026-09-03.md`). It came from Praneet's question after a VM start, where yesterday's agents were: the record had them, the panel hid them after a day, and `open` refused them.

## Known issues

Slice 1 ships with these, each with its repro in `findings/evaluation-slice1-2026-09-02.md`:

- A question and a permission prompt both reach the panel as one state, because Herdr reports both as `blocked`; every surface says "needs you" until the hook payload can tell them apart.
- A `send` to an agent at a permission prompt is delivered through Herdr's `agent.prompt`; whether the harness accepts text there is untested. The row reports the exit code either way.
- The five-second identification trials for signal 1 have not run; nothing here claims that signal passes.
- On the ARM image every Claude launch raises a locked-keyring password prompt; it is the image's fault and it lands in every launch path.
- After a plugin file changes, the shell's hot reload leaves the live widget on old code; `omarchy-restart-shell` makes the change real, and on this VM under load its two-second readiness check can report failure while the shell is still coming up.

## Where to start reading

`PLAN.md` for the question, the five success signals, and the phases. Keepalive, the installable plugin, is built from this repository by `outbound/build-listing.sh` and released by `outbound/release-keepalive.sh`; `main` ships, slice work branches. `spec/00-overview.md` for the architecture and the map of spec files. `findings/research-brief-2026-09-01.md` for the evidence and the decisions it forced. `decisions.md` for the dated log. `bin/`, `systemd/`, `plugin/`, and `tests/` hold the build; `python3 -m unittest discover -s tests` runs the 167 local tests, and `bin/README-core.md` lists the assumptions and what the rig confirmed.

## Relationship to Omarchy-UX

[Omarchy-UX](https://github.com/mphaxise/omarchy-ux) evaluates Omarchy's shipped agent surfaces and contributes fixes upstream. This repository builds a new surface and evaluates it with the same protocol and capture discipline. The test rig is documented there.

## Evidence discipline

Every capture carries provenance, Omarchy version, date, and environment; every proposed screen or command is labeled `proposed` until it runs on the rig, then `live`. Every OpenClaw claim in `patterns/` names its source page and the date it was read. Rules in [`captures/README.md`](captures/README.md).

## Author

Praneet Koppula, product design leader working on AI-native experiences for complex, expert workflows. Built with Claude as dev partner. Related work: [ai-agent-ux-research-platform](https://github.com/mphaxise/ai-agent-ux-research-platform), [design-skill-pack-for-ai-agent-coding-platforms](https://github.com/mphaxise/design-skill-pack-for-ai-agent-coding-platforms).
