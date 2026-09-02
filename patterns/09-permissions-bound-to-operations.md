---
pattern: Permissions bound to operations
source: https://docs.openclaw.ai/gateway/permission-modes.md, https://docs.openclaw.ai/tools/exec-approvals.md, https://docs.openclaw.ai/tools/exec.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: launcher
slice: 1
---

# Permissions bound to operations

## What OpenClaw does

Permission binds to the session, not to the agent or the human driving it. Four modes, read-only, guarded, workspace, and full, each pair a filesystem boundary, reads and writes confined to the session's recorded root, with an exec escalation reviewer: read-only denies exec outright, guarded asks a human after a fast allowlist check, workspace routes to an LLM reviewer with human fallback, and full asks no one. Full specifically requires `operator.admin`; the other three only need `operator.write`, a deliberately higher bar for the one mode that removes the boundary. Exec approvals stack a second layer on top: `tools.exec.mode` can only tighten a stricter session mode, never loosen it, documented as the stricter of the two always winning. An approved command binds a canonical plan at approval time, exact argv, working directory, and one concrete file when identifiable, and a later attempt that drifted from that plan even slightly is denied instead of silently re-approved. Standing "allow always" grants bind to the exact argv and the working directory where they were approved, so the same command elsewhere is a fresh miss, and every grant is visible and revocable from one ledger instead of a silent blanket trust.

## What Omarchy has today

The opposite default. Nine of eleven `omarchy-agent` launch paths start in a no-prompt mode by construction, `claude --permission-mode auto`, `codex --approve-for-me`, `grok --permission-mode bypassPermissions`, and more, decided once at launch by which binary was picked, with no distinction between a read and a destructive exec, and no way to tighten mid-session.

## What porting it means

Invariant 5 in the session model, a session in shared or restricted mode is never bound to a harness launched with a bypass-permissions flag, is the direct port of full requiring `operator.admin`: the `mode` field on `session.json` already exists to gate which of those nine flags may be used, and success signal 5 in `PLAN.md` measures exactly this. The finer four-mode split is bigger than slice 1 needs, since none of the eleven harnesses expose a filesystem boundary Omarchy could enforce externally, but the underlying idea, permission as a property of the session checked at every operation, not a flag baked into the launch command, is what `mode` already is. Canonical-plan binding has no home yet without an approvals layer of Omarchy's own, but it is the right target once `restricted` mode needs to ask about anything more specific than whether bypass is allowed at all.

## Open questions

- Does `restricted` mode need its own allowlist before it is useful, or is "not personal, so no bypass flag" enough for a first cut?
- Can `mode` change mid-session, or does changing a launch flag require stop and restart?
- Should `receipt.json` record which mode a session ran under, even before `approvals` is populated?

## Sources

- Session permission modes, https://docs.openclaw.ai/gateway/permission-modes.md, observed 2026-09-01
- Exec approvals, https://docs.openclaw.ai/tools/exec-approvals.md, observed 2026-09-01
- Exec tool, https://docs.openclaw.ai/tools/exec.md, observed 2026-09-01
