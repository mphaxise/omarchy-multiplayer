# Omarchy Multiplayer: experiment plan

Status: plan, 2026-09-01. Revised at each phase review; `decisions.md` carries the dated log.

## Bottom line

I am going to test one claim on a running Omarchy system: an agent run becomes legible and controllable for one person running several agents when the session is a durable, named object that terminals attach to, and the shell shows those sessions with their state, owner, and outputs. Omarchy 4.0.2 treats an agent run as a terminal process launched from a keybinding. OpenClaw 2.0 (v2026.8.1, released 2026-08-31) treats it as a shared session with a creator, an owner, participants, and receipts. The experiment ports the parts of that model that fit Omarchy's shape and measures whether they help.

Decisions made today: design-led prototype on the ARM rig; first slice is one user with many agents; OpenClaw gets a half-day spike on the rig before I choose the session engine; the repo is `github.com/mphaxise/omarchy-multiplayer`, public, MIT, at `/Users/praneet/Omarchy-Multiplayer`.

Done means six artifacts exist: a verified pattern catalog, a recorded engine decision, a spec with labeled mockups, a working slice on the rig with a recording, an evaluation run through the Omarchy-UX protocol, and one outbound artifact (an upstream discussion post or a plugin release) that I approve before it goes out.

## What is verified today

Facts below were read live on 2026-09-01. Anything else in this document is a proposal.

**OpenClaw 2.0.** Version 2026.8.1 shipped 2026-08-31 with over 16,000 merged pull requests from 933 contributors (InfoQ, 2026-09-01). The multi-user model has three attribution layers: an immutable creator, an assignable owner in the style of a GitHub issue assignee, and a participant history capped at 32 identities per session. The docs state the trust boundary in plain terms: ownership, sidebar visibility, and presence are usability features. Isolation requires separate agents or separate gateways. Drafts hide work from teammates' sidebars until published, with admins excepted. Agent-spawned sessions return a receipt with the child session key, run id, a Control UI URL, and an owner record. Verified GitHub identities get `Co-authored-by` credit on commits. Cloud sessions keep the transcript, reconciled workspace, and credentials on the Gateway while execution runs on a paired device or a leased machine; both the OpenClaw runtime and Codex (`remote-exec`) use that path. Sources: `docs.openclaw.ai/concepts/multi-user`, `docs.openclaw.ai/gateway/cloud-sessions`.

**OpenClaw pages I have seen only by title.** Session state awareness, session tools, steering queue, command queue, parallel specialist lanes, delegate architecture, presence, session permission modes, session dashboards, managed worktrees, CLI backends, multi-tenant hosting. The ChatGPT brief paraphrases several of these. The pattern catalog reads each one before it cites it.

**Omarchy 4.0.2 agent surfaces** (default branch `quattro`, read from `omacom/omarchy`). `bin/omarchy-agent` launches the default agent through `omarchy-launch-tui` with app id `org.omarchy.agent`, starting in `~/Work` so trust grants persist. Eleven agents are selectable on that branch today: pi, omp, opencode, ori, claude, codex, grok, agy, hermes, copilot, crush. Nine of them launch in a no-prompt mode: `claude --permission-mode auto`, `codex --approve-for-me`, `opencode --auto`, `copilot --allow-all`, `crush --yolo`, `grok --permission-mode bypassPermissions`, `hermes --yolo`, `agy --dangerously-skip-permissions`, `omp --auto-approve`. Pi and Ori have no such flag. `omarchy-agent-crash` builds a prompt from `coredumpctl` and hands it to the default agent with the `diagnose-crash` skill. Omarchy ships two skills into harnesses, `diagnose-crash` and `omarchy`, the latter documenting hooks, plugins, Hyprland, and theming. Usage collectors exist for Claude, Codex, and Fireworks. User shell plugins live in `~/.config/omarchy/plugins/<plugin-id>/`, run inside the single Quickshell `omarchy-shell` process, and hot-reload on save. Hook directories exist for post-boot, post-update, pre-refresh-pacman, theme-set, font-set, and battery-low.

**Upstream white space.** An issue search on `omacom/omarchy` for "openclaw", "multiplayer", "collaborate", "multi-agent", and "agent session" returned no issue about shared or durable agent sessions. Discussions were not searched.

**Rig.** The secondary rig from Omarchy-UX is live: native aarch64 UTM VM on the M4, 6 vCPU, 8 GiB, software rendering, unofficial ggalancs image, `omarchy-version` reports `unknown`. Claude Code v2.1.251 is installed and authenticated in the VM. The ChatGPT desktop package installs through the community aarch64 repo. Codex CLI status in the VM is unrecorded. The x86-64 cloud rig was approved 2026-08-31 and has no setup log entry yet. OpenClaw is installed on neither the Mac nor the VM.

