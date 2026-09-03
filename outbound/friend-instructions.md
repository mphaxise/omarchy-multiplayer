# Keepalive: tonight's test, for you

Thanks for coming. Two things to try on your Omarchy VM: install Keepalive the way a stranger would and see whether it keeps its promises, then be the second person on a session that runs on my machine. Ninety minutes. Say every confusing thing out loud; that is the point.

## Bring, or have ready

- Your Omarchy VM booted (Quattro, 4.0.x), on the same Wi-Fi as my Mac. If UTM has it on "Shared Network", switch it to "Bridged (Advanced)" before you come (VM off → Edit → Network → Bridged, interface `en0` → Save); that gives it an address my machine can reach, and the reverse test needs it.
- Claude Code logged in on the VM (`claude` opens and answers). Codex also works if that is what you use.
- A scratch git repo on the VM with a few files, for the agent to work in. `git init ~/scratch && cd ~/scratch && echo hi > hello.md && git add . && git commit -m start` is enough.
- Pick two words: your name as the panel should show it (say `alex`) and a name for your VM (say `alex-vm`). Everything you do on my machine will carry `alex@alex-vm`.

## Part 1: install it, run one session, close things, reboot

Open a terminal on your VM.

```
omarchy plugin add https://github.com/mphaxise/omarchy-keepalive --enable
~/.config/omarchy/plugins/io.github.mphaxise.keepalive/install.sh
```

No root. It links commands into `~/.local/bin` and installs two user units. A robot icon appears in the bar; if it does not, run `omarchy-restart-shell`.

Then, from the bar (click the robot) or the keyboard (`SUPER+CTRL+G` if you add the binding from the README):

1. Press `n`, type what the agent should do in your scratch repo ("add a README that lists the files, commit it"), press Enter. A terminal opens with the agent in it.
2. Close that terminal window. Open the panel again: the session is still there, still working or idle. That is the whole point of the plugin; tell me if it is not.
3. Press `s` on the row and send it a second instruction. Press `r` when it is done: the receipt shows the branch, the commits, the diff.
4. Press `z` to pause it, then Enter to resume it. Press `e` to open History.
5. Reboot the VM. Open the panel: the session shows as orphaned. Press Enter; the agent comes back on its own transcript.

Take a screenshot of the panel at each step (Omarchy's screenshot key, or `grim ~/eval-run14-panel-N.png` from a terminal); I only keep the panel crop.

## Part 2: be the second person on my session

My machine is the host; the session runs there. You act on it from your VM over ssh. Replace `RIG` with the address I give you, and the two names with yours.

Once, so nothing asks for a password later:

```
ssh-copy-id omarchy@RIG
```

Then these, one at a time, when I say go. Each runs a script on my machine under your name:

```
G='ssh omarchy@RIG FRIEND=alex FRIEND_HOST=alex-vm bash ~/Work/omarchy-multiplayer/setup/run14-two-hosts.sh'
$G guest-look       # you see the shared session and not my draft; your send is refused
$G guest-suggest    # you propose an instruction; it waits on my panel until I press y
$G guest-answer     # after step 3 below; this just watches the record while you answer
$G guest-done       # you end the session, because by then it is yours
```

Step 3, the interesting one. My agent will stop and ask a question. I will have handed the session to you, so it is yours to answer, from your machine:

```
herdr --remote omarchy@RIG
```

That opens my machine's Herdr in your terminal. Pick the `pair-page` workspace, click into the agent's pane, answer the question (type the color and press Enter), then detach the way Herdr's status line says. If `herdr --remote` refuses, use `ssh -t omarchy@RIG herdr` instead and do the same.

What I am looking for: whether you can tell, from your side, what the session is doing without seeing my screen (`ssh omarchy@RIG omarchy-agent-session-show pair-page --loop` prints the whole story any time), and whether answering from your machine feels like something you would do again.

## Part 3: ten minutes on your own

No script. On your own VM: start a second session, press `a` on it and give a second agent its own task, press `w` to walk between the two, `x` twice to stop one. Open the panel, close it, open it again. Tell me every word that did not mean what you expected, and everything you pressed that did nothing.

## Remove it afterwards, if you want

```
~/.config/omarchy/plugins/io.github.mphaxise.keepalive/uninstall.sh
omarchy plugin remove io.github.mphaxise.keepalive
```

Your session records stay in `~/.local/state/omarchy/sessions/`; delete the folder if you want them gone.
