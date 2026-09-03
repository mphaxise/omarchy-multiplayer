# Two people on one session

Status: proposed 2026-09-03 (slice 3); built the same day in proxy form and verified on the rig in run 10 (`findings/evaluation-run10-two-people-2026-09-03.md`), which settled the names rule, the loop view and receipt sections, and presence at the end below; the sitting with a second person follows. Builds on `08-identity-and-attribution.md`, whose reserved shape this file fills in, and on `01-session-model.md`. The question it serves is in `PLAN.md`, slice 3: when a second person joins a session, can both see it, can the second person suggest and the owner decide, and does the record keep every action attributed and every approval visible?

## The identity, and what the proxy can claim

A human actor stays `human:<user>@<host>`, unverified and machine-local. Slice 3 adds two ways for a second identity to appear on one store, both proxies for the real second-person cases `PLAN.md` names (another OS account, another host over Herdr `--remote`):

- `OMARCHY_ACTOR=human:<user>@<host>` names the actor for the commands that run in that environment.
- A command that arrives over ssh reports the client's host instead of the machine's own (`SSH_CONNECTION`), so the same OS user driving the rig from the Mac is `human:omarchy@<mac>`, a distinguishable actor.

On the rig the ssh client resolves to `_gateway`, the VM's NAT name, so the second person is `human:omarchy@_gateway`; the override is the fallback when the name is worse than that.

What the proxy tests: the mechanics of visibility, access, suggestions, acceptance, assignment, and presence, with every action attributed to the actor that took it. What it cannot claim: isolation. Both identities are the same OS user on the same store, and anyone on the machine can set either. That is the trust boundary `08` states and this file keeps: a second person who must be kept out needs their own account or host, never a flag on the first person's store. Verified profiles (`profile`, `verified_at`) and commit trailers stay reserved.

## Names on a surface

