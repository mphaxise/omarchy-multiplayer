---
pattern: Interoperability as boundary
source: https://docs.openclaw.ai/gateway/cli-backends.md, https://docs.openclaw.ai/tools/acp-agents.md, https://docs.openclaw.ai/concepts/agent-runtimes.md, https://docs.openclaw.ai/channels/a2a.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: none yet
slice: out of scope
---

# Interoperability as boundary

## What OpenClaw does

OpenClaw draws a hard line between runtimes it owns and harnesses it only hosts. CLI backends are text-only local fallbacks; no tool is injected unless a backend opts into a bundled MCP bridge over a per-run token. ACP spawns a genuinely external harness, Claude Code, Cursor, Gemini CLI, OpenCode, and more, where OpenClaw owns routing, background-task state, delivery, and policy, while the harness owns its own login, model catalog, and native tools, and ACP sessions explicitly run outside OpenClaw's own sandbox. A2A, the Linux Foundation's open protocol, is the boundary for agents that are not OpenClaw at all: a public Agent Card advertises what is reachable, every peer needs its own bearer token with no unauthenticated mode, each authenticated peer gets a pinned and isolated session so remote content never joins the operator's main session, and task cancellation is refused outright instead of falsely acknowledged, because a dispatched run has no abort seam across that boundary. The pattern across all three: the less OpenClaw's own visibility and policy reach, the harder the authentication and the narrower the session scope have to be, and a failure state that admits what it cannot guarantee beats one that pretends.

## What Omarchy has today

Nothing, and no roadmap item asks for it. The eleven agent CLIs are alternatives a user picks between, not peers that talk to each other or to agents on other machines. `bin/omarchy-agent` launches one harness per session with no protocol boundary, because there is no second party to protect a boundary against.

## What porting it means

I am marking this out of scope deliberately. Omarchy's own roadmap, one user and one machine, then user-to-agent control, then agent-to-agent, then user-to-user, stays inside sessions Omarchy itself creates. A2A-style interoperability is a different axis: accepting instructions from an agent this gateway did not spawn and does not control. The one thing worth borrowing without adopting the protocol is the posture. If a later slice ever lets a session receive an instruction from outside Herdr's own reach, it should get A2A's treatment, its own pinned identity and an honest refusal on anything Omarchy cannot guarantee, not the same `origin_session` marker built for same-machine parent-child traffic.

## Open questions

- Does Omarchy's roadmap ever need cross-machine agent traffic, or does agent-to-agent mean same-machine delegation only, which the lineage pattern already covers?
- If it does come up, is Herdr's own remote thin client, which mirrors one frame to every viewer today, close enough to build on?
- Should the `agent:<session-id>` actor kind ever name a foreign agent, or does that need its own kind by design?

## Sources

- CLI backends, https://docs.openclaw.ai/gateway/cli-backends.md, observed 2026-09-01
- ACP agents, https://docs.openclaw.ai/tools/acp-agents.md, observed 2026-09-01
- Agent runtimes, https://docs.openclaw.ai/concepts/agent-runtimes.md, observed 2026-09-01
- A2A, https://docs.openclaw.ai/channels/a2a.md, observed 2026-09-01
