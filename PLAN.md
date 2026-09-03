# Omarchy Multiplayer: experiment plan

Status: plan v2, 2026-09-01 (evening), revised after the research phase; v1 from the same morning is in git history. `decisions.md` carries the dated log. Progress as of 2026-09-02 evening: Phases 0 to 4 done, slice 1 live on the rig; Phase 5 half done (the review passes and an ssh-driven scenario run are in `findings/`; the stopwatch trials, the keyboard pass, and the closed-loop pass wait for a person at the rig); Phase 6 not started.

## Bottom line

I am testing one claim on a running Omarchy system: an agent run becomes legible and controllable for one person running several agents when the session is a durable, named object that terminals attach to, and the shell shows those sessions with their state, owner, and outputs. Omarchy 4.0.2 launches an agent as a terminal process from a keybinding, and since quattro it also ships Herdr, a background runtime that keeps agent processes alive and reports whether each one is working, blocked, idle, or done. OpenClaw 2.0 (v2026.8.1, released 2026-08-31) treats an agent run as a shared session with a creator, an owner, participants, a typed event log, and receipts. The experiment builds that model on top of Herdr as Omarchy-native scripts and a shell plugin, for people who design and build with agents, and measures whether it helps.

Decisions in force: design-led prototype on the ARM rig; first slice is one user with many agents; Herdr is the runtime and OpenClaw the pattern source; the repo is `github.com/mphaxise/omarchy-multiplayer`, public, MIT, at `/Users/praneet/Omarchy-Multiplayer`; development runs from the Mac over ssh into the VM, with Claude Code inside the VM only for baseline and walkthrough sessions.

Done means six artifacts exist: the verified pattern catalog (drafted), a recorded runtime decision (taken, pending rig confirmation), the spec set with labeled mockups (drafted, mockups pending), a working slice on the rig with a recording, an evaluation run through the Omarchy-UX protocol, and one outbound artifact that I approve before it goes out.

## What is verified

Facts below were read on 2026-09-01. `findings/research-brief-2026-09-01.md` carries the full list with sources; anything else in this document is a proposal.

**Omarchy quattro.** `bin/omarchy-agent` launches the default agent through `omarchy-launch-tui` with app id `org.omarchy.agent`; nine of eleven harnesses start in no-prompt modes. Nothing keeps the process alive after the window closes. The crash watcher is a systemd user unit that hands a coredump to the default agent through a clickable notification. Shell plugins are QML directories under `~/.config/omarchy/plugins/` that hot-reload inside the single `omarchy-shell` process, unsandboxed. Herdr is in the base package list, bound to Super+Ctrl+Return, configured to mirror Omarchy's tmux setup, with four layout functions (`hdl`, `hds`, `hdlm`, `hsl`).

**Herdr v0.8.2.** Server plus clients; named sessions with sockets under `~/.config/herdr/`; workspaces, tabs, panes; `agent start`; status detection from lifecycle hooks for six harnesses and screen manifests for the rest; a newline-delimited JSON socket API with `events.subscribe`, `agent.wait`, `notification.show`, and `agent.view.set`; worktrees under `~/.herdr/worktrees`; `--remote` over SSH. Herdr keeps no durable session identity beyond a transient agent alias and the harness's own resume id. Per-client views, delegation, and cross-host views are open discussions.

**OpenClaw 2.0.** The multi-user model, session state log, sub-agent receipts, steering queue, permission modes, managed worktrees, and trust boundary are all documented as the catalog records them. Two details in the ChatGPT brief are unsupported: editing or reordering a queued message, and a documented suggest-versus-start UX.

**Upstream.** No omacom/omarchy issue covers shared or durable agent sessions. Two discussions do, with zero replies each: #5433 (2026-04-24, human and agent as separate compositor seats) and #8463 (2026-08-26, a headless agent API for plugins). Hyprland closed multiple logical seats as not planned (2025-04-05). Community work on Omarchy: Maestro (parallel agent CLIs in tmux and worktrees), omarchy-hermes-sessions (a bar widget listing Hermes sessions), Passpage (agent-published pages in the bar).

**Rig.** Native aarch64 UTM VM on the M4, 6 vCPU, 8 GiB, software rendering, unofficial ggalancs image. Claude Code v2.1.251 installed and authenticated. Whether Herdr and the Codex CLI are present on this image is unrecorded. OpenClaw is installed nowhere.

## The question

Reading the launcher source, a second launch on Omarchy opens a second terminal window with the same app id, and each run lives exactly as long as its terminal unless the user started it inside Herdr by hand. Omarchy keeps no list of agent work as sessions, no owner, no lineage, no record of what a run produced, and no way to hand a run to another window, person, or agent. The Phase 1 baseline confirms this on the rig before anything changes.

