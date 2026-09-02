---
pattern: Isolated agent identities
source: https://docs.openclaw.ai/concepts/oauth.md, https://docs.openclaw.ai/gateway/secrets.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: none yet
slice: 3
---

# Isolated agent identities

## What OpenClaw does

OpenClaw treats credential isolation between agents as a design problem with two separate answers. For accounts that should never mix, the documented pattern is separate agents, each with its own session, credentials, and workspace, created with `openclaw agents add <name>`. Multiple profiles inside one agent, picked through `auth.order` or `/model ...@<profileId>`, are named as the advanced path, not the preferred one, and sub-agent auth is resolved by agent id with shared profiles merged in only as a fallback; the docs say plainly that fully isolated auth per agent is not supported yet. For credentials at execution time, OpenClaw can mint a per-run, process-local sentinel standing in for a real key everywhere it would otherwise appear, in logs, in auth storage, in SDK config, and only its own loopback secret egress proxy substitutes the real value into outbound HTTPS traffic, only for hostnames that credential was explicitly bound to with `secrets store set <NAME> --allow-host <host>`. An unbound host is refused with the exact command needed to fix it. The proxy's CA and each run's auth token are generated fresh and torn down when the run closes.

## What Omarchy has today

Nothing. `bin/omarchy-agent` launches any of eleven agent CLIs through the same launcher, in the same `~/Work`, as the same OS user. Each CLI manages its own login independently of Omarchy, so isolation today is whatever the vendor happens to provide, not anything Omarchy adds.

## What porting it means

Full sentinel and egress-proxy machinery needs an actual gateway brokering every outbound call, which is out of reach for a launcher and shell plugin in slice 3. The useful part to port is the separate-agents pattern, which needs no proxy: `session.json`'s `agent.kind` field already names which harness owns a session, so the next step is letting a session declare which credential context it launches into, so switching agents is a different identity, not the same shell environment with a different binary. That belongs in `started_with`, recording which credential context a session used so the receipt can show it, and in `omarchy-agent` accepting a profile argument the way OpenClaw's `--profile-id` does.

## Open questions

- Do any of the eleven CLIs already support a profile-scoped login the way Claude or Codex OAuth profiles do, or would Omarchy fake this with per-agent `HOME` overrides?
- Is there ever a case in slice 1 through 3 where two different agent kinds should share one credential?
- Should `started_with.env_summary` name the credential context at all, or does that leak something into `receipt.json`?

## Sources

- OAuth, https://docs.openclaw.ai/concepts/oauth.md, observed 2026-09-01
- Secrets management, https://docs.openclaw.ai/gateway/secrets.md, observed 2026-09-01
