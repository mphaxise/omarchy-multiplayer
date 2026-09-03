# Agent Sessions for Omarchy

Durable, named coding-agent sessions in the Omarchy bar. Each session survives its terminal window closing and a reboot, shows its state in a panel (who needs you, who is working, what finished today, what got orphaned), reaches you as a notification when it needs an answer, and leaves a receipt when it ends: the branch, the commits, the diff, the artifacts, the verdict.

![The Agent Sessions panel with one session that needs an answer](preview.png)

Herdr, Omarchy's agent runtime, keeps the agent process alive. This plugin keeps the record: a directory per session under `~/.local/state/omarchy/sessions/` with an append-only event log, so every surface reads the same facts.

## What you get

A bar widget: a robot glyph that turns urgent with a badge when a session needs you, and a panel behind it with keyboard control (arrows, Enter to open or answer, `s` to send an instruction, `x` twice to stop, `r` for the receipt, `p` to focus a session's preview).

Twenty commands, all `omarchy-agent-session-<verb>`: `new`, `list`, `show`, `open`, `send`, `stop`, `done`, `rename`, `assign`, `goal`, `mode`, `preview`, `capture`, `artifact-add`, `log`, `receipt`, `reconcile`, `watch`, plus the `omarchy-agent-session` dispatcher and the Python core. `omarchy-agent-session-new --agent claude --goal "..."` creates a session on a git worktree and starts the agent in Herdr; `open` attaches a terminal; `send` delivers an instruction, with `--with-capture` to attach a capture of the session's preview window.

A watcher (a user unit) that turns state changes into Omarchy notifications: "<name> needs you" when the agent asks a question or a permission, a low-urgency "finished" whose click opens the receipt, and "stopped unexpectedly" with a revive path when Herdr loses the process.

Three permission modes, enforced before exec: Personal (the agent's own no-prompt mode), Shared (the agent asks before acting), Restricted (read-only tools). No session launches with a bypass flag outside Personal.

## Requirements

Omarchy Quattro (4.0.x). Tested on the community aarch64 UTM port at `0b3f1b7`; x86 is untested. Herdr (installed with Omarchy), `python3` 3.11 or later, `grim` and `hyprctl` (both in Omarchy) for captures and preview focus, and a coding agent Omarchy knows. Claude Code is the agent every test ran with. Codex, OpenCode, and the others have permission-mode tables and no live run yet.

## Install

```bash
omarchy plugin add https://github.com/mphaxise/omarchy-agent-sessions --enable
~/.config/omarchy/plugins/@PLUGIN_ID@/install.sh
```

`omarchy plugin add` clones this repository into `~/.config/omarchy/plugins/@PLUGIN_ID@/` and, with `--enable`, places the widget in the bar (right section by default). `install.sh` then links the commands into `~/.local/bin/` and installs two user units: `omarchy-agent-session-herdr.service`, which keeps the Herdr server running for the whole graphical session so sessions outlive every client window, and `omarchy-agent-session-watch.service`, the notifier. It refuses to overwrite a file it did not create and needs no root. Run it again after `omarchy plugin update`.

Two keybindings are useful and optional; add them to `~/.config/hypr/bindings.lua` yourself:

```lua
o.bind("SUPER + CTRL + G", "Agent sessions", "omarchy-shell @PLUGIN_ID@ toggle")
o.bind("SUPER + CTRL + SHIFT + G", "Agent that needs you", "omarchy-shell @PLUGIN_ID@ openMostUrgent")
```

The plugin leaves Omarchy's own `omarchy-agent` keybinding alone. A version of `omarchy-agent` that creates a session and attaches a terminal sits in the development repository as a proposed change (`bin/upstream-proposed/omarchy-agent.proposed`); it shadows Omarchy's command, so it stays out of this plugin.

## Use

```bash
omarchy-agent-session-new --agent claude --mode personal --name api-refactor --goal "Split the router into modules"
omarchy-agent-session-list
omarchy-agent-session-send api-refactor "Keep the public API unchanged"
omarchy-agent-session-open api-refactor          # attaches a terminal; focuses the preview if one is registered
omarchy-agent-session-preview api-refactor http://localhost:3000
omarchy-agent-session-done api-refactor --verdict kept --note "Reviewed the diff, merged"
omarchy-agent-session-receipt api-refactor
omarchy-agent-session-show api-refactor --loop  # intent, captures, instructions, commits, verdict, in order
```

`omarchy-shell @PLUGIN_ID@ open|close|toggle|refresh|openMostUrgent` drives the panel from anywhere.

## Remove

```bash
~/.config/omarchy/plugins/@PLUGIN_ID@/uninstall.sh
omarchy plugin remove @PLUGIN_ID@
```

`uninstall.sh` stops and removes the two units and the command links, and leaves your session records in `~/.local/state/omarchy/sessions/` because they are your work; delete that directory yourself if you want them gone. Sessions that are still running in Herdr keep running; stop them first with `omarchy-agent-session-stop` if you want a clean slate.

## What it writes

Symlinks in `~/.local/bin/`; two unit files in `~/.config/systemd/user/`; session records under `~/.local/state/omarchy/sessions/`; git worktrees under Herdr's worktree directory (`~/.herdr/worktrees/` by default), one per session that asks for one, on a `session/<name>` branch. That is the whole list: it leaves `/usr`, your projects' own files, and Omarchy's configuration untouched.

## Known issues

A question and a permission prompt reach the panel as one state, because Herdr reports both as `blocked`; every surface says "needs you" for both. Previews registered as a URL open in a Chromium app window and are found by its window class; previews registered as an app id are untested. On the aarch64 image every Claude Code launch raises the locked-keyring prompt, which is the image's doing. After the plugin's files change, the shell's hot reload can leave the widget on old code; `omarchy-restart-shell` makes the change real.

## Source, specs, evidence

The plugin is the shippable part of [omarchy-multiplayer](https://github.com/mphaxise/omarchy-multiplayer), which holds the specs, the evaluation runs with their captures, and the decisions log. Tests: `python3 -m unittest discover -s tests` (121, standard library only).

## License

MIT. External dependencies: Herdr (MIT), the Omarchy shell and its Quickshell components, Python 3, grim, Hyprland's `hyprctl`. Nothing is downloaded at install or run time.
