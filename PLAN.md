# Omarchy Multiplayer: the program plan

Status: plan v3, 2026-09-02, late night, written after slice 1 shipped as Keepalive. Progress as of 2026-09-03, early morning: slice 2a, 2d, and the buildable half of 2b are built and unit-tested on `slice-2/lanes`, slice 3's mechanics in proxy form on `slice-3/two-people`, 162 tests; none of it has run on the rig yet (`findings/slice2-3-build-2026-09-03.md`), and `main` still carries only slice 1 and this plan. Plan v2 (2026-09-01) and v1 are in git history; `decisions.md` carries the dated log. This version keeps v2's question and verified facts, records what slice 1 settled, and plans slices 2 through 4 in the detail the work now supports. Each slice is a bounded test with a question, success signals, a limit, and a review point; effort numbers are working estimates, and the order comes from learning value and reversibility, with gates applied first.

## Bottom line

Slice 1 held. On Omarchy, a durable session object plus a shell panel makes concurrent agent work legible and controllable for one person. Sessions survive every terminal closing and a reboot. Receipts carry the work. State changes arrive as notifications within a second. The waiting session is named first on every surface. Nothing launches with a bypass flag outside Personal mode. The plugin is public as Keepalive (`mphaxise/omarchy-keepalive`, id `io.github.mphaxise.keepalive`), submitted to the marketplace (`omacom/omarchy-plugin-marketplace#4566`), and proposed to Omarchy in discussion `omacom/omarchy#9936`. The evidence is in `findings/`, with captures, and the defect list from the review passes and eight scenario runs is what made it hold.

The program's real claim is still untested: a person who designs and builds, working with several agents, stays oriented and in control when the desktop owns the session. Three things stand between the slice-1 result and that claim. Every session still hosts one agent, and the people this is for run more than one on a goal. Every instruction so far came from me or a script; no designer has sat at the panel and run a loop by their own judgment. And every run used Claude Code on one aarch64 image.

The program answers those in order. Slice 2 puts a team of agents inside one session, measures the designer's own loop, and brings a second harness live. Slice 3 adds a second person. Slice 4 turns fan-out into structured parallelism and takes what held upstream. Federation stays out of scope throughout.

## What is settled

These are facts as of 2026-09-02, with the file that carries the evidence.

Slice 1 is live on the rig and installable from the listing repository. It is twenty commands over a Python core with 125 tests, a record per session under `~/.local/state/omarchy/sessions/<id>/` with an append-only event log and a receipt, Herdr as the runtime, a watcher that turns state changes into Omarchy notifications, the bar widget and keyboard panel, and permission modes enforced before exec (`findings/experiment-report-slice1.md`, `README.md`).

The five success signals hold on captured evidence, with signal 1 restated as capture-verified on 2026-09-02 (`findings/signal-1` to `signal-5`, `decisions.md`). The closed loop from `spec/09` runs from the terminal and from the panel: a goal, a registered preview, feedback sent with the capture it was about, commits, a verdict, every step in `show --loop` (`findings/closed-loop.md`, runs 3 and 4). A session starts from the panel with `n` (run 5). A reboot orphans sessions and Enter revives them with the harness's own transcript; the first reboot ended two sessions by mistake and the rule that fixed it has a test (run 7, `decisions.md`).

Herdr 0.8.2 is confirmed as the runtime: workspaces, tabs, panes, `agent.start`, `events.subscribe`, `worktree.create`, `pane.report_metadata` with a session id in `tokens`, `pane.close` ending processes (`spikes/herdr-on-rig.md`). Herdr reports a question and a permission prompt as one `blocked` state, restores every workspace with a fresh shell after a restart, exposes no exit status, and accepts `agent.prompt` before the harness can take it (`findings/upstream-contributions.md`).

