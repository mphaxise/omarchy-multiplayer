---
pattern: Outputs as collaborative objects
source: https://docs.openclaw.ai/web/dashboards.md, https://docs.openclaw.ai/web/dashboard-architecture.md, https://docs.openclaw.ai/concepts/managed-worktrees.md, https://docs.openclaw.ai/concepts/user-model.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: worktrees
slice: 1
---

# Outputs as collaborative objects

## What OpenClaw does

A dashboard is documented as a second face of the session object, not a separate thing: every thread has a transcript face and a board face, with no separate creation call and no separate access-control model for it. Boards survive `/new` and `/reset`, only the conversation clears, and are deleted only when the session itself is deleted, so output persistence tracks the session's own lifecycle instead of a chat retention policy. Managed worktrees get the same treatment on the filesystem side: a worktree is only removed when its status is clean and every commit is pushed, and even then removal snapshots tracked and non-ignored untracked content first, to a ref restorable for 30 days, so dirty or unpushed work is never silently discarded. On attribution, a verified identity gets an exact co-author trailer carried through amendments and rebases, and a brokered pull request ends with a link back to the exact session that produced it, so the output points back at the record that made it.

## What Omarchy has today

`receipt.json` in the session model is the direct equivalent for the half of this pattern about pointing back at the session: workspace, branch, commits since base, diff stat, dirty and unpushed flags, artifacts, and the exact launch command, written at the end and refreshed at checkpoints so a crash still leaves something. This already answers `PLAN.md` success signal 3. Omarchy has nothing like the dashboard half, a persistent interactive face other viewers see live, since the panel reads static JSON and Herdr's pane is a live terminal, not a structured artifact.

## What porting it means

For slice 1 this pattern is scoped to the receipt, and `receipt.json` already is that port. The design principle worth taking explicitly is that an output belongs to the session and stays addressable after the session ends, not a transient message. One real gap: OpenClaw's cleanup rule, never discard dirty or unpushed work, snapshot first, is stricter than what the spec's `workspace` field currently guarantees; it records paths but does not yet require a status check before a worktree is ever removed. That check belongs wherever eventually calls `gd` on behalf of a finished session, so a receipt cannot outlive the work it describes. The dashboard half stays out of scope; Omarchy has no widget-hosting runtime and none of the five success signals need one yet.

## Open questions

- Should `gd` refuse to run against a session's worktree unless `status` is done, failed, or stopped, matching OpenClaw's finish-then-snapshot-then-remove order?
- Does `receipt.json`'s `artifacts` list need size caps the way board widgets do, or is that moot without a hosting runtime?
- Is 30 days the right snapshot window for a single-user machine, or should it be longer?

## Sources

- Session Dashboards, https://docs.openclaw.ai/web/dashboards.md, observed 2026-09-01
- Dashboard Architecture, https://docs.openclaw.ai/web/dashboard-architecture.md, observed 2026-09-01
- Managed worktrees, https://docs.openclaw.ai/concepts/managed-worktrees.md, observed 2026-09-01
- User model, https://docs.openclaw.ai/concepts/user-model.md, observed 2026-09-01