Hypothesis H1: on Omarchy, a durable session object plus a shell panel listing sessions makes concurrent agent work legible and controllable for one user. Success signals, measured on the rig with three sessions running (one Claude Code, one Codex or OpenCode, one crash diagnosis started from the notification path):

1. From the panel, I can identify the session waiting on me within five seconds.
2. Closing every terminal window kills zero sessions; reattaching restores the live transcript.
3. A completed session shows a receipt: workspace, branch, commits, diff summary, status, and the command that started it.
4. The panel needs zero polling by me: completion and blocked states arrive as notifications.
5. Nothing in the slice launches a harness in a bypass-permissions mode unless the session's mode is Personal and I chose it.

A failed signal is recorded as a finding with its evidence and feeds the next design pass. `spec/10-evaluation-plan.md` turns each signal into a protocol.

## Scope

Slice 1 covers one user, many agents, on one machine. Sessions are created, listed, attached, sent instructions, and stopped. Each session has a workspace or git worktree, a mode (Personal, Shared, Restricted), a status, a parent when spawned by another session, a goal, artifacts, and a receipt when it ends. For people who design and build, slice 1 adds a light closed-loop layer: a goal template, a registered preview, captures labeled before and after, and a loop view in the receipt (`spec/09-closed-loop-surfaces.md`).

Out of scope for slice 1: two human identities, presence, suggest mode, remote placement, A2A federation, hostile multi-tenancy, live design-tool sync, and any change to Omarchy core. Those are slices 2 through 4 and get planned after slice 1 reports.

Design rules carried into every slice: the session is the durable object and a terminal attaches to it. Every instruction has a named author, human or agent. Ownership assigns responsibility. Access is granted separately. Agent-originated messages carry a marker that distinguishes them from user instructions. Shared mode requires per-operation approval. Every child session has a parent, a status, and a completion path that pushes back to the parent. Concurrent edits happen in isolated worktrees. Outputs persist as artifacts with receipts. Documentation states the trust boundary: a shared gateway serves people who trust each other, and isolation needs separate agents or gateways.

## Phases

Each phase ends at a review point. Timeboxes are my working estimate.

**Phase 0, scaffold. Done 2026-09-01.** Repository created and published (`c929ec0`).

**Phase 1, catalog and baseline (two days; catalog drafted).** The pattern catalog is drafted in `patterns/`, one file per OpenClaw pattern with source URL, observed date, and slice. The baseline on the rig remains: what one user sees today running two agents from the keybinding and two inside Herdr, the crash-notification path, the usage widget, window behavior under `org.omarchy.agent`. Captured before any change lands, from a pristine boot. Gate: every baseline capture carries provenance, version, and date.

**Phase 2, Herdr spike (half day, hard stop).** Answer `setup/rig-questions.md` items 2 through 10 on the ARM rig: is Herdr present and does its socket API, event stream, status detection, rename, and worktree creation behave as documented. Decision rule, written before the spike: Herdr is confirmed as the runtime if the socket API lists panes and streams `pane.agent_status_changed` for a Claude Code pane. If Herdr is absent on aarch64, move the spike to the x86-64 cloud rig for one more half day; if it fails there too, slice 1 runs in a degraded mode on `git worktree` plus tmux with status limited to running or exited, recorded in `decisions.md`. The OpenClaw install spike is deferred to the slice 2 gate.

**Phase 3, spec (three days; drafted).** `spec/00` through `spec/10` are written as proposed. The remaining work is the mockups, drawn against the rig's real bar and menu and labeled `proposed`, and a revision pass after the Herdr spike. Gate: the spec answers every open item the baseline raised, and each spec section names the catalog pattern or finding it derives from.

**Phase 4, build the slice (five days; skeleton drafted).** A proposed skeleton exists: `bin/omarchy-agent-session-core` with 53 local tests against a fake Herdr socket and real git repositories, the command wrappers, the notification watcher with its own tests, proposed diffs to the three upstream launchers under `bin/upstream-proposed/`, and the plugin skeleton under `plugin/`. Nothing in it has run on Omarchy; every Herdr wire-format assumption is marked VERIFY ON RIG. The remaining work is to run it on Herdr. The build runs from the Mac over ssh into the rig, with Claude as dev partner, working from the spec, the exact paths, the acceptance scenario, and the verified facts above. Verify with the scripted scenario in `spec/10-evaluation-plan.md`, recorded on the rig. Gate: the recording exists, each signal has a pass or fail with evidence, and no harness is launched in a bypass mode outside Personal.

**Phase 5, evaluate (two days).** Run `/ux-review` and `/design-qa` against the live slice with the Omarchy-UX lenses, run the closed-loop pass (one designer, three iterations on a preview), and write the experiment report. Gate: every finding cites a capture, and the report separates measured outcomes from judgment calls.