The pattern catalog assigns twelve OpenClaw patterns to slices: delegation with visible lineage, event-driven state, live human control, outputs as collaborative objects, and the stated trust boundary in slice 1; three-layer attribution and explicit visibility in slice 2; isolated agent identities and structured parallelism in slice 3; interoperability as a boundary out of scope (`patterns/`). Slice 1 built the lineage fields, the queue with steer and followup delivery, the receipt, and the invariant that an id is a routing key and never an authorization token; it left watchers and `status --since` from pattern 06 unbuilt.

The rig is Gabriel Galán's aarch64 UTM image (`ggalancs/omarchy-arm-utm`) at Omarchy `0b3f1b7`, Claude Code 2.1.259, Codex installed without a login, OpenCode untested, software rendering. Findings from it carry the unofficial-port caveat and exclude performance and rendering judgments. `omarchy-update` on this image updates packages only; the port's own `omarchy` package is the path to a newer tree, and taking it is a snapshotted, deliberate step.

The plugin's structure matches quattro's own `agents` plugin at HEAD and passed plugins.omarchy.org's pre-share checklist under the listing id (run 6). Every text that leaves the repository goes through my editorial rules; every publication waits for my word on the exact text and target.

## Design rules carried into every slice

The session is the durable object and a terminal attaches to it. Every instruction has a named author, human or agent. Ownership assigns responsibility. Access is granted separately, and the two never merge. Agent-originated messages carry a marker that distinguishes them from a person's instructions. Shared mode requires per-operation approval. Every child session has a parent, a status, and a completion path that pushes back to the parent. Concurrent edits happen in isolated worktrees. Outputs persist as artifacts with receipts. The trust boundary is stated: one machine and one OS user is one boundary; a second person needs their own account or host, never a flag on the first person's store.

Three rules join the list from slice 1's evidence. Every automated reading carries its own confidence, and a true label beats a specific wrong one, so "needs you" stays until Herdr can tell a question from a permission prompt. A manual path exists beside every automated one: the commands do everything the panel does, and a person can always take a session over in its terminal. And nothing ends a session by inference when a person could still revive it; a state the reconciler guessed is written as a guess and stays reversible.

## The question for the program

Hypothesis H2, tested across slices 2 and 3: on Omarchy, a person who designs and builds can run a goal across several agents, and later alongside a second person, from the desktop's own surfaces, and at every moment can answer who is doing what, who needs them, what has landed, and what they approved. H1 from slice 1 stays the floor: everything H2 adds keeps the five slice-1 signals passing.

The measurement stays the Omarchy-UX protocol: usability, accessibility, and trust-and-handoff lenses, review passes with captures, scenario runs with per-signal evidence, one report per slice that separates measured outcomes from judgment calls, and one sitting per slice with a person at the rig doing the work unscripted. A failed signal is a finding with its evidence and feeds the next design pass.

## Slice 2: one person, a team of agents

**The question.** When two agents work one goal inside one session, each with its own task, does the person stay oriented and in control from the panel, and does the work land on one branch with the record showing which agent did what?

**Why first.** This is the highest-learning, most reversible step available. It tests the load-bearing assumption behind the audience claim (people run more than one agent on a goal), it reuses the lineage, queue, worktree, and receipt machinery slice 1 already verified, and everything it adds is a plugin and scripts, undoable by uninstalling. It also answers the first thing I asked for after slice 1: pull two agents into a session and give each a task.

### 2a. Agent lanes

**The model.** A session gains lanes. A lane is one agent with one task inside the session: `{lane, agent: {kind, harness_session_ref}, task, runtime, status, workspace}`. The session keeps its goal, mode, owner, and receipt; the lanes carry the agents. On disk this is the existing parent-and-child shape, so no record migrates: the session is the parent, each lane is a child session with `lineage.parent_id` set and `spawn_reason: "lane"`, and the parent's `lineage.children` lists them. The panel and the commands present the parent as one session with lanes; the record keeps every child addressable on its own, which is what the receipt, the watcher, and the reconciler already understand.

