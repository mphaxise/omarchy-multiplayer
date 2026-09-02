# Identity and attribution

Status: proposed, 2026-09-01. Slice 1. This file specifies attribution on top of the objects `01-session-model.md` defines.

Every event in `events.jsonl` names an actor, and every mutable field in `session.json` records who last changed it. Six attribution layers touch a session: creator, owner, participant, presence, instruction author, and commit author. Slice 1 implements the first, second, third, and fifth of these on one OS user. This file specifies that shape, the reserved shape for the other two, and the rule that holds across every slice: an actor is named on every record, and a human is never inferred from an agent's action.

## Actors

An actor is the object `01-session-model.md` defines:

```
{ "kind": "human" | "agent" | "system", "id": "<string>", "label": "<display>" }
```

Slice 1 has exactly three actors in practice on a given machine:

- `human:<username>@<hostname>`, the OS user who runs the launcher.
- `agent:<session-id>`, an agent acting from within its own session, for example when it spawns a child or sends an instruction into another session.
- `system:omarchy`, the launcher and reconciler acting on their own, for example when the reconciler adopts an orphaned Herdr pane.

`label` is display text only, a name or short description, and carries no authority. Two actor records with the same `kind` and `id` are the same actor; `label` can change without changing identity.

## `created_by`

`session new` sets `created_by` to `human:<username>@<hostname>` for the OS user who ran the command. `session new --from <session>` sets it instead to `agent:<session-id>` for the session named by `--from`, and records `lineage.parent_id` on the child and the child in `lineage.children` on the parent, per `01-session-model.md`. `created_by` is written once at `session.created` and never changes; invariant 4 in the session model holds it fixed even when ownership moves on.

## `owner`

`owner` defaults to `created_by` at creation. It changes only through the `assign` command (`session assign <id> --to <actor>`), run by a human or an agent against a session it can see, which writes an `owner.assigned` event carrying `from`, `to`, and the actor who ran the command. `owner.assigned_by` on the record is that actor, not the new owner.

Reassigning the owner changes two things: which actor the panel displays as responsible, and which actor a notification about that session routes to by default. It changes nothing else. It grants the new owner no access beyond what their OS account already has, and removes none from the old owner. Slice 1 has no access list to change; the point holds regardless, because slice 2 adds an access list that assignment still does not touch.

## `participants`

`participants` accrues one entry per actor whose instruction reached the session and was delivered to the harness, not per actor who merely opened the panel or attached a terminal to watch. An entry is `{actor, first_input_at, last_input_at}`; `last_input_at` updates on each further instruction from that actor, an entry is otherwise never edited, and none is ever removed short of deleting the session. The list is bounded to 32 actors; once full, a new actor's instruction still delivers and still lands in `events.jsonl`, but earns no `participants` slot. The session's own agent is never a participant in its own record. A passive viewer, an attached terminal or an open panel row that sends nothing, is never recorded at all.

## Instructions and the delivery marker

Every instruction carries `author` (an actor) and, when sent from another session, `origin_session`. `01-session-model.md` fixes the shape; delivery is what marks it. When `origin_session` is set, the text handed to the harness is prefixed with a fixed marker line naming the origin session, defined once in `02-command-surface.md` and used verbatim everywhere an instruction crosses a session boundary. The marker exists so the model reads the line as inter-agent traffic, never as the user typing at it directly. OpenClaw's session-state design solves the identical problem by tagging inter-agent messages so the model treats them as data; the marker here borrows that idea.

## The accountability rule

Every event in `events.jsonl` has an `actor` field, with no exception; `system:omarchy` is itself an actor for exactly this reason, so a reconciler action or a launcher default is attributable instead of anonymous. Nothing in this design infers a human from an agent's action: an agent's commit is authored by the agent's git identity, an agent's instruction to another session is authored by `agent:<session-id>`, and no code path substitutes the human who happens to own that session for the agent that actually acted.

