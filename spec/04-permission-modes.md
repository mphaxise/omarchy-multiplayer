# Permission modes

Status: proposed, 2026-09-01. Slice 1.

## The three modes

A session's mode sets how much a harness may do before a human sees it. It is a property of the session record in `01-session-model.md`, not a preference of the harness.

**Personal** means the launcher is at the keyboard and no one else is attached. Today's Omarchy no-prompt launch flags are allowed here, and only here: a session uses them only when its mode is Personal. Personal is what a keybinding launch gets by default, matching today's behavior, because the one person who could be asked is already watching.

**Shared** means someone other than the launcher may steer or watch: a teammate, a gateway user, or a parent agent. Every write outside the worktree and every command execution asks. No bypass flag is ever used, whatever the harness supports.

**Restricted** means read and plan only. No writes, and no command beyond read-only inspection. A restricted session runs unattended with nobody watching. Its safety comes from what it cannot do.

## Harness launch flags

| Harness | Personal | Shared | Restricted | Verified against |
|---|---|---|---|---|
| claude | `--permission-mode auto` | `--permission-mode default` | `--restricted --tools Read,Grep,Glob` | code.claude.com/docs/en/permission-modes |
| codex | `--approve-for-me` (verify on rig) | `--sandbox workspace-write --ask-for-approval untrusted` | `--sandbox read-only --ask-for-approval never` | developers.openai.com/codex/cli/reference |
| opencode | `--auto` | `OPENCODE_PERMISSION='{"permission":"ask"}'` | `OPENCODE_PERMISSION='{"permission":{"*":"deny","read":"allow","glob":"allow","grep":"allow"}}'` | opencode.ai/docs/permissions |
| copilot | `--allow-all` | (default, no flag) | `--available-tools=view,grep,glob` | docs.github.com/.../allowing-tools |
| crush | `--yolo` | (default, no flag) | `.crush.json`, see note | charmbracelet-crush.mintlify.app/configuration/permissions |
| grok | `--permission-mode bypassPermissions` | `--permission-mode default` | `--allow 'Read' --allow 'Grep' --deny 'Bash' --deny 'Edit'`, see note | github.com/xai-org/grok-build/.../22-permissions-and-safety.md |
| hermes | `--yolo` | no match, refuse | no match, refuse | hermes-agent.nousresearch.com/docs/user-guide/security |
| agy | `--dangerously-skip-permissions` | (default, no flag) | `--mode=plan`, see note | antigravity.google/docs/cli/modes |
| omp | `--auto-approve` (verify on rig) | (default, no flag, verify on rig) | verify on rig | github.com/awslabs/cli-agent-orchestrator/.../omp-cli.md, omp.sh |
| pi | (none needed) | no match, refuse | no match, refuse | github.com/badlogic/pi-mono |
| ori | inherits wrapped harness | inherits wrapped harness | inherits wrapped harness | omarchy.org/manual/ai |

"Default, no flag" rows already ask before every tool call with nothing added, so Shared just omits the Personal column's flags. "No match, refuse" rows have no config that satisfies the mode's contract, so the launcher refuses that mode and records `status.detail` naming the harness.

Six rows need a sentence more. Codex's Personal flag is what `bin/omarchy-agent` runs today, `--approve-for-me`, absent from the current CLI reference; the documented no-prompt paths are `--ask-for-approval never` and `--dangerously-bypass-approvals-and-sandbox` (`--yolo`), so treat Omarchy's flag as aged. Crush's restricted cell is a config file the launcher writes before exec, not a flag: `disabled_tools` set to `bash, edit, multiedit, write, download, job_output, job_kill`; delivering that file without touching the working tree is verify on rig. Grok's strictest policy, `dontAsk`, cannot be set by `--permission-mode` at all, only by `defaultMode` in a settings file it reads at startup, so the launcher writes that file alongside the flags shown. Hermes gates only a curated dangerous-command list, with no mode that asks before every action and none that is read-only, so both refuse. agy's `--mode=plan` stops file writes but shell commands go through a separate `/permissions` gate in every mode, so restricted also needs a read-only `/permissions` rule. OMP's Personal flag comes from a third party's integration notes, not OMP's own reference, and its restricted tool filter is unconfirmed.

pi ships no permission gate at all, so nothing stops it once started; Shared and Restricted both refuse instead of pretending a boundary exists. ori is a pass-through: `ori claude`, `ori codex`, and `ori opencode` inherit that harness's row. Its own native agent, bare `ori`, has no confirmed flag in any mode; treat it like pi until the rig says otherwise.

## Choosing and changing mode

