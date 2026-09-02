# Rig questions

Status: open, 2026-09-01. The rig is documented in Omarchy-UX (`setup/omarchy-vm-notes.md`); this file lists what this experiment needs the rig to answer, in the order the first hands-on session should take them. Each spec file carries its own "Verify on rig" list; this is the union, deduplicated.

## Answers so far

Items 2 and 4 through 10 are answered in `spikes/herdr-on-rig.md` (2026-09-02). Item 1: sshd is on, the guest is `192.168.64.2` (UTM shared network, host side `192.168.64.1`), key auth works, and the Mac's ssh config carries the alias `omarchy-rig`. Item 3: Codex is present as a mise shim; OpenCode is present. Open: a Claude Code turn with status transitions (needs the in-VM login), items 11 through 19.

## Before anything else

1. Snapshot the VM as `dev-2026-09-01`. Done 2026-09-02 09:59 PDT: after the VM was quit from UTM (a power-cut stop; the guest runs btrfs, so the image is crash-consistent), `Data/dev-2026-09-01.qcow2.bak` (9,254,600,704 bytes) and `Data/dev-efi_vars-2026-09-01.fd.bak` were made with an APFS clone of the live disk and EFI vars, verified by size, head, tail, and EFI byte compare. The Mac had 14 GiB free at the time; clones share blocks until the live disk diverges. Still open: enable sshd in the guest, record the guest IP here, confirm `ssh omarchy@<ip>` from the Mac, and note the UTM network mode that made it work.
2. Is Herdr installed on the ARM image? `which herdr`, `herdr --version`, and `pacman -Qi herdr`. If absent, does the community aarch64 repo carry it? If the package is x86-64 only, this is the first decision point in `decisions.md` (x86-64 rig, or degraded tmux mode).
3. Is the Codex CLI installed and authenticated? OpenCode? Record versions.

## Herdr

4. Does the socket exist at `~/.config/herdr/herdr.sock` and does `herdr api snapshot` return JSON? Do `workspace list`, `pane list`, `agent list`, and `agent get` return the fields the session model binds (`workspace_id`, `tab_id`, `pane_id`, `agent_id`)?
5. Does `events.subscribe` stream `pane.agent_status_changed` to a long-lived reader started outside a Herdr client, and does the stream survive `herdr server reload-config` (which Omarchy triggers on theme change)?
6. Which status source applies to Claude Code and to Codex on this image (hook or manifest), and what do `waiting` versus `blocked` look like in `herdr agent explain` for each?
7. Does `agent.rename` accept the slugified session name, and does the sidebar show it?
8. Does `pane.close` end the harness process, or only Herdr's tracking of it?
9. Does Herdr's custom metadata channel keep the session id across a reload?
10. Does `worktree.create` work on this image, and where does it put the checkout?

## Harness flags

11. For each harness in the `04-permission-modes.md` table marked "verify on rig", run the flag and record whether the harness accepts it and what it does. The Codex `--approve-for-me` flag Omarchy ships is undocumented in the vendor reference; record what the installed Codex version accepts.
12. Confirm the exit key sequence per harness so `stop` ends the process cleanly.

## Shell plugin

13. Does a user plugin with kinds `["bar-widget"]` and a `Process`-fed model appear after `omarchy plugin enable` and `omarchy bar put`, and does hot reload pick up edits, or is `omarchy restart shell` needed each time?
14. Does a JSON parse failure inside the widget stay contained, or does it take the bar down?
15. What does `hyprctl activewindow -j` return for a terminal launched with `--app-id=org.omarchy.session.<id>`, and does the fullscreen field exist?
16. Which screenshot command exists on this image (`omarchy capture screenshot` and its modes), and can it run without an interactive click?
17. Does `omarchy-notification-send --exec` deliver the click action when the notifier runs as a systemd user service?

## Measurement

18. Frame rate and input latency under software rendering, to decide whether the five-second signal is measured from a screen recording or from event timestamps.
19. Whether a deliberate segfault produces the crash notification on this image, and how long the coredump takes.