Nissenbaum's account of "many hands" names the failure this prevents: distributed systems diffuse responsibility until no one is answerable for an outcome, by collapsing who-did-it into who-is-nominally-in-charge. Naming the acting actor on every event keeps the two questions separate. OpenClaw states the same rule for its own ownership and participant records: attribution and participation never grant session access, and ownership, sidebar visibility, and presence are usability features with no security guarantee. This design adopts that rule for the same reason: an owner label answers who is responsible, and a separate grant answers who is allowed.

## Reserved shape for slice 2

None of this is built in slice 1. The shape reserves room for it without changing what slice 1 already writes.

A `human` actor gains two optional fields: `profile`, naming a gateway identity or a verified GitHub account, and `verified_at`, the time that identity was verified. An actor with no `profile` is exactly today's `human:<username>@<hostname>`, unverified and machine-local.

A session gains `visibility`, one of `private`, `draft`, or `shared`, and `access`, a list of `{actor, level}` with `level` one of `view`, `suggest`, `contribute`, or `own`. `access` is distinct from `owner`: owner is who is responsible, access is who may act at all and how much. A `draft` session stays out of other actors' session lists until its owner publishes it, matching OpenClaw's draft state, where work in progress stays out of teammates' sidebars until published and an admin can still see it. `suggest` access lets an actor queue instructions that do not run: they write with `delivery: "suggested"` instead of `"steer"` or `"followup"`, and sit until the owner accepts or dismisses them. Nothing with `suggest` access can move a session's state on its own.

Presence, meaning which actors currently have a terminal attached or a panel open on a session, tracks only in memory and never writes to `session.json` or `events.jsonl`. It disappears when the last viewer disconnects and does not survive a restart. This mirrors OpenClaw's live presence and typing drafts, explicitly ephemeral and never entered into the transcript or the model's context.

Commit co-author trailers are added only for actors with a verified `profile`, following OpenClaw's rule that public co-author credit requires a verified GitHub identity and an explicit per-account default. An unverified human, an agent, or a system actor never receives a trailer, no matter how much it participated.

## What slice 1 deliberately omits

Slice 1 runs on one OS user. There is no access list: an actor that can reach the machine can reach every session on it, exactly as `owner` already implies. There is no presence: the panel shows state and receipts, not who else is looking, because there is no one else. Building `visibility`, `access`, `profile`, or presence now would add fields with no way to test them and no second user to test them against. The reserved shape above exists so slice 2 can add behavior without a schema migration.

## Attribution layers

| Layer | Immutable or mutable | Durable or ephemeral | Slice |
|---|---|---|---|
| Creator (`created_by`) | Immutable | Durable | 1 |
| Owner (`owner`) | Mutable, only via `owner.assigned` | Durable | 1 |
| Participant (`participants`) | Append-only; existing entries only update `last_input_at` | Durable | 1 |
| Presence | Changes continuously | Ephemeral, never recorded | 2 |
| Instruction author (`instructions[].author`) | Immutable per instruction | Durable | 1 |
| Commit author / co-author trailer | Immutable once committed | Durable, in git history | 1 for the primary author; 2 for the verified co-author trailer |

## Trust boundary

Slice 1 runs on one machine with one OS user, so every actor on it already has that user's full access, and `owner` and `participants` are bookkeeping, not gates. Shared, when it arrives, means people who trust each other enough to sit on one gateway together, the same boundary OpenClaw draws around a Gateway: anyone who can operate an agent there can make it do anything that agent can do. Isolation is not a setting inside this design. It requires separate OS users or separate machines, because access lists and visibility states describe who sees what, not who is barred from what.

## Verify on rig

Whether `$HOSTNAME` on the ggalancs image resolves to a stable, meaningful value for `human:<username>@<hostname>`, or whether the unofficial image's default hostname makes every session on the rig report the same generic host segment regardless of which machine ran it.

## Sources

OpenClaw multi-user mode and user model pages at docs.openclaw.ai/concepts/multi-user and docs.openclaw.ai/concepts/user-model (observed 2026-09-01), for the creator/owner/participant split, the draft-visibility model, ephemeral presence and typing drafts, and verified-identity co-author trailers. Nissenbaum, "Accountability in a Computerized Society" (1996), for the many-hands account of diffused responsibility. `01-session-model.md` for the actor shape, instruction shape, and invariants this file specifies attribution on top of.
