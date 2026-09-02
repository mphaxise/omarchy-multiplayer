# Prior art: session models for agent work

Status: findings, doc-derived, 2026-09-01.

## Bottom line

Every piece omarchy-multiplayer needs already ships somewhere. A session that survives closing its window runs today in Herdr and Maestro. Ownership separate from access runs today in OpenClaw. Real people joining a running agent thread runs today in Amp and Warp. A shell widget reading agent state off disk runs today in omarchy-hermes-sessions. None of these live together, and none live inside a Linux desktop shell. Herdr and Maestro are terminal tools on top of whatever desktop runs under them. OpenClaw is a gateway reached through chat apps and a web dashboard. Amp and Warp are hosted products with their own accounts and billing. The object PLAN.md describes, a session the shell itself treats as durable, with state, owner, and outputs, has no occupant yet.

Each source proves a different slice of the claim. Herdr proves a background server plus status detection scales to real agent CLIs without the harness knowing it is being watched. OpenClaw proves creator, owner, and participant can be three separate fields on one session object, enforced by a gateway instead of convention. Amp and Warp prove a live agent thread can take a second, third, and fourth person mid-run without the harness changing. Claude Code's Agent Teams proves that tagging another agent's output as data holds up in production. Maestro proves the worktree convention Omarchy's own shell already uses makes parallel sessions interchangeable across tools built by strangers. None of them prove the desktop-shell integration itself. That part stays open.

## Comparison

| Tool | What a session is | Survives window close | Shown how | Attribution | Worktree | Notifies | Multi-person | Owns | Verified |
|---|---|---|---|---|---|---|---|---|---|
| Herdr | Named pane in a background server | Yes | Sidebar status, OS toast | No | Yes | Yes | Mirrors one frame to all clients | Owner (session table, worktrees) | 2026-09-01 |
| Maestro | tmux session bound to a worktree | Yes | Sidebar status mark | No | Yes | Partial | No | Owner (worktrees, tmux) | 2026-09-01 |
| omarchy-hermes-sessions | Row in Hermes's own SQLite store | Depends on Hermes | Bar popup, hides if empty | No | Not shown | No, 30 s poll | No | Reader | 2026-09-01 |
| Claude Code sessions, Remote Control, Agent Teams | JSONL transcript; teams get a session-derived directory | Yes | `/resume` picker; teammate rows in the agent panel | Agent tag only | Yes, `--worktree` | Yes, idle push to lead | No, same account or spawned agents | Single owner | 2026-09-01 |
| Codex cloud | Task in an isolated cloud environment, own branch | Yes | List: state, Sharing, Creator, date | Creator email | Cloud environment | Reaches a reviewable result | Sharing: Workspace | Creator recorded | 2026-09-01 |
| Cursor cloud agents | Isolated VM per run | Yes | Shareable URL | Starting user | Cloud VM | Relays to Slack, GitHub, Linear | Read-only by default; admin-granted follow-ups | Reader vs granted follow-up | 2026-09-01 |
| Zed threads, Parallel Agents | Thread plus its own worktree | Not addressed | Threads sidebar | None | Yes, per thread | Not described | No, one developer | Owner (threads) | 2026-09-01 |
| Amp orbs, Multiplayer | Thread bound to a cloud orb | Yes | Multiplayer menu | Owner fixed, owner bills | Orb is the unit | @-tag auto-invites | Any workspace member, time-boxed | Owner bills, no reader tier | 2026-09-01 |
| Warp session sharing | Live session mirrored through Warp | Link, expires | Live prompts, thinking, credits | Owner controls access | Separate feature | Real-time sync | Multi-viewer, own cursors | Owner, collaborator, team, link tiers | 2026-09-01 |
| OpenClaw 2.0 | Gateway-owned key with a shareable URL | Yes | Control UI, typed state-event log | Creator fixed, owner assignable | Yes, 30-day snapshots | Yes, versioned event log | Up to 32 identities per session | Creator, owner, admin split | 2026-09-01 |
| Emdash | Orchestrator-tracked task | Yes (worktrees) | Local app UI | None documented | Yes | Not documented | No | Owner (SQLite, worktrees) | 2026-09-01 via C |
| Agent Orchestrator | Daemon-tracked session with terminal | Yes | Dashboard: working, waiting, finished, blocked | None documented | Yes | CI, review, conflicts routed back | No | Owner | 2026-09-01 via C |
| Claude Squad | tmux session bound to a worktree | Yes | TUI status mark | No | Yes | Not documented | No | Owner (tmux table, worktrees) | 2026-09-01 |
| Nimbalyst | Kanban card per session | Yes (files on disk) | Kanban board, mobile dashboard | None documented | Yes | Mobile push | Not confirmed | Owner (kanban, worktrees, closed sync) | 2026-09-01 via C |
| CloudCLI | Reads `~/.claude` transcripts | Read-only | Web UI | No | No | No | Paid cloud tier only | Reader (self-hosted) | 2026-09-01 via C |
| Agent Sessions | macOS reader across ten agents | Read-only | Native macOS UI | No | No | Usage alerts | No | Reader | 2026-09-01 via C |
| Vibe Kanban | Kanban issue plus agent workspace | Local workspace yes; hosted layer shut down | Kanban board, diff comments | None described | Yes, per workspace | Not documented | Was hosted; local only now | Owner | 2026-09-01 |
| Windows agent workspace | Contained desktop session for Copilot Actions | Windows-managed | Auditable separate desktop | No agent account in that post | No | Not described | No | n/a | 2026-09-01 |
| UFO2 | Single-device task run | n/a | CLI, log output | No | No | No | One user, several agents | n/a | 2026-09-01 |
| Multi | Thesis that the desktop itself is multiplayer | n/a | n/a | n/a | n/a | n/a | Conceptual; product sunset 2024-07-24 | n/a | 2026-09-01 |