A session with no lanes is a slice-1 session, unchanged. A session's first agent is its first lane. Slice 1's depth limit of 3 and children limit of 5 apply, so a session holds at most five lanes and a lane can spawn its own children within the depth limit.

**Runtime.** Every lane runs as its own Herdr agent in its own pane inside the session's one Herdr workspace, so attaching the session shows the lanes side by side in one terminal window, and attaching a lane shows that pane alone. Herdr's `agent.start` per alias, `pane.report_metadata` with the session id and lane name in `tokens`, and `events.subscribe` give this without new runtime machinery; the spike verified each call.

**Workspaces.** Each lane gets its own worktree on a branch `session/<name>/<lane>` cut from the session branch, so two agents never edit one tree at once. When a lane ends with a verdict, its branch merges into the session branch; a clean fast-forward or merge lands as a `lane.merged` event with the commit range, and a conflict puts the lane in `blocked` with the detail "merge conflict; open the lane to resolve", which routes through the existing needs-you path. A person can opt a lane into the session's own worktree with `--share-worktree` when the tasks cannot collide, for example a copy pass and a build pass on different files, and the record says so.

**Attribution.** Commits are attributed by the lane they were made in, from the branch, at merge time, and the receipt lists them per lane. Trailers written by an agent are unverifiable, so attribution comes from the lane's worktree. A verified human identity stays a slice 3 concern, as `spec/08` reserves it.

**Instructions.** `send` addresses the session or a lane: `send <session> "<text>"` goes to every live lane by default, with `--lane <name>` for one. Each delivery records which lane received it. Feedback with a capture works per lane the way it works per session today. A lane that asks a question or hits a permission prompt is the session's needs-you, named as "<session> · <lane> needs you" on the toast, the badge, the hero, and the row.

**Commands.** Four additions to the surface:

- `omarchy-agent-session-add <session> --agent <kind> --task "<text>"` pulls a second agent in; the parent must be live or orphaned.
- `omarchy-agent-session-lanes <session>` lists lanes with state, task, worktree, and last event.
- `omarchy-agent-session-open <session> --lane <name>` attaches one lane's pane.
- `omarchy-agent-session-done <session> --lane <name> --verdict kept|dropped` ends one lane and merges or discards it.

`stop` on a session stops its lanes unless `--keep-lanes`. `show --loop` and the receipt render lanes as sections. `list --json` carries `lanes: [{lane, kind, state, task}]` for the panel.

**The panel.** A session row with lanes gains one line per lane under the goal: dot, lane name, agent kind, state, the task elided. The cursor moves across sessions as today; `l` cycles the cursor through a session's lanes so Enter, `s`, `x`, and `p` act on a lane; the legend shows "l lane" only when the cursor row has lanes. A new key, `a`, on a live session opens a field "Add an agent: <kind> <task>" with the default agent prefilled, mirroring the `n` field. The hero counts lanes that need you across sessions. Needs-you ranking names the lane. Nothing in the collapsed row grows: a session with lanes is one row until the cursor is on it, which keeps signal 1 intact.

**Permissions.** A lane inherits the session's mode and may be stricter, never looser: a Personal session can hold a Shared lane, a Shared session cannot hold a Personal one. The deny-list check runs per lane before exec, and signal 5's rule extends to every lane.

**Notifications.** The watcher already tails every session record, and lanes are records, so lane states arrive with no new plumbing. Two changes: the toast names the lane, and a lane ending routes `child.completed` into the parent's queue as the session model already specifies, so the parent's own agent, when it has one, learns that a lane finished.

**Harness pairing.** The first proof uses two Claude Code lanes, because that path is verified end to end. The second proof uses Codex as the second lane, which needs the Codex login on the rig (mine to do) and its permission-mode flags verified live; `--approve-for-me` is unverified against the vendor's current reference and the table marks it. OpenCode stays the fallback.

**Success signals, measured on the rig with captures.**

