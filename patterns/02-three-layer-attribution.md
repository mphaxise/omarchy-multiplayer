---
pattern: Three-layer attribution
source: https://docs.openclaw.ai/concepts/multi-user.md, https://docs.openclaw.ai/concepts/session-tool.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: none yet
slice: 2
---

# Three-layer attribution

## What OpenClaw does

Every session in multi-user mode carries three separate layers of attribution. Creator is immutable: a write-once field set only when the creation path can prove who caused it, and it stays anchored to that person even after everything else about the session changes. Owner is assignable, modeled explicitly on a GitHub issue assignee: it defaults to the creator, changes through "Assign to me" or "Assign to..." in the session menu, or through the `sessions` tool's `assign_owner` action with an `ownerType` and `ownerId`, and both paths call the Gateway method `sessions.assignOwner` under `operator.write`. Participants is a bounded history: every authenticated person, channel sender, or requesting agent whose input reached the session, capped at 32 records, recorded in the background so it never delays a turn. Reassigning the owner only changes responsibility and the sidebar label, from "Created by" to "Owned by." It never moves sharing authority, which stays with the creator for the life of the session. The docs state the point directly: ownership and participant history are display and coordination, not an access grant.

## What Omarchy has today

`spec/01-session-model.md` already carries this exact shape. `created_by` is immutable per invariant 4, `owner` is a reassignable `{actor, assigned_at, assigned_by}` record that only changes through the `owner.assigned` event, and `participants` is a list of `{actor, first_input_at, last_input_at}` bounded to 32 entries, the same cap OpenClaw uses. What slice 1 lacks is a second identity for these fields to distinguish: the only human actor is `human:<username>@<hostname>` for the one OS user, so `owner` and `participants` exist in the schema but carry no multi-person meaning yet.

## What porting it means

Slice 2's job is giving the actor shape a real second person, not inventing new fields. Assignment ports directly as `omarchy session assign <id> --to <actor>`, emitting the `owner.assigned` event the spec already defines. Participant tracking ports as an append to `participants` on any `instruction.queued` event from a new actor, matching OpenClaw's background, non-blocking write and its 32-entry cap exactly. The discipline worth carrying over deliberately is the non-security framing: `owner` must keep meaning who is responsible, never who has access, so slice 2 does not let it quietly become a permissions field.

## Open questions

- What is Omarchy's second identity space in slice 2: another OS account, an SSH peer, or something else?
- Does the panel need a facepile once more than one participant exists, or is a label enough for a first cut?
- Does reassignment need its own confirmation step given Omarchy has no session menu yet?

## Sources

- Multi-user mode, https://docs.openclaw.ai/concepts/multi-user.md, observed 2026-09-01
- Session tools, https://docs.openclaw.ai/concepts/session-tool.md, observed 2026-09-01
