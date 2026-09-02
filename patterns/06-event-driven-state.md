---
pattern: Event-driven state
source: https://docs.openclaw.ai/concepts/session-state.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: Herdr runtime
slice: 1
---

# Event-driven state

## What OpenClaw does

Every session keeps a durable, typed signal log recording eight kinds of change: a direct human message, a missing upstream, a goal change, a spawned child, a completed run, a failed run, a compaction, and an adoption. The first three notify watchers; the rest are logged for reconciliation only. A session's state version is just the highest sequence number in its own log. Watchers hold a cursor on a target, seeded automatically when a session spawns a child, or set explicitly with `sessions_send watch: true`, starting from the target's current version so old history never produces noise. The anti-spam contract is exact: one pending notice per watcher and target pair, a frozen watermark while a notice is pending, and self-suppression so a watcher is never notified about its own actions. After a crash, pending notices re-materialize from durable cursors instead of being lost. Reconciliation is pull-based: `session_status` with `changesSince: <version>` returns the typed events after that point, and a `historyGap: true` flag tells a watcher whose target predates retained history to refresh wholesale instead of trusting a partial delta.

## What Omarchy has today

`spec/01-session-model.md` already specifies almost this exact shape as `events.jsonl`: append-only, one object per line, a monotonic `seq` that `state_version` mirrors, and a matching event-type table. The binding-to-Herdr section already plans to subscribe to Herdr's `pane.agent_status_changed` and translate it into `status.changed` entries. What is missing is everything downstream of the log itself: no watcher or cursor concept, no de-duplication rule, and no `changesSince`-style call for a reader that fell behind.

## What porting it means

Add a small `watchers` list, `{watcher_session_id, cursor}`, seeded automatically whenever `lineage.parent_id` is set, the same implicit watch OpenClaw gives every spawn for free, and settable explicitly for any other reader. After each append to `events.jsonl`, check watcher cursors against the new `seq` and enqueue at most one pending instruction per watcher, reusing the `instruction.queued` event and `queue` field the schema already has, so no new delivery path is needed, only the coalescing rule. `session status --since <seq>` is the direct port of `changesSince`, reading forward from `events.jsonl` at an offset. This belongs in slice 1 because the log is already load-bearing for the panel and the receipt, and watchers are cheap to add now and expensive to retrofit once every consumer has invented its own polling loop.

## Open questions

- Does `events.jsonl` need rotation to match OpenClaw's 30-day, 50,000-row bound, or can slice 1 assume small files?
- Is the panel itself an implicit watcher of every visible session, or does it read `status` directly and leave watchers to parent-child coordination?
- What counts as self-suppression when the reconciler, not a session, is doing the notifying?

## Sources

- Session state awareness, https://docs.openclaw.ai/concepts/session-state.md, observed 2026-09-01
