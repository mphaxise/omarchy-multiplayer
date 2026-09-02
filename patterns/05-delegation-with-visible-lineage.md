---
pattern: Delegation with visible lineage
source: https://docs.openclaw.ai/concepts/multi-user.md, https://docs.openclaw.ai/tools/subagents.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: Herdr runtime
slice: 1
---

# Delegation with visible lineage

## What OpenClaw does

A session an agent spawns with `sessions_spawn(visible: true)` is attributed to the requesting agent, not to the human talking to it: the child's creator and initial owner is the agent, shown with the agent's own name and avatar instead of an opaque key. The accepted spawn call doubles as a receipt: it returns the child session key, a run id, a Control UI session URL, and an owner record, and the model is told to put the session URL on the first line and `Owner: <label>` on the second when it announces the spawn in chat. Depth and fan-out are bounded by config, not convention. `maxSpawnDepth` runs 1 to 5, default 1, and `maxChildrenPerAgent` runs 1 to 20, default 5, both enforced at spawn time; a depth-1 session only gets orchestration tools back when depth 2 is explicitly allowed, and depth 2 can never spawn further. Completion pushes instead of polling: the parent calls `sessions_yield` to end its turn and wait, the child's result arrives as the next message, and cancelling a parent cascades to its children.

## What Omarchy has today

Herdr's `worktree.create` already groups a worktree-derived workspace under its parent workspace in the sidebar, the one piece of parent and child display Omarchy gets for free. There is no receipt, no owner record, and no depth or fan-out limit; nothing stops a session from launching an unbounded number of others, and nothing records why a child exists.

## What porting it means

This is what `lineage` and the `child.spawned`/`child.completed` events in the session model already describe. The port is an explicit verb, `omarchy session spawn <parent-id> --agent <kind> --reason "<text>"`, that writes `lineage.parent_id` and `spawn_reason` on the child, appends it to the parent's `lineage.children`, and emits `child.spawned`. Completion should push exactly as OpenClaw does it: deliver `child.completed` into the parent's `queue` as a marked instruction, so the parent agent learns the outcome without polling, which is already the design note in the spec. Depth 3 and 5 children per session are already spec'd, close to OpenClaw's own defaults on purpose. The receipt piece, a session id and owner on two lines, is a one-line addition to whatever prints a spawn confirmation.

## Open questions

- Must the parent be `working` to spawn, or can any live session do it?
- Can a cascading stop reliably reach a child's Herdr pane through the socket API, since Herdr, not Omarchy, owns the process?
- Does the child need a URL-equivalent before Omarchy has any URL-addressable session view, or is an id enough for slice 1?

## Sources

- Multi-user mode, https://docs.openclaw.ai/concepts/multi-user.md, observed 2026-09-01
- Sub-agents, https://docs.openclaw.ai/tools/subagents.md, observed 2026-09-01
