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
