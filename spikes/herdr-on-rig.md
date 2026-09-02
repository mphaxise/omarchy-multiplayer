# Herdr on the ARM rig

Status: hands-on, 2026-09-02, over ssh from the Mac. Environment: native aarch64 UTM VM (unofficial ggalancs image, kernel 7.2.2-2-aarch64-ARCH, Arch Linux ARM), Herdr 0.8.2-1 aarch64 from the image's package set, headless `herdr server` started from an ssh login shell. Findings carry the unofficial-port caveat.

## Verdict

Herdr is confirmed as the slice-1 runtime. The socket API lists workspaces, tabs, panes, and agents; `events.subscribe` streams to an external process; `agent.start` launched Claude Code in a pane and Herdr classified it; `pane.report_metadata` survives `server reload-config`; `worktree.create` produces a linked worktree opened as a grouped workspace; `pane.close` ends the pane's processes. A Claude Code turn with `working`, `blocked`, and `done` transitions streamed to an external subscriber once the in-VM login was done (see below).

## Facts, in the order of `setup/rig-questions.md`

2. `herdr` is `/usr/bin/herdr`, package `herdr 0.8.2-1`, architecture aarch64, installed 2026-08-29 with the image. Claude Code is `~/.local/share/mise/shims/claude` (2.1.252 after an auto-update), Codex is a mise shim too, OpenCode is `~/.local/bin/opencode`. A non-login ssh shell sees none of them; a login shell (`bash -l`) has `~/.local/share/mise/shims` and `~/.local/bin` on PATH. Python 3.14.7, jq 1.8.2, tmux 3.7c, git 2.55.0.
3. Codex CLI: present as a shim; not exercised yet.
4. The socket is `~/.config/herdr/herdr.sock` (mode 0600). `herdr status server --json` reports `protocol: 20`. `herdr api snapshot` returns `{"id": "cli:api:snapshot", "result": {"type": "session_snapshot", "snapshot": {"workspaces": [], "tabs": [], "panes": [], "agents": [], ...}}}`. Ids are `w1`, `w1:t1`, `w1:p1`; panes carry `terminal_id`, `cwd`, `foreground_cwd`, `agent_status`, `revision`; agents carry `name`, `agent`, `agent_status`, `interactive_ready`, `state_change_seq`, `terminal_title`. `herdr api schema --json` prints the full request, response, event, and subscription-event schema (91 methods); a copy is in `herdr-api-schema-0.8.2.json` beside this file.
5. `events.subscribe` works from a plain Unix-socket client: request `{"id", "method": "events.subscribe", "params": {"subscriptions": [{"type": "workspace.renamed"}, {"type": "pane.agent_status_changed", "pane_id": "w1:p1"}]}}`; first reply `{"id", "result": {"type": "subscription_started"}}`; then one line per event as `{"event": "workspace_renamed", "data": {...}}`. Subscription types are dotted; event names are underscored. `pane.agent_status_changed` and `pane.scroll_changed` require a `pane_id`; the other 25 types take none. The socket API also stayed usable across `herdr server reload-config`.
6. Status source for Claude Code is the screen manifest path: `herdr agent explain --json` lists evaluated rules (`osc_title_working` on the OSC title, `live_turn_*` on the screen region) with a `cached_remote_version` of `2026.08.31.1` for the manifests. With Claude at its first-run screens the status read `idle` with `interactive_ready: true`. Transitions to `working`, `blocked`, and `done` were observed after the login; see below.
7. `agent.rename` accepted `omarchy-session-demo`; `agent.list` reflects it immediately.
8. `pane.close` kills the pane's processes: a `sleep 600` started in the pane's shell died when the pane closed. Closing a worktree workspace's only pane removed the workspace from the list.
9. `pane.report_metadata` with `title`, `tokens` (up to 16 keys, `[A-Za-z0-9_-]{1,32}`), and `state_labels` persisted across `server reload-config` and appears in both `pane.get` and `agent.get`. The session id can ride in `tokens.session_id`. `pane.report_agent_session` exists for the harness resume id (`agent_session_id`, `agent_session_path`, `source`).
10. `worktree.create --workspace w1 --branch spike/wt-1 --base main` created `~/.herdr/worktrees/spike-repo/spike-wt-1` on branch `spike/wt-1` and opened it as workspace `w2`, labeled, grouped under the source repo; `worktree list` reports both checkouts with `is_linked_worktree`.

## The Claude Code turn, completed 19:41 guest time

After Praneet completed the sign-in inside the VM, the pane still held Claude Code's first-run screens (login confirmation, safety notes, folder trust). Herdr classified the folder-trust dialog as `blocked` through rule `live_blocked_form` and streamed `pane.agent_status_changed` with `agent_status: blocked` to the external subscriber, which is the first success signal's mechanism working end to end. Two Down and Enter key presses through `pane.send-keys` accepted the trust prompt.

With the harness at its prompt, `herdr agent prompt --wait` on "Reply with exactly the word ready" produced `working` within the same second and `done` two seconds later, both as streamed events and as the CLI's wait result (`state_change_seq` 7). A second prompt that runs `ls -la` produced `working` then `done` five seconds later with the answer in the pane; no `blocked` state appeared because Claude Code started in its auto permission mode, which is the Personal-mode behavior `04-permission-modes.md` describes. Herdr reports `done` after a completed turn while the pane stays alive, matching the session model's mapping of Herdr `done` to Omarchy `idle`.

Two observations for the build. Herdr's `agent_session` field stayed `null` for Claude Code, so the harness resume id has to come from `pane.report_agent_session` or from Claude's own session files until the Herdr integration for Claude is installed (`herdr integration install claude`, untested). And `~/.claude/settings.json` on this image carries only theme and notification flags, so the auto mode came from the harness's own default, which the permission-mode launcher must override explicitly in Shared and Restricted.

The spike's decision rule is met in full: panes listed, `pane.agent_status_changed` streamed for a Claude Code pane, and a Claude Code session hosted end to end.

## Rig notes for Omarchy-UX

- A custom `omarchy-arm-vdagent.service` (SPICE clipboard over Wayland, Spanish unit description) fails repeatedly at boot, so host-guest clipboard sharing does not work on this image. Candidate report to ggalancs/omarchy-arm-utm.
- The guest clock reads about nine hours ahead of the Mac's local time; the image's timezone is inherited from the author. Worth setting before captures carry timestamps.
- Docker is active with no containers.
- After a power-cut stop and reboot, the live qcow2 churned several gigabytes on the host within twenty minutes; with an APFS-cloned snapshot beside it, that churn costs host disk. Keep more than 10 GiB free on the Mac while the VM runs.
