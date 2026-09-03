# Two people on one session

Status: proposed 2026-09-03 (slice 3); the core, its tests, the watcher change, and the panel's suggestion and presence rows exist as of the same day, in proxy form; the rig run and the sitting with a second person follow. Builds on `08-identity-and-attribution.md`, whose reserved shape this file fills in, and on `01-session-model.md`. The question it serves is in `PLAN.md`, slice 3: when a second person joins a session, can both see it, can the second person suggest and the owner decide, and does the record keep every action attributed and every approval visible?

## The identity, and what the proxy can claim

A human actor stays `human:<user>@<host>`, unverified and machine-local. Slice 3 adds two ways for a second identity to appear on one store, both proxies for the real second-person cases `PLAN.md` names (another OS account, another host over Herdr `--remote`):

- `OMARCHY_ACTOR=human:<user>@<host>` names the actor for the commands that run in that environment.
- A command that arrives over ssh reports the client's host instead of the machine's own (`SSH_CONNECTION`), so the same OS user driving the rig from the Mac is `human:omarchy@<mac>`, a distinguishable actor.

What the proxy tests: the mechanics of visibility, access, suggestions, acceptance, assignment, and presence, with every action attributed to the actor that took it. What it cannot claim: isolation. Both identities are the same OS user on the same store, and anyone on the machine can set either. That is the trust boundary `08` states and this file keeps: a second person who must be kept out needs their own account or host, never a flag on the first person's store. Verified profiles (`profile`, `verified_at`) and commit trailers stay reserved.

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

## Assignment

`assign <session> <user>@<host>` moves responsibility: which actor the panel shows as owner and which actor a notification names. It grants and revokes nothing; a former owner who created the session keeps `own` as the creator. On one desktop, routing to the owner means naming the owner when it is someone else: the toast's body gains "owned by <name>".

## Presence

Which actors have the session open right now lives in the runtime directory only (`$XDG_RUNTIME_DIR/omarchy-sessions/presence/<session>/<actor>`), touched by `open` and by `presence --here`, dropped by `presence --leave`, expired after ten minutes. It is never written to `session.json` or `events.jsonl`, and it dies with the runtime directory. `list --json` carries it as `presence` and the panel shows "N here" on the row when more than one actor is present.

## The panel

A session with a suggestion waiting ranks in Needs you after the agents that are asking; the row reads "<name> suggests" in the accent color with the suggestion's first line on line 2, and `y` accepts, `d` dismisses, from the keyboard or the row's buttons. The legend swaps "⏎ open · n new" for "y accept · d dismiss" while the cursor is on such a row. Drafts and private sessions never reach the panel of an actor who cannot see them, because `list` filters them first. Presence shows as "N here" on line 2.

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

## Success signals

The five in `PLAN.md`, slice 3, measured on the rig with captures: the second person sees every shared session and no draft; a suggestion appears to the owner, runs only after acceptance, and the record shows the suggestion, the acceptance, and the delivery as three attributed events; assignment moves the notification and changes no access; presence shows while a terminal is attached and writes nothing to the record; every earlier signal still passes for the owner.

## Verify on rig

- Whether `SSH_CONNECTION` reaches the commands when they run through `ssh omarchy-rig <command>` from the Mac, and what host name it resolves to.
- Whether presence written by `open` from a second identity over ssh is visible on the rig's panel within a poll.
- The row budget with a suggestion's text on line 2 beside the goal.