**Claims from the ChatGPT brief I could not confirm.** A Quickshell "Agents panel" with usage tabs, usage records aggregated across machines, A2A 1.0 support in OpenClaw, and OpenClaw's swarm and state-version mechanics. These stay out of the plan until the catalog reads their sources.

## The question

Reading the launcher source, a second launch on Omarchy opens a second terminal window with the same app id, and each run lives exactly as long as its terminal. Omarchy keeps no list of running agent work, no state per run, no record of what a run produced, and offers no way to hand a run to another window, person, or agent. The Phase 1 baseline confirms this on the rig before anything changes.

Hypothesis H1: on Omarchy, a durable session object plus a shell panel listing sessions makes concurrent agent work legible and controllable for one user. Success signals, measured on the rig with three sessions running (one Claude Code, one Codex or OpenCode, one crash diagnosis started from the notification path):

1. From the panel, I can identify the session waiting on me within five seconds.
2. Closing every terminal window kills zero sessions; reattaching restores the live transcript.
3. A completed session shows a receipt: workspace, branch, commits, diff summary, status, and the command that started it.
4. The panel needs zero polling by me: completion and blocked states arrive as notifications.
5. Nothing in the slice launches a harness in a bypass-permissions mode unless the session's mode is Personal and I chose it.

A failed signal is recorded as a finding with its evidence and feeds the next design pass.

## Scope

Slice 1 covers one user, many agents, on one machine. Sessions are created, listed, attached, sent instructions, and stopped. Each session has a workspace or git worktree, a mode (Personal, Shared, Restricted), a status, a parent when spawned by another session, and a receipt when it ends.

Out of scope for slice 1: two human identities, presence, suggest mode, remote placement, A2A federation, hostile multi-tenancy, and any change to Omarchy core. Those are slices 2 through 4 and get planned after slice 1 reports.

Design rules carried into every slice, stated affirmatively: the session is the durable object and a terminal attaches to it. Every instruction has a named author, human or agent. Ownership assigns responsibility. Access is granted separately. Agent-originated messages carry a marker that distinguishes them from user instructions. Shared mode requires per-operation approval. Every child session has a parent, a status, and a completion path that pushes back to the parent. Concurrent edits happen in isolated worktrees. Outputs persist as artifacts with receipts. Documentation states the trust boundary: a shared gateway serves people who trust each other, and isolation needs separate agents or gateways.

## Phases

Each phase ends at a review point. Timeboxes are my working estimate and get revised at the first review.

**Phase 0, scaffold (half day).** Create the repository with the layout below, a README that states the question and the current slice, and the capture rules copied from Omarchy-UX with one addition: every proposed screen carries `proposed` until it runs on the rig, then `live`. Gate: I approve creating the public repository before anything is pushed.

**Phase 1, catalog and baseline (two days).** Write the pattern catalog: one file per OpenClaw pattern, each with the source URL, the observed date, a paraphrase in my words, the Omarchy surface it maps to, and the slice it belongs to. Capture the baseline on the rig, hands-on and labeled: what one user sees today when running two agents at once, the crash-notification path, the usage widget, window behavior under `org.omarchy.agent`. The baseline is the before picture for the portfolio record, so it is captured before any change lands. Gate: catalog entries cite pages I read, and every baseline capture carries provenance, version, and date.

**Phase 2, OpenClaw spike (half day, hard stop).** Install the OpenClaw Gateway in the ARM VM. Record whether it installs on aarch64 Arch, whether it hosts a CLI-backend session for Claude Code, what it costs in RAM on an 8 GiB guest, whether the Control UI runs in the guest's Chromium under software rendering, and whether a browser on the Mac attaches to the same session through the VM's Control UI. Decision rule, written before the spike starts: OpenClaw becomes the engine if it runs on the rig, hosts a Claude Code session end to end, and leaves at least 3 GiB free. Otherwise slice 1 uses an Omarchy-native session layer (systemd user units, a persistent PTY through tmux or abduco, JSON state under `~/.local/state/omarchy/agent-sessions/`, desktop notifications through the Omarchy shell) and OpenClaw returns as a candidate for slice 3. If the ARM guest is the blocker, the x86-64 cloud rig gets one more half day. The decision and its evidence go in `decisions.md`.

**Phase 3, spec (three days).** Specify the session object (identity, workspace, mode, status, parent, receipt), the command surface for slice 1 (`omarchy agent new`, `list`, `open`, `send`, `stop`; `share` and `take` reserved for slice 2), the Sessions panel as a user shell plugin at `~/.config/omarchy/plugins/<user>.agent-sessions/`, the notification behavior (notify on state change, coalesce repeats, suppress self-notifications), the three permission modes and what each does to today's launch flags, and worktree creation per coding session. Mockups are drawn against the rig's real bar and menu and labeled `proposed`. Gate: the spec answers every open item the baseline raised, and each spec section names the catalog pattern it derives from.