1. From a live session, a second agent with its own task is pulled in from the panel with the `a` field and nothing else; its lane appears in the row on the next poll and its terminal pane sits beside the first in the session's workspace.
2. Each lane's state and task are visible on the cursor row, and a lane that asks a question is named first on the toast, the badge, the hero, and the row, with the lane's name in the text.
3. Both lanes' commits land on the session branch through `done --lane`, the receipt lists commits per lane, and a forced conflict shows as a `blocked` lane with the merge-conflict detail and never as silent loss.
4. `send` with `--lane` reaches one lane and the record shows which; `send` without it reaches every live lane and records each delivery.
5. Every slice-1 signal still passes on a session with lanes: survival across terminal close and reboot for every lane, a receipt with every lane, notifications for every lane, no bypass flag on any lane outside Personal.

**Limit and review point.** Four working days: one for `spec/11-agent-lanes.md` with mockups over the real bar, one and a half for the core and its tests, one for the panel, half for the runs and the findings. Review at the end: if signals 1, 2, and 3 hold with two Claude lanes, the Codex lane proof follows inside 2c; if they do not, the findings decide whether lanes stay as separate workspaces (the fallback) or the model changes.

### 2b. The designer's loop, measured

**The question.** Does a designer's situated judgment survive the surfaces? Every loop so far was pre-written or scripted. `spec/09` section 8 asks for one sitting: me as the designer, one goal, three rounds of feedback typed into the panel's Send field while looking at the preview, a verdict, and the loop view and receipt showing every step with no gap.

**What it adds.** The sitting itself, before any lane work lands, so the measurement is of slice 1 as shipped. Then the two open items from `findings/closed-loop.md`: previews registered as an app id (a native window found by class, untested), and design artifacts as links (`artifact-add --kind url` for a Figma or Paper frame, shown in the loop view and the receipt). Then the `live` relabeling of a capture as a command, replacing today's sidecar edit. Then the same sitting again with a two-lane session, once 2a lands, which is the measurement H2 needs.

**Success signals.** The sitting completes with three feedback rounds sent from the panel, each with the capture it was about. The loop view and the receipt show every step in order. The designer, me first and then one person who is not me, answers four questions from the panel alone: who is doing what, who needs me, what landed, what did I approve. The answers are recorded with the panel open and checked against the record.

**Limit.** Two working days plus one sitting of an hour with a second person, who I recruit from people who design and build and who has never seen the rig; their session is a hands-on capture with consent, and the report separates their words from my reading of them.

### 2c. The second harness, the picker, and the x86 rig

**The question.** Does the session model hold for a harness that is not Claude Code, on hardware the project does not caveat?

**What it adds.**

- Codex live in a lane and in a session of its own: login on the rig, permission flags verified against the vendor's reference, resume verified through the `RESUME_FLAGS` table.
- OpenCode the same, if Codex's login is blocked.
- One session created through the agent picker, which closes signal 5's flag.
- The x86-64 rig, either the cloud rig from v2 or Omarchy on a spare machine, running the same scenario so the port caveat drops from the findings.

**Success signals.** A Codex session passes signals 2, 3, and 5 (survival, receipt, no bypass); `blocked` and `done` for Codex arrive as notifications; the x86 run of the slice-1 scenario passes all five signals with the same captures, and any difference from the aarch64 run is a finding.

**Limit.** One and a half working days once the login and the x86 machine exist; those two are mine and gate the start.

### 2d. Event-driven state, finished

**The question.** Can a session react to another session's events without polling, which slice 3's second person and slice 4's fan-out both need?

**What it adds.** Pattern 06's `watchers` list on the session record, seeded on spawn and settable with `omarchy-agent-session-watch-events <id> --for <other>`, one coalesced pending instruction per watcher after each append, and `status --since <seq>` reading forward from `events.jsonl`. Log rotation is decided here: a bound like OpenClaw's, or an archive per session on `done`, with the receipt unaffected.

