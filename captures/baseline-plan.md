# Baseline capture plan

Status: plan, 2026-09-01. Runs once, from a pristine boot, before any build lands in the guest. Provenance: `hands-on`. Environment: the ARM rig as documented in Omarchy-UX. Findings from it carry the unofficial-port caveat.

## Why first

Every later capture is an after picture. This session is the before picture: what one person sees today when running several agents on Omarchy 4.0.2, with nothing from this repository installed.

## Setup

1. Boot from the pristine snapshot. Confirm the Omarchy version string, the Hyprland version, and whether `herdr` is present (`which herdr`, `herdr --version`).
2. Set the default agent to Claude Code if unset (`omarchy default agent claude`). Record the choice.
3. Open a small project under `~/Work` (a throwaway git repository with a README and one script) so agents have something to touch.

## Scenario A, two agents from the keybinding

4. Press Super+Shift+Ctrl+A twice. Capture: two terminal windows with app id `org.omarchy.agent`, how the bar and the window titles distinguish them, what the usage widget shows.
5. Give each agent a short task. Close one window mid-task. Capture what remains: is the process gone (`pgrep -af claude`), what the other window shows, whether anything in the shell notices.
6. Reopen with the keybinding. Capture whether the previous conversation is reachable and how (harness resume only).

## Scenario B, two agents inside Herdr

7. Press Super+Ctrl+Return. Run `hdl claude` in the project directory. Capture the layout, the sidebar, and the agent status Herdr shows while the agent works, waits, and idles.
8. Detach the Herdr client (close the terminal window). Capture: is the agent still running, what `herdr agent list` reports, and how long it takes to find the pane again from a fresh terminal.
9. Start a second agent with `hsl 2 claude` or a second `hdl` tab. Capture how Herdr distinguishes them and what happens when both need input at once.

## Scenario C, the crash path

10. Enable crash capture if off (`omarchy toggle crash-capture`). Run a program that segfaults (`sh -c 'kill -SEGV $$'` or a small C binary). Capture the notification, its click target, the agent window it opens, and the prompt the agent receives.
11. Close that window while the diagnosis runs. Capture what remains.

## What to record per capture

Filename per `captures/README.md`: `<surface>_hands-on_<version>_2026-09-DD.png` or `.mp4`. A session note in `captures/sessions/` with the environment line, the scenario step numbers, the observation, and the open question each capture answers from `setup/rig-questions.md`.

## What this session must not do

Install anything from this repository. Change Herdr's config. Enable sshd on the pristine snapshot (that happens on the `dev` snapshot).
