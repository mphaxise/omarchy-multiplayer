# Upstream candidate texts

Six findings from `findings/upstream-contributions.md`, each written as the issue it would become. Status: drafts, 2026-09-02; none filed. Praneet approves each text and its target before it goes anywhere, and `findings/upstream-contributions.md` records the outcome. Targets are the repositories as they stood on 2026-09-02; the aarch64 port's canonical repository should be confirmed before filing (the image came from `ggalancs/omarchy-arm-utm`; the package repository is `omarchy-aarch64`).

Every text keeps to what the rig showed. Where a fix is suggested it is one of several, and says so.

---

## 1. aarch64 port: `omarchy-update` updates packages and never Omarchy itself

Target: the aarch64 port (`ggalancs/omarchy-arm-utm`, or wherever the port maintainer tracks the image). Kind: issue.

**Title:** `omarchy-update` on the aarch64 image leaves `/usr/share/omarchy` at the image's commit

On the UTM aarch64 image, `omarchy-update` updates Arch packages and leaves Omarchy at the commit the image shipped with. `/usr/share/omarchy` is a root-owned git checkout at `0b3f1b7` that no package owns (`pacman -Qo /usr/share/omarchy/bin/omarchy-update` reports no owner), and upstream's `omarchy-update-dev` returns early for that path instead of pulling. The port's own `omarchy` package, 4.0.1-2 in the `omarchy-aarch64` repository, is not installed on the image, so `pacman -Syu` does not update the tree either.

Observed 2026-09-02 after `omarchy-update` and a reboot: nine packages updated (Claude Code among them, through mise), `/usr/share/omarchy` unchanged, version file still `4.0.0.alpha`.

Two ways out, and I would take whichever matches the port's plan: ship the tree as the `omarchy` package on the image so `pacman -Syu` carries it, or point the dev-checkout update path at `/usr/share/omarchy` on this image. Happy to test either on my VM.

---

## 2. `omarchy-restart-shell` reports failure while the shell is still starting

Target: `basecamp/omarchy`. Kind: issue.

**Title:** `omarchy-restart-shell` gives up after two seconds and reports failure on a slow machine

`omarchy-restart-shell` polls for the new shell twenty times at 0.1 s and reports failure when the shell has not answered in two seconds. On an aarch64 VM with software rendering and a load average around 3, the shell took about thirty seconds to come up, so the script printed a failure and left the bar gone while the shell was in fact starting. Recovery was `hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")'` by hand, or waiting.

Observed on quattro `0b3f1b7`, 2026-09-02, repeatedly during plugin development, where the script runs after every QML change.

A longer window, or polling until the launched process exits or answers, would make the failure message true. I can send a pull request if you would rather see it as one.

---

## 3. A plugin hot reload leaves the live widget answering from old code

Target: `basecamp/omarchy`. Kind: issue, after a reproduction on current quattro.

**Title:** After `Local plugin changed, reloading`, the bar widget still answers IPC from the previous code

On `0b3f1b7`, editing a user plugin's `Panel.qml` logged `Local plugin changed, reloading`, and afterwards `omarchy-shell <id> refresh` was answered by the previous version of the widget: a property added in the edit was absent from the running instance until `omarchy-restart-shell`. It happened twice in a row on the same build, with a probe (an IPC call that only the new code could answer) confirming each time.

Because #9485 touched the reload path after `0b3f1b7`, this needs a reproduction on current quattro before it is worth your time; I will reproduce and update this issue, or close it, once my rig is on a newer build. Filing now so the observation is not lost.

---

## 4. `omarchy-launch-tui` blocks its caller until the terminal exits

Target: `basecamp/omarchy`. Kind: issue.

**Title:** `omarchy-launch-tui` returns only when the launched terminal closes

`omarchy-launch-tui` execs the terminal and returns when the terminal window closes, so a script that treats it as a launcher waits for the whole session. In my case a Quickshell `Process` that ran `omarchy-launch-tui ... omarchy-agent-session-receipt --pager` held the panel's "opening…" state until the pager was closed, and a Python `subprocess.run` around it blocked for the terminal's lifetime.

This may be intended (the launcher is the terminal's parent), in which case a line in the script's header saying so would have saved me a detour; otherwise `setsid -f` or the `&` the other launchers use would make it a launcher. Observed on quattro `0b3f1b7`, 2026-09-02, run 1 step 14 in my evaluation notes.

---

## 5. Herdr: `agent.prompt` accepts text before the harness can take it, and the text is lost

Target: Herdr (herdr.dev; the repository or feedback channel it names). Kind: issue.

**Title:** `agent.prompt` succeeds while `interactive_ready` is false, and the prompt never reaches the harness

Sequence on Herdr 0.8.2 with Claude Code 2.1.252 as the agent, 2026-09-02: `agent.start`, then within a second `agent.prompt` with a first instruction. The agent's `agent_status` was already `idle` and the call returned success, but the agent list still showed `interactive_ready: false`; the harness came up a few seconds later with no prompt, and the text was gone. `agent.wait` cannot wait on `interactive_ready`, so a client has to poll `agent.list` for it, which is what I do now.

Two shapes would fix it from the client's side: an `until` value for `interactive_ready` on `agent.wait`, or `agent.prompt` refusing (or queueing) while the harness is not ready. A related observation: a server restart restores every workspace with a fresh shell, so workspaces whose agent has ended come back and pile up; a way to mark a workspace ephemeral, or to close it with the agent, would remove the sweep my client does after every restart.

---

## 6. aarch64 image: every Claude Code launch raises the locked-keyring prompt

Target: the aarch64 port. Kind: issue.

**Title:** Each Claude Code launch opens "Authentication required" for the default keyring

On the UTM aarch64 image, every launch of Claude Code (through `omarchy-agent`, through Herdr, or from a plain terminal) raises the GNOME keyring prompt: "An application wants access to the keyring 'Default Keyring', but it is locked". Dismissing it lets the agent continue; it returns on the next launch, and it lands in every screen capture (`gcr-prompter`, floating at the screen center).

The default keyring is not unlocked at login on this image. Unlocking it through the login path (PAM's `pam_gnome_keyring`, or whatever the x86 image does) would remove the prompt; if the x86 image behaves the same, this belongs upstream instead and I will move it. Observed 2026-09-01 and 2026-09-02, captures on request.
