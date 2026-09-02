---
pattern: Structured parallelism
source: https://docs.openclaw.ai/tools/subagents.md, https://docs.openclaw.ai/tools/swarm.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: Herdr runtime
slice: 3
---

# Structured parallelism

## What OpenClaw does

Sub-agents are the baseline parallel primitive: each spawn gets its own session and isolated context by default, with a `fork` mode for when a child genuinely needs the parent's transcript, described as something to use sparingly, not a substitute for a clear task prompt. Nesting is bounded and structured: depth 0 is the main session, depth 1 is a sub-agent that only becomes an orchestrator when depth 2 is explicitly configured, and depth 2 is always a leaf, hard-denied from spawning further regardless of config. Swarm builds structured fan-out on top of that, adding no new language, just bounded concurrency, default 8, a per-group cap of 50, and a lifetime cap of 200 children described as the runaway-spawn backstop, plus JSON-Schema-validated structured results so a parent can wait on many children and get typed data back instead of parsing prose. Every swarm child is a leaf by construction, even when depth would otherwise allow more, and every child's approval requests fail closed: a tool call needing human sign-off is denied outright, and the denial comes back in the child's own result for the orchestrating script to handle.

## What Omarchy has today

`hsl <count> <command>` already builds a grid of identical panes, Omarchy's own name for it is the swarm, and `hdl <ai> [<ai2>]` lays out an editor plus one or two agent panes plus a terminal strip, both bash functions built on Herdr and tmux. This is real, working fan-out today, but unstructured: no concurrency cap, no depth limit, no typed result, no fail-closed approval. `hsl 8 claude` opens eight panes with no relationship recorded between them beyond launching together.

## What porting it means

The session model already puts a depth limit of 3 and a children-per-session limit of 5 into the schema, deliberately close to OpenClaw's own defaults, so the bookkeeping exists. What is missing is treating `hsl`'s fan-out as spawning, not just launching: have it create sessions that all name the same `lineage.parent_id`, enforce the existing caps at creation, and require the invoking session to be idle or working first. A typed result contract is a stretch goal, not a slice 1 target: swarm assumes the child harness can emit a schema-validated payload on request, and none of Omarchy's eleven CLIs do that natively, so the honest first cut is a plain `receipt.json` per child and a manual read of its diff stat.

## Open questions

- Does `hsl` change at all before slice 3, or does structured parallelism wait entirely?
- Does a swarm child inherit the parent's `mode` automatically, given invariant 5 already forbids bypass flags in shared or restricted mode?
- What bounds resource use the way `maxConcurrent` does, given eight parallel panes on one machine can exhaust memory or rate limits fast?

## Sources

- Sub-agents, https://docs.openclaw.ai/tools/subagents.md, observed 2026-09-01
- Swarm, https://docs.openclaw.ai/tools/swarm.md, observed 2026-09-01
