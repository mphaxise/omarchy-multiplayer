# Evaluation run 10: two people, in proxy form, on the rig

Status: hands-on, `live`, 2026-09-03, 09:00 to 09:17 PDT, on `slice-3/two-people` at Omarchy `0b3f1b7` (the aarch64 image), Herdr 0.8.2, Claude Code 2.1.259, driven over ssh from the Mac. Raw evidence: `captures/evaluation-run10-two-people_hands-on_arm-port_2026-09-03/`. The spec is `spec/12-two-people.md`; the signals are `PLAN.md`, slice 3.

## The result

The two-people mechanics hold on this rig with the proxy `spec/12` describes: the second person is the Mac over ssh, `human:omarchy@_gateway`, and the owner is the rig's own user, `human:omarchy@omarchy`, both the same OS account on one store. The second person saw every shared session and no draft, could not send until granted, suggested, and could not accept their own suggestion. The owner accepted from the panel with `y`, the instruction ran under the suggester's name, and the record holds the three attributed events. Assignment moved the toast's owner and changed no access, and the creator kept `own`. Presence showed the second person and left nothing in the record. What the run cannot say: anything about isolation, which the proxy does not test, and whether a real second person reads any of this right, which the sitting will say.

Two defects surfaced. One was serious: the reconciler's sweep closed a brand-new session's Herdr workspace within five seconds of its creation, which is why two starts were refused before pass `a` ran. One was about names: with both people called "omarchy", the panel said "omarchy suggests" and the loop view said "omarchy: …" for both, so nothing on screen told the owner who was speaking. Both are fixed in the branch and both fixes are captured live.

## What happened

Three passes on the spike repo, each a session cut from `session/loop-hello` with the intent "hello.html: the owner decides, a second person suggests", plus a draft session `my-draft` that the owner set to `draft`.

| Time (UTC) | Pass | Step | Evidence |
|---|---|---|---|
| 16:00:32 | a | `new` as the owner; `my-draft` set to draft; both idle in Herdr `w8` and `w9` | `timeline.txt` |
| 16:00:56 | a | `list` as the second person: `shared-page` shared, the owner's draft absent (the one draft it sees is its own, from a refused start earlier); `send` refused, "view access; contribute is needed", rc 5 | `timeline.txt` |
| 16:00:56 | a | `grant --to omarchy@_gateway --level suggest` | `a/events.jsonl` seq 6 |
| 16:00:57 | a | `send --suggest` as the second person, rc 0, nothing ran; `accept` as the second person refused, "suggest access; own is needed", rc 5 | `timeline.txt` |
| 16:01:28 | a | The panel as the owner: `shared-page` first under Needs you, "omarchy suggests", the text quoted, `y Accept` and `d Dismiss` | `a-panel-suggests-before-naming-fix.jpg` |
| 16:01:29 | a | `y`: `suggestion.accepted` by `omarchy@omarchy`, `instruction.delivered` by `omarchy@_gateway`; the row "accepted, sent"; the agent working | `a-panel-accepted.jpg`, `a/loop-view.txt` |
| 16:02:02 | a | `assign` to `omarchy@_gateway`: owner changed, access list unchanged (`[(omarchy@_gateway, suggest)]`); presence mentions in the record: 0; present: the second person | `timeline.txt` |
| 16:02:03 | a | The agent asked a question (this branch has no footer): `blocked`; the toast body "… · owned by omarchy@_gateway · Click to open and answer"; the panel's row "needs you", Answer, badge 1 | `toasts-replayed.txt`, `a-panel-blocked-owned-by.jpg` |
| 16:03:35 | a | `send "2"` as the new owner: dropped, "agent is blocked and requires interactive input", rc 5 (by design) | `a/loop-view.txt` |
| 16:04:39 | a | The creator, no longer the owner, opened the session and answered `2` in the attached terminal; the commit `c132da4 italic footer, suggested` landed; `done --verdict kept` as the new owner; the receipt's Owner line `human:omarchy@_gateway   created by human:omarchy@omarchy` | `a/receipt.txt` |
| 16:12:26 | | Core, watcher, and panel redeployed with the fixes below; pass `a`'s loop view and receipt re-rendered from the record | `timeline.txt` |
| 16:12:34 to 16:14:42 | b | The same steps: "omarchy@_gateway suggests" on the hero and the row; after the assignment the row reads "owned by omarchy@_gateway"; the agent committed without a question this time; `done` as the new owner | `b-panel-suggests.jpg`, `b-panel-owned-by.jpg`, `b/loop-view.txt`, `b/receipt.txt` |
| 16:16:06 to 16:16:24 | c | A suggestion the owner turns down: the hero "omarchy@_gateway suggests · y accepts · just n…"; `d`; `suggestion.dismissed` by the owner naming the suggester; nothing needs you | `c-panel-suggests.jpg`, `c-panel-dismissed.jpg`, `c/loop-view.txt` |