**Success signals.** A parent session receives one marked instruction when its lane completes and none while the lane works; `status --since` returns exactly the events after the cursor across a hundred appends; the tests cover both.

**Limit.** One working day.

### Slice 2 review

The slice ends with a report in the shape of slice 1's: bottom line, evidence per signal, the defect list, judgment calls, what it cannot claim. Keepalive ships as 0.2.0 from the same listing repository through the marketplace's newer-commit verification form, and the discussion post gets a follow-up comment with the lanes result. Gate: every signal has a capture; the second person's sitting happened; the report separates measured outcomes from judgment.

## Slice 3: two people

**The question.** When a second person joins a session, from another OS account on the same machine or from another host, can both see the session, can the second person suggest and the owner decide, and does the record keep every action attributed and every approval visible?

**Why second.** It tests the pattern catalog's slice-2 items (three-layer attribution, explicit visibility and drafts, suggest versus start) and the identity shape `spec/08` reserved, and it is where the trust boundary stops being a sentence and becomes a design. It is less reversible than slice 2 because identity choices harden: an actor string that reaches a receipt or a commit trailer is hard to rename later, which is why the identity space is decided first, with a reversible proxy.

**The identity decision, first.** Two candidates for the second identity space, tested in order. First, the Mac watching the VM over Herdr's `--remote`: cheap, already close, and it answers whether a remote viewer works at all; the second identity is `human:<user>@<mac-host>`, unverified. Second, a second OS account on the same machine, which is the trust boundary the spec names for people who share a box. GitHub-verified profiles (`profile`, `verified_at`) are the third step and only after one of the first two holds. The decision is recorded in `decisions.md` with the evidence from the proxy.

**What it adds.**

- `visibility` (`private`, `draft`, `shared`) with a `session.visibility_changed` event.
- `access` as a list of `{actor, level}` with `view`, `suggest`, `contribute`, `own`, kept distinct from `owner`.
- Suggested instructions, written with `delivery: "suggested"`, that sit until the owner accepts or dismisses them; each acceptance is an event naming who approved what.
- Presence, in memory only: the panel shows who has a terminal or a panel on the session, and nothing is written to the record.
- `assign` with meaning: notifications route to the owner by default.
- A panel that filters drafts out of everyone's view but the creator's.
- The reconciler and the watcher running per account, with the sessions directory's permissions audited before a second account exists.

**Success signals.**

1. The second person sees every `shared` session and no `draft` session from their surface, verified by capture on both sides.
2. A suggestion from the second person appears to the owner as "<name> suggests…", runs only after the owner accepts, and the record shows the suggestion, the acceptance, and the delivery as three attributed events.
3. Assignment moves the needs-you notification to the new owner and nothing else; the previous owner's access is unchanged, verified by attempting the same actions before and after.
4. Presence shows the second person on the session while their terminal is attached and disappears when it closes, with nothing written to `session.json` or `events.jsonl`.
5. Every slice-1 and slice-2 signal still passes for the owner.

**Limit and review point.** Six to eight working days: two for the proxy and the identity decision, two for the record and commands, two for the panel and the second surface, one to two for the sitting with a second person and the report. Review at the end decides whether verified profiles and commit trailers are worth a slice of their own.

## Slice 4: teams of agents, and upstream

**The question.** When a session fans out to several agents at once, does the structure hold (caps, lineage, results) without the person losing the thread, and which parts of this belong in Omarchy itself?

**What it adds.** Herdr's `hsl` fan-out treated as spawning: lanes created together from one instruction, each naming the parent, the caps enforced at creation, the parent idle or working first. A results contract that stays honest about what harnesses can do: a `receipt.json` per lane and a merged receipt, with a typed payload only when a harness can produce one on request. Isolated agent identities as the separate-agents pattern: a session declares which credential context it launches into, recorded in `started_with` and shown on the receipt, so switching agents is a different identity. And the upstream path, which is where the discussion's answer lands: a pull request for `omarchy-agent` writing a session record on launch, a proposal for a first-party sessions widget or room in the `agents` plugin, and the script findings filed as issues.