A person is shown by label (`omarchy`, `sam`) except when the label would read as the viewer's own name for someone else, in which case the surface shows `user@host`. Run 10's proxy is the case: both people are the OS user "omarchy", and before the rule the owner saw "omarchy suggests" and could not tell it was not them. `list --json` carries `owner_display`, `owned_by_other` (null when the viewer owns the session, else the owner's display name), and `author_display` on each suggestion; the loop view and the watcher's body apply the same rule.

## Visibility

A session carries `visibility`: `private`, `draft`, or `shared`. Records written before this field exist read as `shared`, so slice 1 stays unchanged. `visibility <session> draft|shared|private` records `session.visibility_changed` with `from` and `to`; only an actor with `own` may change it.

`list` shows a session to an actor who can see it: everyone when `shared`; the creator, the owner, and those granted access when `draft` or `private`. `list --all` is the exception for the person at the machine, and the panel never uses it. There is no admin actor in this slice; `08` reserved one and the proxy has no way to test it.

## Access

`access` is a list of `{actor, level, granted_by, granted_at}` with `level` one of `view`, `suggest`, `contribute`, `own`. It is distinct from `owner`: owner is who is responsible, access is who may act at all and how much. The creator and the owner hold `own` without an entry; a `shared` session gives everyone else `view`. `grant <session> --to <user>@<host> --level suggest` and `grant … --revoke` record `access.granted` and `access.revoked`.

What each level allows, enforced by the commands for the actor they see:

| Level | list, show, log, receipt | send --suggest | send, open (attach) | stop, done, assign, visibility, grant, accept |
|---|---|---|---|---|
| none (draft or private, not granted) | no | no | no | no |
| `view` | yes | no | no | no |
| `suggest` | yes | yes | no | no |
| `contribute` | yes | yes | yes | no |
| `own` | yes | yes | yes | yes |

## Suggestions

`send <session> "<text>" --suggest` writes an instruction with `delivery: "suggested"` from its author. It sits in the session's queue and never runs on its own. The owner sees it on the panel as "<name> suggests" with the text on the row, and decides: `accept <session>` records `suggestion.accepted` by the owner, then delivers the instruction to the agent with its original author, so the record shows three attributed facts, who suggested, who accepted, who the agent heard it from. `accept --dismiss` records `suggestion.dismissed` and drops it. `oldest` is the default; `latest` or an instruction id picks another.

Suggest versus start, OpenClaw's distinction (pattern 08), is exactly this: a `suggest` actor proposes, an `own` actor starts.

An accepted suggestion goes to the agent the way any instruction does, which means a `blocked` agent refuses it ("requires interactive input") and the person answers at the keyboard. A second person on another host has no keyboard on the session's pane, so today they cannot answer an agent's question even after the session is assigned to them (run 10, pass `a`). The answer path for two hosts is open: the second host attaching through Herdr, or a `send --answer` that types into the pane on the person's word.

## Assignment

`assign <session> <user>@<host>` moves responsibility: which actor the panel shows as owner and which actor a notification names. It grants and revokes nothing; a former owner who created the session keeps `own` as the creator. On one desktop, routing to the owner means naming the owner when it is someone else: the toast's body gains "owned by <name>".

## Presence

Which actors have the session open right now lives in the runtime directory only (`$XDG_RUNTIME_DIR/omarchy-sessions/presence/<session>/<actor>`), touched by `open` and by `presence --here`, dropped by `presence --leave`, expired after ten minutes, and cleared when the session ends. It is never written to `session.json` or `events.jsonl`, and it dies with the runtime directory. `list --json` carries it as `presence` for live sessions and the panel shows "N here" on the row when more than one actor is present. A terminal closing does not clear presence; the TTL does, which is weaker than `PLAN.md`'s signal 4 states and is recorded as such.

## The panel

A session with a suggestion waiting ranks in Needs you after the agents that are asking; the row reads "<name> suggests" in the accent color with the suggestion's first line on line 2, and `y` accepts, `d` dismisses, from the keyboard or the row's buttons. The hero's meta line reads "<name> suggests · y accepts · <age>", the action ahead of the age so a long name elides the age and never the hint. The legend swaps "⏎ open · n new" for "y accept · d dismiss" while the cursor is on such a row. A session owned by someone else says "owned by <name>" on line 2. Drafts and private sessions never reach the panel of an actor who cannot see them, because `list` filters them first. Presence shows as "N here" on line 2.

## Commands

| Command | What it does |
|---|---|
| `omarchy-agent-session-visibility <session> private\|draft\|shared` | who may see it |
| `omarchy-agent-session-grant <session> --to <user>@<host> [--level …] [--revoke]` | who may act, and how much |
| `omarchy-agent-session-send <session> "<text>" --suggest` | propose, without running |
| `omarchy-agent-session-accept <session> [oldest\|latest\|<id>] [--dismiss]` | the owner decides |
| `omarchy-agent-session-assign <session> <user>@<host>` | move responsibility |
| `omarchy-agent-session-presence <session> [--here\|--leave]` | who is here |
| `omarchy-agent-session-list --all` | everything, for the person at the machine |

## Events

`session.visibility_changed`, `access.granted`, `access.revoked`, `suggestion.accepted`, `suggestion.dismissed`; suggestions themselves are `instruction.queued` with `delivery: "suggested"`, and an accepted one is delivered as `instruction.delivered` by its original author with `accepted_by` on the instruction.

The loop view renders them as `suggested <name>: <text>`, `instruction <name>: <text> [accepted by <name>]`, `dismissed <name> dismissed <name>: <text>`, `access <name> may <level> (by <name>)`, `owner <name> -> <name> (by <name>)`, and `visibility <from> -> <to> (by <name>)`. The receipt gains a People group: visibility, the access list, each assignment, and the suggestion counts (made, accepted, dismissed, waiting) with their authors.

## Success signals

The five in `PLAN.md`, slice 3, measured on the rig with captures: the second person sees every shared session and no draft; a suggestion appears to the owner, runs only after acceptance, and the record shows the suggestion, the acceptance, and the delivery as three attributed events; assignment moves the notification and changes no access; presence shows while a terminal is attached and writes nothing to the record; every earlier signal still passes for the owner.

## Verified on the rig (run 10)

- `SSH_CONNECTION` reaches the commands through `ssh omarchy-rig <command>`; the client resolves to `_gateway`. The rig's own steps pin `OMARCHY_ACTOR=human:omarchy@omarchy`, because every command in a run driven over ssh would otherwise be the second person.
- Presence written over ssh shows in `list` on the rig at once; the panel's "N here" was not captured, because the owner's own presence is written by `open` and the runs opened once.
- The row holds the suggestion's text on line 2 with the goal elided behind it; the hero line is the tight one, hence the reorder above.
- Still open: the row budget with a suggestion and lanes on one session; the answer path for a second host.