"via C" marks rows carried from the prior-art research pass earlier the same day, which read each repository; they were not re-fetched in this pass.

## Omarchy-specific findings

Two Omarchy discussions ask for parts of this, and neither found traction. Discussion #5433, opened 2026-04-24 by zigmoo, asks for a second compositor seat so an agent gets its own cursor, clipboard, and browser. It drew one reaction and zero comments. Discussion #8463, opened 2026-08-26 by ronald2wing, asks for a headless JSON API to Omarchy's bundled agent, since plugins now hand-roll their own model clients. It also drew zero comments. Hyprland's issue #1731, requesting multiple logical seats, is closed as not planned (2025-04-05).

blinry's 2026-07-28 survey of multi-seat Wayland rates the core protocol a full 5 out of 5, sway and River 4 out of 5, Weston 3, niri 1. It tests GTK, SDL, Kitty, Alacritty, Firefox, Chromium, and wayvnc. Chromium ignores additional seats. Hyprland is absent from the post.

Session-level multiplayer, the object PLAN.md describes, needs no compositor work. Herdr, Maestro, and OpenClaw prove it out in userspace: a background process, a named session, a worktree, a notification. Desktop-seat multiplayer, two input devices with two cursors sharing one Hyprland session, is a harder problem sitting upstream in the compositor and in every toolkit above it. Both Omarchy discussions ask for that harder problem and got no response. This experiment targets the one that does not require Hyprland to change.

## Additions, 2026-09-02 afternoon

Three items surfaced by a Claude Code session running inside the rig, verified from here through the GitHub API. `omacom/omarchy-plugin-marketplace` (215 stars, pushed 2026-09-02) and plugins.omarchy.org are live: the community plugin directory is the natural outbound channel for this experiment's plugin, ahead of a discussion post. Discussion #532 (Support Multiple Users, 2025-08-07, ten comments) belongs beside #5433: a 2026-08-18 comment ties multi-user accounts to Quattro's agentic use, which is this experiment's slice-2 identity question raised in the maintainers' forum by a user; a claim that a maintainer promised multi-user in 4.1 does not appear in that thread's comments and stays unverified. Discussion #3273 (RDP to an Omarchy machine, 2025-11-09) and the Sunshine and Moonlight path in the manual's gaming page cover remote display, which is slice-4 territory.

## Patterns worth carrying

OpenClaw treats ownership as an assignable field. Creator stays immutable, owner reassigns like a GitHub issue assignee, and a teammate's draft stays hidden until published. It is the cleanest version I found of ownership assigning responsibility while access is granted separately.

OpenClaw's session state log is a durable, versioned signal. Each watcher keeps its own cursor and gets one pending notice per pair, so nobody drowns in duplicate pings.

Amp's Multiplayer is off by default, time-boxed, and scoped to a single thread. Everyone invited gets write access while it lasts; the bill and the default state stay with the owner. Multiplayer is a grant, not a standing permission.

Warp splits viewing from editing on the same live session and gives every simultaneous viewer a distinct cursor and avatar. Presence and permission are two separate settings.

