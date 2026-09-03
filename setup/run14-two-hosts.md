# Run 14: two people, two machines, one session

Prepared 2026-09-03 afternoon for the evening sitting: a friend on his own Omarchy VM (an M1 Mac, the same aarch64 image, most likely) beside Praneet's rig. Two things get tested. First, a fresh install of Keepalive on a machine nobody here has touched, from the public URL, with the slice-1 promises (close the terminal, reboot, revive) checked by a second person. Second, slice 3 for real: two people on one session across two hosts, the thing run 10 only proxied, including the one path run 10 could not test, a second person answering a blocked agent from another machine.

Roles: the **host** is Praneet's rig (`omarchy@omarchy`, the VM on his Mac); it holds the shared session, the panel, and the Herdr server. The **guest** is the friend's VM; it reaches the host over ssh and Herdr's `--remote`. The friend also installs Keepalive on his own VM for the fresh-install half. Nothing syncs between the two Keepalives; the shared session lives on the host only, which is the slice-3 model.

## Before he arrives (Praneet)

1. **Push 0.3.0** so the friend installs the current listing: `main` is 17 commits ahead, `keepalive-v0.3.0` is tagged, the listing clone is built. On your word: `git push origin main --tags` here, `git push origin main` in `~/Work/omarchy-keepalive`. Without this he gets 0.2.0, which also works for tonight.
2. **Deploy `main` to the rig** (bin, tests, plugin), restart the shell, probe with `omarchy-shell io.github.mphaxise.keepalive refresh`, run the tests there. I do this when you say the other thread is done with the rig.
3. **Make the rig reachable from his VM.** Today the rig sits on UTM's shared network at `192.168.64.2`, reachable only from your Mac (`10.0.0.50`). Three ways, best first:
   - **Bridged.** Shut the rig down (sessions orphan or stay paused; that is the feature). UTM → the VM → Edit → Network → Network Mode "Bridged (Advanced)", interface `en0` → Save → Start. In the VM, `ip -4 -br addr` gives its new address on your Wi-Fi (10.0.0.x). Tell me the address and I update `~/.ssh/config`'s `omarchy-rig` entry. Ask the friend to do the same on his VM, so the reverse test works too.
   - **Port forward on the Mac** (keeps the rig on shared networking): `echo "rdr pass on en0 inet proto tcp from any to any port 2222 -> 192.168.64.2 port 22" | sudo pfctl -ef -` and `sudo sysctl -w net.inet.ip.forwarding=1`. The friend then uses `ssh -p 2222 omarchy@10.0.0.50`. Herdr's `--remote` takes an ssh target, so it needs a `Host` entry with `Port 2222` on his side. Undo afterwards with `sudo pfctl -F all -f /etc/pf.conf`.
   - **Tailscale** on both VMs (`sudo pacman -S tailscale`, `sudo tailscale up`, both of you logged in): the cleanest, and thirty minutes you may not have.
