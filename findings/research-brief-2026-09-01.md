# Research brief: what the evidence says before I build

Status: findings, 2026-09-01. This brief closes the research phase and records the decisions it forced. Detail lives in `prior-art.md`, `cscw-insights.md`, `product-people-landscape.md`, and `patterns/`.

## Bottom line

Omarchy already ships the durable agent runtime this experiment was going to build. Herdr, packaged in Omarchy quattro and bound to Super+Ctrl+Return, keeps agent processes alive when the window closes, detects whether an agent is working, blocked, idle, or done, exposes a socket API to list and watch panes, and manages git worktrees. OpenClaw 2.0 supplies the model Herdr lacks: a session with an immutable creator, an assignable owner, a participant history, a typed event log with a state version, spawn receipts, marked inter-agent messages, and an honest trust boundary. The experiment builds that model on top of Herdr as Omarchy-native scripts and a shell plugin, and measures it with the five success signals in `PLAN.md`.

The constituent ideas are shipped elsewhere; the synthesis on a Linux desktop is unclaimed. Two Omarchy discussions asked for pieces of it and drew zero comments. The differentiator for product people who design and build is the loop record: intent, evidence, approval, and receipt kept together where the running product is.

## What changed since the morning plan

The morning plan named tmux or abduco as the fallback runtime and OpenClaw as the engine candidate. Both are superseded. Herdr is the runtime; OpenClaw is the pattern source, and its spike moves to the slice 2 gate, where multi-user needs a gateway.

The morning plan called the upstream white space clean. It is clean of issues and dirty with discussions: #5433 (2026-04-24) asks for human and agent as separate compositor seats; #8463 (2026-08-26) asks for a headless agent API for plugins. Neither has a reply. Hyprland closed multi-seat as not planned (2025-04-05), which places desktop-seat multiplayer upstream and out of scope; session-level multiplayer needs no compositor change.

Community prior art on Omarchy exists: Maestro (parallel agent CLIs in detached tmux sessions and worktrees, wired to Omarchy's theme, notifications, and default agent), omarchy-hermes-sessions (a bar widget listing Hermes sessions), and the Passpage plugin (agent-published pages in the bar). None carries identity, lineage, receipts, or a session that outlives its runtime alias.

The audience widened. The plan now names AI-native product people and adds a slice-1 layer of closed-loop surfaces: a goal record, a registered preview, captures with before and after labels, and a loop view in the receipt. The essay this rests on is borne out where it claims a shared running canvas and a design system as action vocabulary, and ahead of the evidence where it claims a designer without code driving the loop and a durable approval history; the experiment tests both.

## Verified facts that carry the design

Omarchy quattro, read from the repository: `bin/omarchy-agent` launches nine of eleven harnesses with no-prompt flags; `omarchy-launch-tui` keeps nothing alive after the window closes; the crash watcher is a systemd user unit that hands a coredump to the default agent through `omarchy-notification-send --exec`; shell plugins run unsandboxed inside the single `omarchy-shell` process with a manifest, hot reload, and `FileView` or `Process` for data; the menu takes user extensions from a JSONC file; Herdr ships with a tmux-mirroring config and four layout functions.

Herdr v0.8.2: server plus clients; named sessions with sockets under `~/.config/herdr/`; workspaces, tabs, panes; `agent start`; status from lifecycle hooks for six harnesses and screen manifests for the rest; `events.subscribe`, `agent.wait`, `notification.show`, `agent.view.set`; worktrees under `~/.herdr/worktrees`; `--remote` over SSH; per-client views and delegation are open discussions, with the maintainer saying per-client views ship in the next one or two updates.

OpenClaw 2.0 (v2026.8.1, 2026-08-31): every pattern in the ChatGPT brief is confirmed from the docs except two details: there is no documented way to edit or reorder a queued message, and "suggest this task" versus "start this task" exists only as tool names. A2A support is real and framed as a channel. The trust boundary is stated in the security docs. Node 22.22.3 or newer; no Arch documentation; AUR pages were unreadable.

Prior art: Amp's Multiplayer (2026-07-22) is workspace-wide and time-boxed with no roles; Warp separates watching from driving with per-viewer cursors; Cursor gates teammate follow-ups behind an admin setting; Codex cloud lists Creator and Sharing as columns; Claude Code's Agent Teams marks inter-agent messages as data; Zed's Parallel Agents post describes one developer; Vibe Kanban's hosted multi-user layer died with the company while local worktrees kept working; no Linux desktop has a first-party agent identity or session feature; Windows has a contained agent workspace.

CSCW: thirty-seven works verified against bibliographic records; five bind the design (awareness elements, interruption cost, calibrated trust, boundary objects, the social-technical gap) and eight principles follow, listed in `cscw-insights.md`.

Product people: Anthropic's analysis of about 400,000 Claude Code sessions finds people make about 70% of planning decisions and about 20% of execution decisions; OpenAI's harness team shipped without hand-written code; Stack Overflow's April 2026 pulse finds 63% of developers rarely or never let agents run unsupervised.

## Claims I could not verify and keep out

Figma's 2026 AI report percentages (page unreadable by my tools). DHH describing Herdr across machines on the Lex Fridman episode (transcript chapter unreachable). A Quickshell "Agents panel" with activity tabs (Omarchy has a usage panel; the activity part is this experiment). The ChatGPT brief's claim that Windows agent workspace includes agent accounts (that post has none). Any Herdr behavior on aarch64 Arch, which only the rig can answer.

## Decisions taken tonight

1. Runtime: Herdr, through its socket API. Fallback if Herdr is absent or broken on the ARM image: the x86-64 rig, then plain `git worktree` plus tmux with reduced status detection, recorded as a degraded mode.
2. OpenClaw: pattern source for slice 1; install spike deferred to the slice 2 gate.
3. Session identity lives in Omarchy state (`~/.local/state/omarchy/sessions/`), and Herdr's transient agent alias mirrors the session name.
4. The slice-1 spec set is written as proposed and revised after the first rig session; nothing in it is live.
5. The audience is product people who design and build; closed-loop surfaces enter slice 1 in a light form.

## Parked for Praneet

Push the local commits to GitHub. Enable sshd in the VM and send the guest IP. Confirm or edit the open decisions in `PLAN.md`. Approve the plugin's release id before any release. Choose whether the Figma report figures are worth reading on a browser and adding.

## Method

Seven read-only research passes and eight drafting passes ran in parallel between 20:00 and 23:30 PDT on 2026-09-01, each restricted to primary sources and told to mark what it could not verify. I spot-checked the load-bearing claims through the GitHub API and direct page reads: Herdr in the Omarchy package list and keybindings, the four Omarchy and three Herdr discussions, PR #6231, Hyprland #1731, Maestro and Passpage, the Anthropic study. Every file carries its sources and observed dates.