**Success signals.** A fan-out of three lanes from one instruction lands three receipts and one merged receipt with per-lane attribution; the caps refuse a sixth lane and a fourth depth with a clear message; a credential context named on `new` shows on the receipt and differs between two lanes of different kinds; and the upstream items each have a recorded outcome in `findings/upstream-contributions.md`.

**Limit.** Five working days for the build; the upstream track runs on the maintainers' clock and stays behind my per-text approval.

**Out of scope, still.** A2A-style federation, hostile multi-tenancy, live design-tool sync, and any change to Omarchy core outside the pull request path.

## Tracks that run across the slices

**Upstream and community.** Six issue texts are drafted in `outbound/upstream-candidates.md`; I pick which go and where. The discussion gets a reply from me to every substantive answer within a day, drafted by Claude and approved by me. The marketplace listing moves through validation and a maintainer's review; a `review-required` baseline with the installer and service-management capabilities is the expected path for a plugin with user units, and any finding it names gets fixed in a new commit before publication. Each slice that changes the plugin ships a new Keepalive version through the marketplace's newer-commit form, with the changelog in the listing repository.

**Evaluation discipline.** Captures follow the Omarchy-UX rules: provenance, version, date, environment, and the `proposed` or `live` label. Every run gets a directory under `captures/` with its timeline, records, and captures cropped to what the evidence needs; full screens with my own work on them are cropped before they are committed. Every slice gets `/ux-review` and `/design-qa` passes on the live build before its sitting, and a report that separates measured outcomes from judgment calls. Findings from the aarch64 rig keep the port caveat until the x86 run exists.

**Rig and platform.** The rig stays on `0b3f1b7` until the port's `omarchy` package is installed as a deliberate, snapshotted step, with the plugin re-run through the pre-share checklist afterwards. Claude Code moves with mise; Herdr's version is recorded in every run. The x86 rig arrives in 2c. The keyring prompt and the stale toasts on the rig are housekeeping I do at the rig.

**Keepalive maintenance.** Keepalive is a build output of this repository, never a second codebase. `outbound/build-listing.sh` assembles the listing repository (`mphaxise/omarchy-keepalive`) from `plugin/`, `bin/`, `systemd/`, `tests/`, and `outbound/listing/`; that is what the rig installs and what users get, and its `SOURCE` file names the dev commit it came from. `main` is what ships. Slice work lives on branches (`slice-2/lanes`, `slice-2/sitting`, and so on) and merges into `main` when its signals pass, so a hotfix never carries half-built work. Each release is `outbound/release-keepalive.sh <version>`: tests pass, the manifest version bumps, the dev commit is tagged `keepalive-v<version>`, the build lands as one commit on a clone of the listing repository at `~/Work/omarchy-keepalive`, and the script prints the two pushes and the marketplace's newer-commit form as the next steps, each on my word. 0.1.0 is tagged at `ea2bc08`; 0.2.0 follows 2a; 0.3.0 follows slice 2's review. A bug reported against the listing is reproduced on the rig, fixed on `main` with a test, and released through the same script, in that order; a fix that cannot wait for a slice branch to merge is a patch release from `main` on its own.

**Writing.** Every outward text, the reports, the listing README, the discussion replies, the issue texts, goes through my editorial rules before it leaves. Internal notes keep their timestamps and their provenance.

## Decisions I own

Each has my proposed default, so work can start without waiting; a different answer changes the plan where noted.

