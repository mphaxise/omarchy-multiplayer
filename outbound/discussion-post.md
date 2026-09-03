# Discussion post draft: omacom/omarchy

Target: GitHub Discussions on `omacom/omarchy`, category **Show and tell** (the live categories on 2026-09-02: General, Ideas, Manual, Polls, Q&A, Show and tell, Suggestions, Support; Ideas is the alternative if the ask matters more than the build). Status: draft, 2026-09-02. Praneet approves the exact text and the target before it is posted. The links assume both repos are public by then.

---

**Title:** Keepalive: coding agents that stay running on the Omarchy desktop. Should any of it live upstream?

I built Keepalive, a session layer for coding agents on Omarchy. It is a user plugin plus twenty small commands. I spent two days testing it on the aarch64 port. The plugin is at [mphaxise/omarchy-keepalive](https://github.com/mphaxise/omarchy-keepalive). The specs, test runs, and screenshots are at [mphaxise/omarchy-multiplayer](https://github.com/mphaxise/omarchy-multiplayer).

I am posting because three pieces might belong in Omarchy itself. I want your read before I build more.

**What it does**

A session is a named record that survives. Each one is a folder under `~/.local/state/omarchy/sessions/<id>/`. The folder holds a log of every event, a goal, a git worktree on its own branch, and a permission mode. When the session ends, it gets a receipt. Herdr keeps the agent process alive. Close every terminal and the session is still there. Reboot and it comes back as `orphaned`, one keypress from revived.

A bar widget shows who needs you, who is working, and what finished today. The panel works from the keyboard: Enter to answer, `s` to send, `x` twice to stop. A watcher turns state changes into Omarchy notifications. "api-refactor needs you" shows up as a toast. Click it and the terminal opens.

Permission modes (Personal, Shared, Restricted) are checked before the agent starts. Only Personal can skip prompts.

**What I measured**

Five checks, on the rig, with screenshots:

1. Close every window, then reboot. Sessions survive. Same process ids and same transcripts before and after.
2. Receipts carry the branch, commits, diff, artifacts, and verdict.
3. `blocked`, `done`, and `failed` each raise a toast within a second, through Herdr's event stream.
4. The session that needs you is named first on the toast, the badge, the panel header, and the first row.
5. No launch outside Personal mode carries a bypass flag.

Two review passes and four test runs found 26 defects. Most are fixed and have tests. Each one is written up with its evidence.

**What might belong upstream**

Least certain first:

1. `omarchy-agent` could write a session record when it opens the terminal. It already launches Herdr. A record next to it costs one folder and makes the crash toast, the receipt, and the revive path possible. I have this as a proposed change to `omarchy-agent` and `omarchy-agent-prompt`, diffed against quattro, running on my rig.
2. A first-party sessions widget, or room in the `agents` plugin for what this panel shows: needs-you first, orphaned shown, done-today collapsed. The rules came from `/ux-review` and `/design-qa` passes on the live build.
3. Two script findings. `omarchy-restart-shell` reports failure after two seconds while the shell is still starting on a slow machine. `omarchy-launch-tui` blocks until the terminal closes, which surprises scripts that use it as a launcher. I can file both as issues.

**What I am asking**

Does Omarchy want to own a durable session object, or leave it to plugins? Either answer works for me. As a plugin, I keep the record format and the commands as they are and keep the marketplace listing current. As an upstream direction, I turn the `omarchy-agent` change into a pull request with tests. If the shape is wrong, tell me.

One limit: everything ran with Claude Code on the community aarch64 UTM image. The other agents have permission tables and no live run. x86 is untested.

---

Notes for Praneet before posting: replace "two days" with the real span if the post goes out later; confirm the two repo names; decide whether to name the aarch64 port's maintainer or keep "the community aarch64 UTM image"; the numbers (five checks, 26 defects, four runs) come from `findings/experiment-report-slice1.md` and `findings/closed-loop.md` as of 2026-09-02.
