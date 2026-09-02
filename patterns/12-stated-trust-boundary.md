---
pattern: Stated trust boundary
source: https://docs.openclaw.ai/gateway/security.md, https://docs.openclaw.ai/concepts/multi-user.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: none yet
slice: 1
---

# Stated trust boundary

## What OpenClaw does

The docs state the boundary as a design axiom: one trust boundary per gateway, a single operator or a team whose members already trust each other, explicitly not a hostile multi-tenant boundary for adversarial users sharing one agent. Everyone who can message a tool-enabled agent shares that agent's full delegated authority; there is no per-user tenant isolation inside one gateway, only collaboration guardrails for teammates who already trust each other. The corollary is operational, not just philosophical: for mixed-trust or adversarial use, split trust boundaries entirely, separate gateway, separate credentials, ideally separate OS users or hosts. A companion rule closes the obvious gap: a session key or label is named directly as a routing selector, never an authorization token. The whole page reduces to one line: anyone who can modify the gateway's own host state or config is, by that fact alone, a trusted operator.

## What Omarchy has today

An unstated but correct boundary. One Linux desktop, one OS user, one set of file permissions, is already one trust boundary in OpenClaw's sense, since anyone who can run a command as that user already has full authority over every session and credential on the box. Nothing in `spec/01-session-model.md` says this out loud, and nothing distinguishes a session id as a routing key from a session id as access control the way OpenClaw's docs do explicitly.

## What porting it means

For slice 1 this costs nothing in code and everything in saying it plainly: one machine, one OS user, is one trust boundary, the same way OpenClaw states it for one gateway, and the moment Omarchy's roadmap reaches a second human on the same box or a remote viewer, that person needs their own OS account or their own host, not a permission flag layered on top of the first user's session store. The concrete artifact worth adding now, while it costs nothing: a line in the invariants list stating that `id` is a routing key, never an authorization token, so nobody later builds an access shortcut around guessing a ULID. `mode: personal/shared/restricted` already assumes a single trust domain; this pattern is the reason that assumption is allowed to stand through slice 1 to 3, and the reason it must be revisited, not quietly extended, once a second OS user or host enters the picture.

## Open questions

- Does the sessions directory need its own permission audit before slice 1 ships, or is inheriting the OS user's normal home-directory permissions enough?
- When a second human arrives, does Omarchy split trust the OpenClaw way, separate OS users per person, or does a desktop need its own model?
- Should the panel ever display a session id in a way that implies it is private, given the explicit warning against treating a session key as an auth token?

## Sources

- Security, https://docs.openclaw.ai/gateway/security.md, observed 2026-09-01
- Multi-user mode, https://docs.openclaw.ai/concepts/multi-user.md, observed 2026-09-01
