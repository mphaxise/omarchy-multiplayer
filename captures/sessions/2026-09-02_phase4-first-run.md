# Session note: Phase 4, first run of the slice on the rig

- Date: 2026-09-02, 11:50 to 12:04 PDT guest time
- Provenance: hands-on, driven over ssh; the rig as in the baseline note
- State label: `live` for everything below; the build ran on Omarchy

## What ran

`omarchy-agent-session-new --agent claude --name readme-note-3 --base main` created the record, a git worktree at `~/.herdr/worktrees/readme-note-3` on `session/readme-note-3`, and a Herdr workspace whose root pane hosts Claude Code, in about one second. `send --wait` delivered "append a line to README.md and commit" and returned after 14 s with the status `idle`; Claude had committed `0ffb084 session note`. `stop` closed the pane and wrote the receipt: 1 commit, 1 file changed, dirty false, unpushed true, worktree kept.

A second session in `shared` mode launched Claude with `--permission-mode default` (the pane shows "manual mode on"). An instruction to create a file made Claude ask "Do you want to create note.txt?"; Herdr classified the pane `blocked`, the watcher's reconcile wrote `status.changed` to `blocked`, and the notification "approval-test needs approval" appeared top-right within seven seconds (`signal4-blocked-notification_…_live.jpg`). Enter in the pane approved it; the session went `idle`; `stop` wrote its receipt.

`reconcile` also adopted the Herdr agent left over from the baseline (`baseline-claude`) as a system-created session, so agents started outside the launcher appear in the list.

## Signals touched

- Signal 2 (survives window close): held by Herdr, confirmed in the baseline; the launcher path now creates through Herdr, so a session never depends on a terminal window.
- Signal 3 (receipt): met for a worktree session with a commit.
- Signal 4 (notifications, no polling by the user): met for `blocked`; the watcher polls Herdr through `reconcile` every five seconds and on Herdr nudges, so the user polls nothing.
- Signal 5 (no bypass outside Personal): the shared launch carried `--permission-mode default`; the deny-list check ran.
- Signal 1 (panel, five seconds): the plugin is next.

## Fixes the rig forced

String request ids; `workspace.create` before `agent.start`; agent list and get result shapes; the worktree's Herdr workspace reused for the agent pane instead of a second workspace; a retry while a new pane reaches its shell prompt; a socket timeout matched to a waited prompt; `agent.wait` before a prompt to a fresh harness; Herdr status mapped into the record on reconcile and after a waited send; receipts written on stop; `--base` and `--pick`.

## Open

- The notification carries a title only; the crash toast has an icon and a second line. Add the harness's question as the body and an icon.
- `agent_session` from Herdr stays null for Claude; the harness resume id needs `pane.report_agent_session` or Claude's session files.
- Every Claude launch still raises the locked-keyring modal on this image.

## Addendum, 12:05 to 12:14: the panel is live

The `praneet.agent-sessions` plugin installed as a copy under `~/.config/omarchy/plugins/`, passed the shell's rescan without a QML error, and took its place in the bar's right section next to the usage widget (`omarchy plugin enable`, `omarchy bar put`). With two idle sessions the glyph sat muted. A shared-mode session asked to create a file went `blocked`; within eight seconds the glyph turned urgent with a badge of 1, and the panel opened over IPC showed the hero "needs-you · BLOCKED · 0M" and the Needs you section leading with that row, Send, Stop, and Receipt buttons under it, the two idle sessions under Working, and the day's stopped sessions under Done today (`signal1-…_live.jpg`, three frames). Signal 1's mechanism is live; the five-second measurement itself waits for the evaluation pass.

One rig note: enabling a plugin makes the shell reload its whole scene, and during the reload the bar and the wallpaper vanish for a moment; my first screenshot caught that plus the idle screensaver, which I misread as a crash. The shell log shows no error from the plugin.

## Addendum, 12:30 to 13:07: reboot, keyboard, resume, launchers

Praneet restarted the VM. The Herdr server was gone, the panel showed a stale `idle` row, and Enter did nothing. Fixes: a user unit keeps the Herdr server up (`systemd/omarchy-agent-session-herdr.service`), the reconciler orphans bound sessions when Herdr is unreachable, and `open` on an orphaned session re-binds, restarts the harness, and attaches a terminal in one step.

Praneet reported arrows and Enter dead in the panel while clicks worked. Esc closed the panel, so focus was fine; the cursor started hidden and the one row had nowhere to move, and Enter opened the session behind an overlay that stayed up. Now the cursor shows from the first frame, Enter closes the panel after opening, and `x` (routed by the shell's key catcher to its own signal) arms and executes Stop.

Resume: the core now reads Claude Code's transcript directory for the harness's session id after the first turn and records it as `harness_session_ref`. Test: a session was told the code word PELICAN, its pane was closed behind its back, the reconciler orphaned it within seven seconds, `open` relaunched Claude with `--resume`, and the revived session answered PELICAN.

Launchers: the proposed `omarchy-agent`, `omarchy-agent-prompt`, and `omarchy-agent-crash` are installed under `~/.local/bin` on the rig, the Super+Shift+Ctrl+A binding is overridden in the user bindings file to call them, and the crash watcher's unit carries a drop-in that prefers `~/.local/bin`. The keybinding path created a session and attached its terminal on the active workspace. The crash path first failed because Herdr refuses argv it cannot encode for the shell (the multi-line crash prompt); prompts now travel through `agent.prompt` after the harness is ready (`new --prompt`), and the crash session started diagnosing with its terminal attached.

Notifications carry a body line and the robot glyph, and their click runs `omarchy-agent-session-open` (the earlier click target was the usage-only group script).
