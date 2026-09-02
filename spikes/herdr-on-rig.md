# Herdr on the ARM rig

Status: hands-on, 2026-09-02, over ssh from the Mac. Environment: native aarch64 UTM VM (unofficial ggalancs image, kernel 7.2.2-2-aarch64-ARCH, Arch Linux ARM), Herdr 0.8.2-1 aarch64 from the image's package set, headless `herdr server` started from an ssh login shell. Findings carry the unofficial-port caveat.

## Verdict

Herdr is confirmed as the slice-1 runtime. The socket API lists workspaces, tabs, panes, and agents; `events.subscribe` streams to an external process; `agent.start` launched Claude Code in a pane and Herdr classified it; `pane.report_metadata` survives `server reload-config`; `worktree.create` produces a linked worktree opened as a grouped workspace; `pane.close` ends the pane's processes. One item stays open: a Claude Code turn with status transitions, because the harness asked for a fresh login inside the headless pane (see below).

## Facts, in the order of `setup/rig-questions.md`

2. `herdr` is `/usr/bin/herdr`, package `herdr 0.8.2-1`, architecture aarch64, installed 2026-08-29 with the image. Claude Code is `~/.local/share/mise/shims/claude` (2.1.252 after an auto-update), Codex is a mise shim too, OpenCode is `~/.local/bin/opencode`. A non-login ssh shell sees none of them; a login shell (`bash -l`) has `~/.local/share/mise/shims` and `~/.local/bin` on PATH. Python 3.14.7, jq 1.8.2, tmux 3.7c, git 2.55.0.
3. Codex CLI: present as a shim; not exercised yet.
4. The socket is `~/.config/herdr/herdr.sock` (mode 0600). `herdr status server --json` reports `protocol: 20`. `herdr api snapshot` returns `{"id": "cli:api:snapshot", "result": {"type": "session_snapshot", "snapshot": {"workspaces": [], "tabs": [], "panes": [], "agents": [], ...}}}`. Ids are `w1`, `w1:t1`, `w1:p1`; panes carry `terminal_id`, `cwd`, `foreground_cwd`, `agent_status`, `revision`; agents carry `name`, `agent`, `agent_status`, `interactive_ready`, `state_change_seq`, `terminal_title`. `herdr api schema --json` prints the full request, response, event, and subscription-event schema (91 methods); a copy is in `herdr-api-schema-0.8.2.json` beside this file.
5. `events.subscribe` works from a plain Unix-socket client: request `{"id", "method": "events.subscribe", "params": {"subscriptions": [{"type": "workspace.renamed"}, {"type": "pane.agent_status_changed", "pane_id": "w1:p1"}]}}`; first reply `{"id", "result": {"type": "subscription_started"}}`; then one line per event as `{"event": "workspace_renamed", "data": {...}}`. Subscription types are dotted; event names are underscored. `pane.agent_status_changed` and `pane.scroll_changed` require a `pane_id`; the other 25 types take none. The socket API also stayed usable across `herdr server reload-config`.
6. Status source for Claude Code is the screen manifest path: `herdr agent explain --json` lists evaluated rules (`osc_title_working` on the OSC title, `live_turn_*` on the screen region) with a `cached_remote_version` of `2026.08.31.1` for the manifests. With Claude at its first-run screens the status read `idle` with `interactive_ready: true`. Transitions to `working` and `blocked` are untested until the login below completes.
7. `agent.rename` accepted `omarchy-session-demo`; `agent.list` reflects it immediately.
8. `pane.close` kills the pane's processes: a `sleep 600` started in the pane's shell died when the pane closed. Closing a worktree workspace's only pane removed the workspace from the list.
9. `pane.report_metadata` with `title`, `tokens` (up to 16 keys, `[A-Za-z0-9_-]{1,32}`), and `state_labels` persisted across `server reload-config` and appears in both `pane.get` and `agent.get`. The session id can ride in `tokens.session_id`. `pane.report_agent_session` exists for the harness resume id (`agent_session_id`, `agent_session_path`, `source`).
10. `worktree.create --workspace w1 --branch spike/wt-1 --base main` created `~/.herdr/worktrees/spike-repo/spike-wt-1` on branch `spike/wt-1` and opened it as workspace `w2`, labeled, grouped under the source repo; `worktree list` reports both checkouts with `is_linked_worktree`.

## The open item

`herdr agent start spike-claude --kind claude --pane w1:p1` launched Claude Code, which showed its theme picker and then a login menu, despite a credentials file under `~/.claude/`. The pane runs under a server started from ssh, with no graphical session, so the harness's stored login was not accepted or was reset by the 2.1.252 update. The pane is left at the login menu in workspace `spike`; opening Herdr in the VM (Super+Ctrl+Return) shows it, and completing the login there unblocks the status-transition test. That login is Praneet's action.

## Rig notes for Omarchy-UX

- A custom `omarchy-arm-vdagent.service` (SPICE clipboard over Wayland, Spanish unit description) fails repeatedly at boot, so host-guest clipboard sharing does not work on this image. Candidate report to ggalancs/omarchy-arm-utm.
- The guest clock reads about nine hours ahead of the Mac's local time; the image's timezone is inherited from the author. Worth setting before captures carry timestamps.
- Docker is active with no containers.
- After a power-cut stop and reboot, the live qcow2 churned several gigabytes on the host within twenty minutes; with an APFS-cloned snapshot beside it, that churn costs host disk. Keep more than 10 GiB free on the Mac while the VM runs.