Herdr's status detection mixes two mechanisms honestly: six agent kinds report their own lifecycle, everyone else gets matched against a rule manifest, and `herdr agent explain` names the rule that fired.

Maestro and Claude Code both put a worktree beside the repository with a branch-derived name. Two tools built by strangers produce interchangeable worktrees.

Claude Code's Agent Teams tags every inter-agent message as data the receiving model should treat with suspicion. Agent-originated messages carrying a marker is shipped behavior.

blinry's survey shows the seat primitive exists in the protocol and the human case for it is made: pair programming without fighting over a cursor. What is missing sits in compositors and toolkits.

## What the deep-research document got right and where it overreached

Most of what I checked held up as written. Amp's Multiplayer date and behavior, Warp's session sharing, Cursor's cloud agents, Codex cloud, OpenClaw's session model, Claude Squad, Vibe Kanban's shutdown date, OpenAI's harness figures, Stack Overflow's pulse survey, DHH's January post, Maestro, Passpage, the OpenCode endpoints, both Omarchy manual pages, and blinry's survey all matched their primary pages.

Three claims do not hold up as written. Zed's Parallel Agents post (2026-04-22) describes one developer running several threads in one window; it never describes a second human joining a thread. The Windows Copilot Actions post (2025-11-17) describes a contained, auditable agent workspace and says nothing about agent accounts or identities; that concept appears in Microsoft's later agentic platform material. The claim that DHH described Herdr tracking agents across machines on the Lex Fridman episode stays unverified: the transcript exists (published 2026-08-26) but the chapter on programming setup could not be retrieved, so the claim is neither confirmed nor contradicted.

One number needs its observation time. The GitHub API reported 34,471 stars for Herdr at 20:30 PDT on 2026-09-01; a page read later the same evening showed a rounded figure. Star counts move daily, so cite the time.

## Sources

- Herdr, github.com/herdrdev/herdr and herdr.dev/docs, observed 2026-09-01
- Maestro, github.com/ivancernja/maestro, observed 2026-09-01
- omarchy-hermes-sessions, github.com/stevequinn/omarchy-hermes-sessions, observed 2026-09-01
- Claude Code sessions, Remote Control, Agent Teams: code.claude.com/docs/en/sessions, /remote-control, /agent-teams, observed 2026-09-01
- Codex cloud, learn.chatgpt.com/docs/cloud, observed 2026-09-01
- Cursor Cloud Agents, cursor.com/docs/cloud-agent, observed 2026-09-01
- Zed, "Introducing Parallel Agents in Zed", zed.dev/blog/parallel-agents, published 2026-04-22, observed 2026-09-01
- Amp, "Multiplayer", ampcode.com/news/multiplayer, published 2026-07-22; ampcode.com/docs/orbs/multiplayer, observed 2026-09-01
- Warp, Agent Session Sharing, docs.warp.dev, observed 2026-09-01
- OpenClaw, concepts/session, concepts/multi-user, concepts/session-state, docs.openclaw.ai, observed 2026-09-01
- Claude Squad, github.com/smtg-ai/claude-squad, observed 2026-09-01
- Emdash, Agent Orchestrator, Nimbalyst, CloudCLI, Agent Sessions: repository pages read in the prior-art pass, observed 2026-09-01
- Vibe Kanban, "Goodbye bloop", vibekanban.com/blog/shutdown, published 2026-04-10, observed 2026-09-01
- Microsoft, Copilot Actions and agent workspace, blogs.windows.com (2025-11-17), observed 2026-09-01
- Microsoft Research, UFO2: The Desktop AgentOS, microsoft.com/en-us/research/publication/ufo2-the-desktop-agentos (TMLR, May 2026), observed 2026-09-01
- Multi, "Multi is joining OpenAI", multi.app/blog (2024-06-24), observed 2026-09-01
- blinry, "State of multi-player Wayland", blinry.org/multi-seat-wayland, published 2026-07-28, observed 2026-09-01
- DHH, "Promoting AI agents", world.hey.com/dhh/promoting-ai-agents-3ee04945, published 2026-01-07, observed 2026-09-01
- Omarchy discussions #5433 and #8463, github.com/omacom/omarchy/discussions, observed 2026-09-01 via the GitHub API
- Hyprland issue #1731, github.com/hyprwm/Hyprland/issues/1731, observed 2026-09-01 via the GitHub API
- Lex Fridman Podcast #501 transcript, lexfridman.com/dhh-2-transcript (published 2026-08-26), partially retrieved 2026-09-01