1. **Lanes run as panes in one Herdr workspace** (default) or as separate workspaces. Panes give one terminal window with the lanes side by side and match Herdr's own layouts; separate workspaces are the fallback if pane-level status reporting turns out unreliable for two agents at once.
2. **Lanes isolate by default** in their own worktrees, with `--share-worktree` as the explicit exception. The alternative, shared by default, would trade the design rule for convenience and I would rather learn where isolation hurts first.
3. **The first lane proof uses two Claude Code lanes**; the Codex lane follows once I log Codex in on the rig. Codex login is mine to do.
4. **The designer sitting happens before 2a's build starts**, so slice 1 is measured as shipped; it costs an hour and its findings shape the lane panel. If I would rather build first, 2b's sitting measures the two-lane session only.
5. **The second person for 2b's sitting** comes from people I know who design and build; the recruiting message is mine to send.
6. **The x86 rig**: the cloud rig from v2, or a spare machine with Omarchy installed. Either works for 2c; the spare machine also answers the installer questions this rig cannot.
7. **Slice 3's identity space** starts with the Mac watching the VM over Herdr `--remote` as the proxy, then a second OS account. Reversing the order is fine if a second account is easier to arrange on the rig.
8. **The Omarchy tree on the rig**: stay on `0b3f1b7` through slice 2, or install the port's `omarchy` package before 2a so the plugin is tested against a newer shell. My default is to stay until the marketplace review lands, then update with a snapshot first.
9. **Which upstream issue texts go**, and whether the aarch64 ones go to the image repository (`ggalancs/omarchy-arm-utm`) or the package repository (`omarchy-mac/omarchy-pkgs-aarch64`).
10. **A name for the room.** "Lane" is my working word for one agent's task inside a session; if a better word comes out of the sitting, it changes before 0.2.0 ships, because names in the panel and the commands harden with the listing.

## Risks

The panel's row budget. A session with five lanes is six lines on the cursor row; if the panel cannot hold two such sessions with the hero and the legend at 640 px, the lane lines collapse to a count and expand on `l`. The mockup in `spec/11` tests this before the build.

Herdr's status detection with two agents in one workspace. The spike verified `pane.agent_status_changed` for one pane; two agents in two panes is untested, and if Herdr's manifest detection reads the wrong pane, lanes fall back to separate workspaces (decision 1).

Merge conflicts as a design problem. A lane blocked on a conflict needs a person in a terminal with git; the panel names it, and the receipt records it, but slice 2 does not resolve conflicts from the panel. Whether that is acceptable for the audience is a finding from the sitting.

Harness drift. Claude Code's permission modes changed in 2026 and Codex's flags differ from Omarchy's table; the deny-list runs per lane and every unverified flag stays marked. A drifted flag that reopens bypass mode fails signal 5 and blocks the slice.

Identity hardening in slice 3. An actor string that reaches a receipt is hard to rename; the proxy-first order exists so the second identity space is chosen on evidence, and profiles and trailers wait for a slice of their own.

Upstream appetite. The discussion may draw no reply, as the two earlier ones did. The plugin path keeps every slice installable without upstream consent. The upstream track never gates a slice.

My time at the rig. The sittings, the Codex login, the x86 machine, and the recruiting message are the steps only I can take; each is named in the decisions above so a slice never waits on one silently.

## Calendar

Working days, sequential, with review points: slice 2 about nine (2b's first sitting, then 2a four, 2b two, 2c one and a half, 2d one) plus the review; slice 3 six to eight; slice 4 five plus the upstream clock. About twenty working days of build across the three slices, on top of the days already spent. Each slice ends with a report and a Keepalive release, and the program stops or turns at any review point where the evidence says the model is wrong.

## Repository layout, additions

```
spec/11-agent-lanes.md              slice 2a: the lane model, commands, panel, worktrees, attribution
spec/12-two-people.md               slice 3: identity space, visibility, access, suggestions, presence
spec/13-structured-parallelism.md   slice 4: fan-out as spawning, results contract, credential contexts
findings/experiment-report-slice2.md, slice3, slice4
captures/evaluation-run9-lanes_…/   one directory per run, as today
outbound/                           the listing build, the texts that go out, per slice
```