## Against the signals

1. **The second person sees every shared session and no draft, verified on both sides.** Held for the command surface: `list` as each identity, with ids. The draft the second person saw was its own, from a refused start earlier in the morning; the owner's drafts stayed out. The second side has no panel in this proxy, so "capture on both sides" is a list on one side and the panel on the other.
2. **A suggestion appears as "<name> suggests…", runs only after acceptance, three attributed events.** Held. `instruction.queued` with `delivery: suggested` by the suggester, `suggestion.accepted` by the owner, `instruction.delivered` by the suggester; the agent's prompt count did not move until `y`. The name half held only after the fix: with both labels "omarchy" the owner saw their own name suggesting to them.
3. **Assignment moves the needs-you notification and nothing else; the previous owner's access is unchanged.** Held. The watcher's body gained "owned by omarchy@_gateway"; the access list was the same before and after; the creator opened the session and answered the agent's question after losing the owner role, which is the `own` a creator keeps.
4. **Presence shows the second person and writes nothing to the record.** Held for the writing half: 0 mentions in `session.json` and `events.jsonl`, `presence` listing the second person after `presence --here` and `open`. The leaving half is weaker than the signal states: presence expires by a 600-second TTL or an explicit `--leave`; a terminal closing does not clear it, and the run did not test a close. Presence on a session that has ended now clears with the ending.
5. **Every slice-1 and slice-2 signal still passes for the owner.** Held for what the passes exercised: `new`, the panel's first row, `send`, `accept`, `done`, the receipt, the toasts, and the suggestion's delivery to a live agent. Not re-run here: a reboot, a Herdr restart, lanes on a session with two people.

## What the run found

1. **The sweep closed new workspaces.** Herdr reuses workspace ids after a server restart (`w3`, `w6` in the morning had belonged to sessions ended the day before). `sweep_ended_workspaces` matched a live workspace against the `runtime.bound` events of ended sessions by workspace id and closed it, five seconds after `new` created it, so `agent.start` failed with "agent target pane w3:p1 not found". The sweep now matches panes by the `tokens.session_id` the core reports on every pane it opens, and skips adopted sessions by their token too. `open` on a session that was created and never bound starts it fresh, and the start retries on "not found" as it did on "not an available shell".
2. **Names collide in the proxy, and would for two people with one first name.** The list, the loop view, the panel, and the watcher used the label alone. `display_name` now gives `user@host` when the label matches the viewer's own; the list carries `author_display`, `owner_display`, and `owned_by_other` (null when the viewer owns the session), the loop view and the watcher use the same rule.
3. **The second person was invisible in the loop view and the receipt.** A suggestion and its acceptance rendered as two identical instruction lines; access grants, assignment, and visibility did not render at all; the receipt counted deliveries and nothing else. The loop view now has `suggested`, `instruction … [accepted by]`, `dismissed`, `access`, `owner`, and `visibility` rows, and the receipt a People group (visibility, access, assignments, suggestion counts).
4. **The panel did not name the owner.** Spec 12 gives the toast "owned by <name>" and says the panel shows the owner; the row did not. It does now, on the detail line, and the hero's meta for a suggestion reads "<who> suggests · y accepts · <age>" so a long name elides the age and never the action ("Y ACCEP…" in pass `b`).
5. **Presence outlived sessions.** An ended session from the morning still listed the second person as present, within the TTL. Presence clears on `session.ended`, and `list` reports none for ended sessions.

## Judgment

The identity decision `PLAN.md` asks for first: the second identity space is `human:<user>@<host>`, unverified, with the host from the ssh client (`SSH_CONNECTION`, reverse-resolved) and `OMARCHY_ACTOR` as the override. It works as a proxy and it exposes its own weakness: on this rig the Mac resolves to `_gateway`, a NAT name, so the second person is "omarchy@_gateway" on every surface. That is a naming problem, not a mechanics problem, and it argues for the next step being a second OS account on the same machine, where the user part differs and the host part can be dropped. Verified profiles stay reserved.

`send` to a blocked agent is refused with "requires interactive input", so a new owner cannot answer a question from another machine; the panel's Answer opens a terminal on the rig, which the ssh identity does not have. For two people on two hosts, the answer path needs the second host to attach (Herdr's remote attach, untested here) or a `send --answer` that types into the pane on the person's word. That is a slice-3 design question for the sitting, and it is the one place in this run where the second person was stuck.

## What this run cannot claim

That two people are kept apart: one OS user, one store, by design. That a second person reads "omarchy@_gateway suggests" as a person: the sitting. That presence follows a terminal closing: untested, and the TTL says it does not. That the second person can answer an agent's question from their own machine: they cannot, today.
