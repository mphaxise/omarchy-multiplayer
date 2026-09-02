---
pattern: Live human control
source: https://docs.openclaw.ai/concepts/queue.md, https://docs.openclaw.ai/concepts/queue-steering.md, https://docs.openclaw.ai/tools/steer.md, https://docs.openclaw.ai/tools/ask-user.md, https://docs.openclaw.ai/tools/goal.md, https://docs.openclaw.ai/concepts/managed-worktrees.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: none yet
slice: 1
---

# Live human control

## What OpenClaw does

Four queue modes govern a new instruction arriving mid-run, set per session with `/queue <mode>`: steer, the default, injects the message at the next safe boundary; followup waits and runs it after; collect coalesces several queued messages after a debounce window; interrupt aborts the active run and starts the new message immediately. The steering boundary is precise: a running tool call finishes, calls that have not started are skipped with a synthetic result so the transcript stays valid, and a parallel batch has one atomic launch point, before it cancels the whole batch, after it cancels none of it. The explicit `/steer <message>` command differs from `/queue steer` by trying to inject this one message now, regardless of the session's stored mode. Separately, `ask_user` pauses for a genuinely user-owned decision, one to three questions, two to four options plus an always-available free-text answer, a 900-second default timeout, and the model is told not to use it to confirm its own plan. A durable goal adds a slower control layer: an operator can pause, resume, or clear it, but the model can only report it complete or blocked. `suggest_task` is the sibling to actually starting work: an agent proposes follow-up work, and a human picks "Start in worktree" or dismisses it, two different actions with two different affordances.

## What Omarchy has today

Nothing at this layer. `omarchy-agent-prompt` passes a prompt at launch, but there is no way to steer a session already mid-task, no queue, and no interrupt distinct from killing the pane. Herdr's states show that a session needs input but supply no delivery mechanism beyond typing into the attached terminal.

## What porting it means

The session model already has a `queue` field and an instruction shape with `delivery: "steer" | "followup"`. The slice 1 port is `omarchy session tell <id> "<text>" --mode steer|followup`, appending to `queue` and emitting `instruction.queued`, delivered through Herdr's own input-send primitive; interrupt maps to `session stop` plus a resume carrying the new instruction. The `waiting` and `blocked` states already in the state machine are exactly `ask_user`'s two purposes. Suggest-versus-start is explicitly slice 2, since it needs a second human for proposing and starting to be meaningfully different actions.

## Open questions

- Can any of the eleven harnesses accept a mid-run steer over tmux send-keys without corrupting their input buffer?
- Does `session stop` need a `--and-tell` combinator, or is stop-then-tell acceptable?
- Once slice 2 adds a second human, does suggest need its own event type, or does a flag on the existing instruction shape carry it?

## Sources

- Command queue, https://docs.openclaw.ai/concepts/queue.md, observed 2026-09-01
- Steering queue, https://docs.openclaw.ai/concepts/queue-steering.md, observed 2026-09-01
- Steer, https://docs.openclaw.ai/tools/steer.md, observed 2026-09-01
- Ask user, https://docs.openclaw.ai/tools/ask-user.md, observed 2026-09-01
- Goal, https://docs.openclaw.ai/tools/goal.md, observed 2026-09-01
- Managed worktrees, https://docs.openclaw.ai/concepts/managed-worktrees.md, observed 2026-09-01
