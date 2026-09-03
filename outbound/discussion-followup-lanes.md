# Follow-up comment draft: omacom/omarchy#9936

Target: a comment on the existing discussion `omacom/omarchy#9936` (Show and tell), the follow-up `PLAN.md` slice 2 promises "with the lanes result". Status: posted 2026-09-03 13:34 PDT on Praneet's "go to it", after the 0.2.0 pushes: https://github.com/omacom/omarchy/discussions/9936#discussioncomment-18276067. The text below is what went out. The dev-repo links assume `main` is pushed.

---

A follow-up with what changed since I posted.

**Lanes.** A session can now hold more than one agent. `a` on the panel pulls a second agent in with its own task; it runs as a second pane in the session's Herdr workspace, on its own worktree cut from the session branch. `done --lane <name> --verdict kept` merges the lane's commits onto the session branch and the receipt lists commits per lane. A merge conflict shows up as a blocked lane ("copy needs you") on the toast, the badge, and the row, with both trees left as they were. I ran it on the rig with two Claude Code lanes on one page: one merged, one conflicted on purpose, both survived shell restarts. Evidence: [`findings/evaluation-run9-lanes-2026-09-03.md`](https://github.com/mphaxise/omarchy-multiplayer/blob/main/findings/evaluation-run9-lanes-2026-09-03.md). This ships as Keepalive 0.2.0 ([`keepalive-v0.2.0`](https://github.com/mphaxise/omarchy-multiplayer/releases/tag/keepalive-v0.2.0)).

**Two things Herdr taught me, in case they help anyone else.** Two agents in one workspace report their states separately, so a lane going `blocked` while main stays `idle` reads right. And workspace ids are reused after a server restart, so anything that remembers a workspace id from before the restart can match the wrong workspace afterwards; I now match panes by a token I set with `pane.report_metadata`.

**A second person, in proxy form.** A session has a visibility (`draft` stays yours, `shared` is visible), an access list (`view`, `suggest`, `contribute`, `own`), and suggestions: someone with `suggest` proposes an instruction, it waits on the owner's panel as `<name> suggests …`, and `y` runs it under the suggester's name. I tested it with my Mac as the second person over ssh, which is a proxy for a second account and claims nothing about isolation. Evidence: [`findings/evaluation-run10-two-people-2026-09-03.md`](https://github.com/mphaxise/omarchy-multiplayer/blob/main/findings/evaluation-run10-two-people-2026-09-03.md).

The upstream question from the first post stands: whether `omarchy-agent` should write a session record on launch, and whether a sessions room belongs in the `agents` plugin. I would still rather hear a no early than build against the grain.