4. **His key on the rig.** Once he has an address for you, he runs `ssh-copy-id omarchy@<RIG>` from his VM (the rig's password once), so `herdr --remote` never asks. Password login also works for the plain ssh steps.
5. **Claude Code on the rig** stays logged in as it is; the shared session's agent runs on the rig under your login. On his VM he needs his own Claude Code login for the fresh-install half.

## The evening, in order

Times are guesses; the whole thing is ninety minutes if the network takes ten.

**A. Fresh install on his VM (20 min).** He follows `outbound/friend-instructions.md`, part 1: install from the public URL, the bar icon, `n` on the panel to start a session with a small goal in a scratch repo, `s` to send an instruction, close the terminal and watch the session keep working, `r` for the receipt, then reboot the VM and press Enter on the orphaned row. Capture each panel state on his machine (`grim`, crop later). What it tells us: whether the install script and the units work on a machine we did not prepare, and whether the panel reads right to someone who has never seen it.

**B. Two people, two hosts (40 min).** Scripted in `setup/run14-two-hosts.sh`; the host steps run on the rig, the guest steps run from his VM over ssh. Every guest command carries `OMARCHY_ACTOR=human:<friend>@<his-vm>` so the surfaces name him, never `omarchy@10.0.0.x`.

1. `host-new`: a session `pair-page` on the spike repo plus a draft session; the panel shows both.
2. `guest-look`: he lists from his VM: `pair-page` shared, the draft absent; `send` refused ("view access; contribute is needed"). Signal 1.
3. `host-grant`: `grant --to <friend>@<his-vm> --level suggest`.
4. `guest-suggest`: `presence --here`, then `send --suggest "…"`; his `accept` refused ("suggest access; own is needed"). The panel on the rig: "<friend> suggests …", `y` and `d`. Signal 2, first half.
5. **You press `y` at the panel.** The instruction runs under his name; the loop view shows `suggested <friend>: …` then `instruction <friend>: … [accepted by omarchy]`. Signal 2, second half. Capture.
6. `host-ask`: an instruction that makes the agent ask a question ("Before you do anything, ask me which of two footer styles I want"); the session goes `blocked`; the toast and the row say needs you.
7. `host-assign`: `assign <friend>@<his-vm>`; the row and the next toast read "owned by <friend>". Signal 3.
8. **`guest-answer`, the new one.** From his VM: `herdr --remote omarchy@<RIG>`, attach to the `pair-page` workspace, answer the agent's question in the pane, detach. On the rig: `blocked` → `working` → `idle`, and the commit lands. This is the path run 10 found closed. Record what the loop view attributes the answer to (nothing, today: a keyboard answer has no actor).
9. `guest-done`: he ends the session as its owner: `done --verdict kept --note "…"`; the receipt's Owner line is him, "created by" is you, People lists his suggest grant, the assignment, one suggestion made and accepted. Signal 4 for presence: `presence` showed him while he was on it and the record has no presence field.
10. `host-finish`: loop view, receipt, events copied to `/tmp/eval-run14/`.

**C. The reverse, if his VM is reachable from the rig (15 min).** You as the guest on a session of his: `guest-look` and `guest-suggest` from the rig against his VM, him pressing `y` on his panel. Same signals, other direction; it also tells us whether the panel's naming holds for a person who set no `OMARCHY_ACTOR` (his panel is `omarchy@omarchy` too, so your commands must carry `OMARCHY_ACTOR=human:praneet@rig`).

**D. Ten minutes of him driving alone.** No script: he opens the panel on his own VM, starts a second session, adds a lane with `a`, walks it with `w`, pauses with `z`, opens History with `e`. Write down every place he hesitates or asks what a word means. That is the sitting slice 2c asks for, in miniature.

## What counts

Pass for B: every step's expected line in `timeline.txt`, the panel captures at 4, 5, 6, 7, and the receipt at 9 with both people on it. The interesting outcomes are in 8: whether `herdr --remote` attaches to the Keepalive server's socket at all (it runs as the user unit `omarchy-agent-session-herdr` with the default socket), whether typing into the pane reaches the harness, and whether the record notices anything. Any of those failing is a finding, not a failed evening.

## Fallbacks

No network between the VMs: run B with the friend at your Mac's keyboard, driving the rig over ssh from your Mac the way run 10 did, with `OMARCHY_ACTOR` set to his name. That loses step 8 and the reverse, and keeps everything else.

`herdr --remote` refuses or hangs: try `ssh -t omarchy@<RIG> herdr` (a plain ssh session running the Herdr client on the rig) and attach to the workspace there; it is the same keyboard path with the client on the far side.

## Evidence

`/tmp/eval-run14/` on the rig (timeline, events, loop view, receipt, panel captures) and `~/eval-run14/` on his VM (his panel captures, `list` output, the install log). Crop every capture to the panel before it lands in `captures/evaluation-run14-two-hosts_hands-on_arm-port_2026-09-03/`; his VM's screen is his, so only the panel crops travel. Findings go to `findings/evaluation-run14-two-hosts-2026-09-03.md`, measured outcomes first, then what he said, then what the run cannot claim.
