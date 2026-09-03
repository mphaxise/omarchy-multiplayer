# Discussion post draft: omacom/omarchy

Target: GitHub Discussions on `omacom/omarchy`, the category the maintainers use for ideas or show-and-tell (check the live category list before posting). Status: draft, 2026-09-02. Praneet approves the exact text and the target before it is posted. The repository links assume both repos are public by then.

---

**Title:** Durable, named agent sessions on Omarchy: a plugin, a session record on top of Herdr, and what two days of measuring it found

I built a session layer for coding agents on Omarchy and spent two days measuring it on the aarch64 port. It is a user plugin plus twenty small commands, and it is public at [mphaxise/omarchy-agent-sessions](https://github.com/mphaxise/omarchy-agent-sessions) with the specs, the evaluation runs, and the captures in [mphaxise/omarchy-multiplayer](https://github.com/mphaxise/omarchy-multiplayer). I am posting because three of the pieces might belong in Omarchy itself, and I want the maintainers' read before I build further.

**What it does.** A session is a named, durable record: a directory under `~/.local/state/omarchy/sessions/<id>/` with an append-only event log, a goal, a git worktree on a `session/<name>` branch, a permission mode, and a receipt when it ends. Herdr keeps the agent process alive, so the session survives every terminal closing, and after a reboot it comes back as `orphaned` with a revive path. A bar widget shows who needs you, who is working, what finished today; the panel is keyboard-first (Enter to answer, `s` to send, `x` twice to stop). A watcher turns state changes into Omarchy notifications through `omarchy-notification-send`, so "api-refactor needs you" arrives as a toast whose click opens the terminal. Permission modes (Personal, Shared, Restricted) are enforced by a deny-list before exec, and a launch outside Personal never carries a bypass flag.

**What I measured.** Five signals, on the rig, with captures: sessions survive every window closing and a reboot (harness pids and transcripts identical before and after); receipts carry the branch, commits, diff stat, artifacts, and verdict; `blocked`, `done`, and `failed` each raised a toast within a second of the event through Herdr's event subscription; the waiting session is the first thing named on the toast, the badge, the hero, and the first row; and no launch outside Personal carried a bypass flag. Two review passes and four scenario runs found twenty-six defects in a slice that passed every happy path. Most are fixed and have tests, and each one is written up with its evidence.

**What might belong upstream.** Three things, least certain first:

1. `omarchy-agent` writing a session record when it launches the terminal. The keybinding already launches Herdr; a record beside it costs one directory and makes the crash toast, the receipt, and a revive path possible. I carry this as a proposed change to `omarchy-agent` and `omarchy-agent-prompt` in the repo, diffed against quattro, and have run it on the rig since the first day.
2. A first-party `sessions` widget, or a place in the `agents` plugin for what this panel shows: needs-you first, orphaned disclosed, done today collapsed. The rendering rules came out of `/ux-review` and `/design-qa` passes on the live build and are documented per state.
3. Two small script findings: `omarchy-restart-shell` reports failure after two seconds while the shell is still coming up on a slow machine, and `omarchy-launch-tui` blocks its caller until the terminal exits, which surprises any script that uses it as a launcher. I will file both as issues if you want them.

**What I am asking.** Whether a durable session object is something Omarchy wants to own, or something it wants to leave to plugins. Either answer changes what I build next: as a plugin I would keep the record format and the commands as they are and keep the marketplace listing current; as an upstream direction I would rework the proposed `omarchy-agent` change into a pull request with the tests. Happy to be told the shape is wrong.

One limit: everything above ran with Claude Code on the community aarch64 UTM image. The other agents have their permission-mode tables and no live run yet, and x86 is untested.

---

Notes for Praneet before posting: replace "two days" with the actual span if the post goes out later; confirm the two repository names; decide whether to name the aarch64 port's maintainer or leave it as "the community aarch64 UTM image"; the numbers (five signals, twenty-six defects, four runs) are from `findings/experiment-report-slice1.md` and `findings/closed-loop.md` as of 2026-09-02.
