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

## Addendum, 13:20 to 14:25: two closed-loop iterations and the review pass

Iteration 1, from my own report at the keyboard: confirming Stop changed nothing on screen until the next poll. The row now shows a spinner and "stopping" in the urgent color, Send and Stop stand down, and the panel polls every second until the record reports stopped (commit 3d5a06d).

Iteration 2, from the review pass (`findings/evaluation-slice1-2026-09-02.md`): a fresh capture of the panel with every session stopped showed no keyboard cursor on any row, every state label clipped ("stopped ·"), and caption text at 3.60:1. `Session.qml` had redeclared `hasCursor`, `foreground`, and `accent`, shadowing the shell's `CursorSurface` properties, so the cursor was never painted, this morning's "cursor visible from open" fix included. Fixed with the label width, a shared duration formatter with a fresh clock per snapshot, and `dim` at `Qt.darker(foreground, 1.3)` (commit 382c785). Before and after: `sessions-panel-done-today-before-fixes_…_live.jpg`, `sessions-panel-done-today-after-fixes_…_live.jpg`.

Rig fact: the shell's hot reload after a plugin file change left the live widget on old code twice (an IPC `refresh` answered from the old code after each `Local plugin changed, reloading` cycle, and from the new code only after `omarchy-restart-shell`). Every panel change since the 12:36 reboot reached the screen for the first time at 14:18. Enter closing the panel, `x` arming and executing Stop, and the stop spinner are therefore unverified by a person until the next keyboard session; the cursor paint is verified by capture.

Also confirmed on the rig: `Style.space(px)` is px times the spacing scale, so the spec's `Style.space(4)` floor is 4 px; the shell's section headers and hero meta use `Qt.darker(foreground, 1.4)` (4.28:1); `omarchy-notification-send` takes `-t <ms>` and `-r <id>`; a written receipt carries `end_state`, `end_reason`, `started_with.command`, and `harness_session_ref`. No panel keybinding exists yet; the shell's pattern is `omarchy-shell shell toggle <plugin>`.

## Addendum, 14:35 to 15:15: Option B on the rig

Decisions from the review (P1 blocks; Option B; stop-ship until the glyph and dots pass 3:1) became commits bad8373 (core and watcher) and cbac0e9 (panel), deployed with `omarchy-restart-shell` and verified with a scenario: a shared-mode session told to create `hello.txt` blocked on the write, one personal session went idle, one had its harness killed, one had its whole pane killed, and then the Herdr server was stopped and started again. Captures: `sessions-panel-needs-you-goal-mode`, `sessions-panel-orphaned-disclosed`, `sessions-panel-herdr-down`, `sessions-panel-calm-collapsed-done`, and `signal4-orphaned-notification-revive-copy`, all `_hands-on_arm-port_2026-09-02_live`.

What the scenario showed beyond the build: the blocked session's toast was recorded in the shell's notification history at 21:59:01.58Z against a `status.changed` event at 21:59:01Z, so signal 4's notification came through the Herdr nudge, under a second, with the five-second sweep as the fallback; a normal-urgency toast leaves the screen within a few seconds while the badge stays; killing only the harness left the pane alive and the session `idle` forever, which the reconciler now ends as `done` with a receipt; the default names came out as `create-a-file-named` and `reply-with-the-single-2` from the prompts.

Rig wiring: `Super+Ctrl+G` toggles the panel and `Super+Ctrl+Shift+G` opens the agent that needs you, both in `~/.config/hypr/bindings.lua` and marked provisional; the watch unit was restarted for the new copy; `~/Work/omarchy-multiplayer/bin` and `tests` match the repo (102 tests green on the rig). One incident: the last `omarchy-restart-shell` reported "did not become ready" and left no shell running under a load average of 3; `hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")'` brought it back in about thirty seconds. The script's readiness window is two seconds; on this VM that is short.

Test sessions were stopped afterwards; `hello.txt` was never written. Remaining for a person: the keyboard path on the restarted shell (arrows, Enter, `s`, `x`, Esc, the inline results, the spinner), and the five-second trials.

## Addendum, evening: runs 1 and 2, and the keyboard

Two scenario runs over ssh (`findings/evaluation-run1-2026-09-02.md`, `findings/evaluation-run2-2026-09-02.md`) and, at about 19:50, a quick keyboard test by me at the rig: the panel's keys work on the restarted shell. Which keys I pressed is not recorded; the stopwatch trials and a full pass over Enter, `s`, `x`, Esc, the inline results, and the spinner are still owed.

## Addendum, 20:30: the package update

Praneet ran `omarchy-update` at 20:22 and rebooted. Nine Arch packages updated, Claude Code among them through the mise shim (2.1.252 to 2.1.259). Omarchy itself stayed at `0b3f1b7`: `/usr/share/omarchy` is a root-owned git checkout that no package owns (`pacman -Qo` finds no owner), and `omarchy-update-dev` exits without pulling when the path is `/usr/share/omarchy`; the port's `omarchy` 4.0.1-2 package sits uninstalled in the `omarchy-aarch64` repo. No migration ran, so the sshd hardening did not either. After the reboot: ssh with our key works, Herdr and the watcher are up, 109 tests pass on the rig, and the panel opened over IPC with the day's thirty sessions under Done today (`post-update-panel`, not kept). The stopwatch trials are withdrawn by Praneet's decision; `decisions.md` has the reason.