`session new` accepts `--mode personal|shared|restricted`. Left unset, the default is `personal` for a keybinding launch, matching `omarchy-agent` today. The default flips to `shared` the moment `--from <session>` is set: an agent spawning a child session never gets Personal by omission, only a human asking for it by name gets that.

`session mode <id> <mode>` changes a running session. It stops the harness process, relaunches it with the new mode's flags from the table above, and passes `harness_session_ref` to the harness's own resume mechanism so the conversation carries over. It appends a `mode.changed` event (`from`, `to`, `changed_by`) to `events.jsonl`, extending the event list in `01-session-model.md`.

## The deny-list invariant

Invariant 5 in `01-session-model.md` states it plainly: a session in `shared` or `restricted` mode is never bound to a harness launched with a bypass-permissions flag. The launcher enforces this before it execs anything. It assembles the full argv, plus any config file or environment variable it is about to write, and checks it against a per-harness deny-list: every flag in the Personal column above, plus combinations that only look safe alone, such as Codex's `--ask-for-approval never` without `--sandbox read-only`. A `shared` or `restricted` launch that matches the deny-list never runs; it fails at `session new` with a named reason, or falls back per the table notes for a harness with no safe expression of the mode at all.

## What OpenClaw contributed, and where this differs

OpenClaw's four gateway modes, read-only, guarded, workspace, full, are one axis of capability, enforced centrally because OpenClaw mediates every tool call itself regardless of which CLI sits behind it. Restricted borrows the read-only end of that axis and Personal borrows the full end. Shared collapses OpenClaw's middle two into a single rule, always ask, because slice 1 has no mediating gateway between the harness and the machine: Omarchy execs it directly, so a mode is only as fine-grained as the flags and config keys that harness exposes. That is why the table varies so much row to row, and why some rows refuse instead of degrading gracefully.

## Approvals and the event log

A harness's own approval prompt is not an `approval.requested` event by itself. Slice 1 writes that event, and its matching `approval.resolved`, only for harnesses whose hooks or status channel expose the operation being approved. For every other harness, the session record shows only what Herdr detects from the screen: a `status.changed` event into `blocked`, with no operation, no requester, and no decision attached. A ledger that captures every approval, on every harness, in enough detail to replay the decision, is slice 2 work.

## Trust

Trust here is a property of the session, not the harness. Personal trusts the person at the keyboard to interrupt a runaway action in real time, so it trades oversight for speed. Shared trusts no single party with unwitnessed authority, so every write and command earns a named approval before it happens, because more than one person's work is now on the line. Restricted trusts no one to be watching at all, so it removes the capability to do harm instead of asking permission to use it. A session's mode is set once at creation from who is present and why, and changing it later is a visible, logged act, never a silent default.

## Verify on rig

- Codex's `--approve-for-me` flag against the installed CLI version; compare with `--ask-for-approval` and `--dangerously-bypass-approvals-and-sandbox`.
- Crush's mechanism for delivering `disabled_tools` at launch without writing into the project's own `.crush.json`.
- Grok's `defaultMode: "dontAsk"` settings file actually taking effect when paired with the `--allow`/`--deny` flags shown.
- agy's shell-command behavior under `--mode=plan` with and without a `/permissions` read-only rule.
- OMP's `--auto-approve` and `--approval-mode` exact syntax, and whether `--tools` can express a read-only filter.
- Whether Hermes or pi have gained a stricter mode since these docs were read.
- ori's own native agent's behavior when not wrapping another harness.
- Whether the rig's Omarchy build ships Hermes at all: the public manual lists ten harnesses without it, so the eleventh may be quattro-branch-only.

## Sources

All observed 2026-09-01. Claude Code: code.claude.com/docs/en/cli-reference, /permission-modes. Codex: developers.openai.com/codex/cli/reference, /codex/permissions. OpenCode: opencode.ai/docs/permissions, /docs/cli. GitHub Copilot CLI: docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/allowing-tools. Crush: charmbracelet-crush.mintlify.app/configuration/permissions. Grok Build: github.com/xai-org/grok-build, crates/codegen/xai-grok-pager/docs/user-guide/22-permissions-and-safety.md. Hermes Agent: hermes-agent.nousresearch.com/docs/user-guide/security. Google Antigravity CLI: antigravity.google/docs/cli/modes, /cli/using. AWS Labs CLI Agent Orchestrator: github.com/awslabs/cli-agent-orchestrator, docs/omp-cli.md; also omp.sh/docs. Pi: github.com/badlogic/pi-mono. Omarchy manual: omarchy.org/manual/ai. Omarchy `bin/omarchy-agent` on branch quattro, plus Herdr and OpenClaw documentation, as read into the context pack.