**Phase 4, build the slice (five days).** Implement the scripts, the systemd user units, the session state, the panel plugin, and the receipts, on the engine Phase 2 chose. Verify with a scripted scenario that exercises the five success signals, recorded on the rig. The build runs from the Mac over ssh into the rig, with Claude as dev partner, working from the spec, the exact paths, the acceptance scenario, and the verified facts above. Claude Code inside the VM is reserved for the baseline and walkthrough sessions, which are evidence. Gate: the scenario recording exists, each signal has a pass or fail with evidence, and no harness is launched in a bypass mode outside Personal.

**Phase 5, evaluate (two days).** Run `/ux-review` and `/design-qa` from the design skill pack against the live slice, using the Omarchy-UX lenses: usability, accessibility, trust and handoff. Findings cite captures and carry `live` labels. Write the experiment report: what H1 predicted, what the rig showed, what changed in the design as a result. Gate: every finding cites a capture, and the report separates measured outcomes from my judgment calls.

**Phase 6, outbound (one day).** Choose one: a discussion post on `omacom/omarchy` proposing the session model with the recording attached, or a tagged release of the plugin plus scripts for other Omarchy users to install. Track the outcome in `findings/upstream-contributions.md` the way Omarchy-UX does. Gate: I approve the exact text and target before it is posted.

## Repository layout

```
omarchy-multiplayer/
  README.md                 question, current slice, how to install the slice on Omarchy
  PLAN.md                   this document
  LICENSE                   MIT
  decisions.md              dated decision log, engine decision first
  patterns/                 one file per verified OpenClaw pattern, source and date in front matter
  spec/                     session model, command surface, panel, modes, worktrees, mockups
  captures/                 Omarchy-UX labeling rules plus proposed/live
    sessions/
    screenshots/
  spikes/                   openclaw-on-rig.md with the install log and measurements
  setup/                    rig facts this experiment depends on; the rig itself stays documented in Omarchy-UX
  bin/                      omarchy-agent-session-* scripts
  systemd/                  user units
  plugin/                   Quickshell user plugin: agent-sessions
  findings/                 evaluation findings, experiment report, upstream-contributions.md
```

## Evidence discipline

Captures follow the Omarchy-UX rules: provenance (`doc-derived`, `video-derived`, `hands-on`), Omarchy version, capture date, and environment. This repo adds two labels. `proposed` marks any screen, command, or behavior that does not yet run on the rig; `live` replaces it once it does. Every OpenClaw claim in `patterns/` names the page it came from and the date I read it, because the project rewrote much of itself in the seven weeks before 2.0 and the docs will keep changing.

Findings from the ARM rig carry the unofficial-port caveat and exclude performance and rendering-quality judgments. Anything about a first-boot or installer experience waits for the x86-64 rig.

## Risks and unknowns

OpenClaw on the rig is the largest unknown: it is a gateway with its own agent runtime, and I have no evidence it runs on aarch64 Arch or fits beside Hyprland in 8 GiB. The Phase 2 decision rule exists so this cannot stall the experiment.

Upstream appetite is unknown. Omarchy is bash and Quickshell, the maintainers have not asked for shared sessions, and an external gateway as a core dependency would be a hard sell. The plugin-and-scripts shape keeps the experiment installable without upstream consent, and the outbound artifact is a proposal with a recording, which is what a maintainer can evaluate.

Today's launch flags are the trust risk. Every harness starts in a mode that skips approvals, which is workable for one person at one keyboard and wrong for a shared session. The three modes exist so the slice never widens that exposure, and the mode design is where the trust-and-handoff lens does most of its work.

Automation on the rig is keyboard-only and drops `/` and bulk text; scripted scenarios in Phase 4 need the per-key path and a fronted VM window, per the Omarchy-UX session protocol.

Claims in the ChatGPT brief are a starting list. Four of them are unconfirmed after one pass. The catalog is the filter between that brief and the spec.

## Open decisions

1. Timebox for the whole experiment. The phases above sum to fourteen working days, about three weeks at full attention.
2. Whether slice 1 includes a second machine in a read-only role (the Mac watching the VM's sessions) or stays strictly single-machine.
3. Whether the x86-64 cloud rig gets set up before Phase 2 or only if the ARM spike fails.
4. Which harness pairs with Claude Code in the scenario: Codex, if its CLI is present in the VM, otherwise OpenCode.

## Next actions

1. Confirm or edit the open decisions above.
2. Snapshot the ARM VM as `dev-2026-09-01`, enable sshd in the guest, and record the guest IP and the rig change in `setup/`.
3. Check whether the Codex CLI is installed in the VM and record the answer in `setup/`.
4. Snapshot again before the OpenClaw spike so Phase 2 is reversible.