**Phase 6, outbound (one day).** Choose one: a listing on the community plugin marketplace (`omacom/omarchy-plugin-marketplace`, plugins.omarchy.org) with the scripts and the recording linked, or a discussion post on `omacom/omarchy` proposing the session model. Track the outcome in `findings/upstream-contributions.md`. Gate: I approve the exact text and target before it is posted.

## Repository layout

```
omarchy-multiplayer/
  README.md                 question, current slice, how to install the slice
  PLAN.md                   this document
  LICENSE                   MIT
  decisions.md              dated decision log
  patterns/                 twelve verified OpenClaw patterns, source and date in front matter
  spec/                     00 overview, 01 session model, 02 command surface, 03 sessions panel,
                            04 permission modes, 05 receipts and artifacts, 06 notifications,
                            07 worktrees, 08 identity, 09 closed-loop surfaces, 10 evaluation plan
  findings/                 research brief, prior art, CSCW insights, product-people landscape,
                            evaluation findings later, upstream-contributions.md
  captures/                 Omarchy-UX labeling rules plus proposed/live
    sessions/
    screenshots/
  spikes/                   herdr-on-rig.md after Phase 2
  setup/                    rig-questions.md; the rig itself stays documented in Omarchy-UX
  bin/                      omarchy-agent-session-* scripts
  systemd/                  omarchy-agent-session-watch.service
  plugin/                   Quickshell user plugin: agent-sessions
```

## Evidence discipline

Captures follow the Omarchy-UX rules: provenance (`doc-derived`, `video-derived`, `hands-on`), Omarchy version, capture date, and environment. This repo adds two labels. `proposed` marks any screen, command, or behavior that does not yet run on the rig; `live` replaces it once it does. Every OpenClaw claim in `patterns/` names the page it came from and the date I read it. Every spec file ends with a "Verify on rig" list, gathered in `setup/rig-questions.md`.

Findings from the ARM rig carry the unofficial-port caveat and exclude performance and rendering-quality judgments. Anything about a first-boot or installer experience waits for the x86-64 rig.

## Risks and unknowns

Herdr on the ARM image is the largest unknown. Herdr is a Rust binary packaged for Omarchy's x86-64 repo; whether the community aarch64 repo carries it is unrecorded. The Phase 2 decision rule exists so this cannot stall the experiment.

Harness flags drift. The Codex flag Omarchy ships (`--approve-for-me`) does not appear in the vendor's current CLI reference, and Claude Code's permission modes changed in 2026. The permission-mode table marks every unverified flag, and the launcher checks a deny list before exec so a drifted flag cannot silently reopen bypass mode.

The shell plugin runs unsandboxed inside the one process that draws the bar, notifications, and lock screen. The panel spec caps output, contains parse errors, and backs off on repeated failure; the rig session tests whether a plugin error stays contained.

Upstream appetite is unknown. Two discussions asking for parts of this drew no reply. The plugin-and-scripts shape keeps the experiment installable without upstream consent, and the outbound artifact is a proposal with a recording.

Automation on the rig is keyboard-only over synthetic input; ssh from the Mac sidesteps it. Until sshd is on, scripted scenarios follow the Omarchy-UX session protocol.

## Open decisions

1. Timebox for the whole experiment. Remaining phases sum to about ten working days.
2. Whether slice 1 includes the Mac watching the VM's sessions read-only (Herdr `--remote` makes this cheap to try).
3. Whether the x86-64 cloud rig gets set up before Phase 2 or only if Herdr is absent on aarch64.
4. Which harness pairs with Claude Code in the scenario: Codex, if its CLI is present in the VM, otherwise OpenCode.
5. The plugin's release id (`praneet.agent-sessions` during the experiment).

## Next actions

Items 1 to 4 of the original list are done (2026-09-01 and 2026-09-02). As of 2026-09-02 evening:

1. Twenty minutes at the rig: the keyboard pass on the restarted shell (arrows, Enter, `s`, `x`, Esc, the inline results, the stop spinner), the three stopwatch trials for signal 1, and one session created through `omarchy-agent --pick` with the picker on screen, which closes signal 5's flag.
2. Snapshot the VM as `dev-2026-09-02` before anything else lands; today's build and the rig wiring are only on the dev disk.
3. Read `findings/evaluation-slice1-2026-09-02.md` and `findings/evaluation-run1-2026-09-02.md`, then push; five commits are local.
4. Run 2 of the scenario with a session that finishes on its own (`done`) and one whose harness dies while working, to exercise the two notification rows run 1 never reached; a Codex login in the guest makes worktree B a second harness.
5. The closed-loop pass (`spec/09-closed-loop-surfaces.md`), one designer, three iterations, on a live preview.
6. Phase 6: the marketplace listing or the discussion post, text approved before it goes anywhere.
