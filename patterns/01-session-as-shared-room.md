---
pattern: Session as shared room
source: https://docs.openclaw.ai/concepts/session.md, https://docs.openclaw.ai/concepts/session-attachment.md, https://docs.openclaw.ai/concepts/session-tool.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: Herdr runtime
slice: 1
---

# Session as shared room

## What OpenClaw does

A session in OpenClaw belongs to the Gateway, not to whichever client happens to be looking at it. The Control UI, a terminal (`openclaw tui`), a mobile client, and a coding harness (`openclaw attach`) all project the same server-held state instead of keeping their own copies. Session keys follow a fixed shape, `agent:<agentId>:<rest>`, and a session with a UUID tail gets a short, shareable form built from 8 to 32 lowercase hex characters of that UUID. `sessions.resolve` turns a key, a raw ID, a label, or a short ID into the canonical session, filtered by what the caller is allowed to see, and returns up to ten candidates when a short ID is ambiguous instead of guessing. Attaching a coding harness mints a temporary, session-scoped MCP grant that expires when the harness exits. Continue in terminal copies a credential-free, opaque handoff string, capped at 512 characters, that a paired CLI profile can run without ever printing a token. Message routing decides which session a new message joins: direct messages default to one shared session, groups and rooms default to isolated sessions, cron gets a fresh session every run. Storage lives in per-agent SQLite plus archived JSONL, with lifecycle timestamps driving optional daily or idle resets. A typed failure taxonomy tells a client exactly why an attach failed and what to do about it.

## What Omarchy has today

Nothing plays this role yet. `bin/omarchy-launch-tui` execs a terminal directly around the agent command; nothing survives the window closing. Herdr is the piece that actually keeps work alive: a background server with named sessions (`herdr session list|attach <name>|stop|delete`), each with its own socket. Herdr's session is a pane namespace, not a single addressable task with an owner and a goal, and Herdr today mirrors one frame to every client instead of letting several viewers read one state independently.

## What porting it means

This is what `session.json` in the session model spec already is: a record that exists before its Herdr pane and outlives it, per invariant 1. `omarchy session open <id>` is Omarchy's version of `attach`, re-binding a pane through the `orphaned` to `working` transition already in the state machine, while the panel reads `session.json` and `events.jsonl` regardless of which terminal, if any, is attached. The `runtime` field going `null` is the local equivalent of a client detaching without the session dying. Slice 1 does not need short-ID sharing across machines, but the `id` (ULID) and `name` fields already carry the shape forward for whenever a second viewer shows up.

## Open questions

- Does Herdr's socket API let a second reader watch a pane live, the way several OpenClaw clients read one session? Verify on rig.
- Should opening an already-bound session detach the first viewer, or mirror to both, given Herdr's current one-frame-to-everyone behavior?
- Does Omarchy need its own short-ID scheme before any session is addressed outside the local machine?

## Sources

- Session management, https://docs.openclaw.ai/concepts/session.md, observed 2026-09-01
- Session synchronization and attachment, https://docs.openclaw.ai/concepts/session-attachment.md, observed 2026-09-01
- Session tools, https://docs.openclaw.ai/concepts/session-tool.md, observed 2026-09-01
