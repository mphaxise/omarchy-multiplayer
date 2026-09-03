# Upstream contributions

Findings that warranted action outside this repository, converted into discussion posts, issues, pull requests, or releases, with their evidence.

| Date | Target | Contribution | Evidence | Status |
|------|--------|--------------|----------|--------|

## Candidates not yet filed

Each needs my approval of the exact text and target before it goes anywhere.

- **ggalancs/omarchy-arm-utm (or omarchy-mac/omarchy-pkgs-aarch64).** On the aarch64 image `omarchy-update` never updates Omarchy itself: `/usr/share/omarchy` is a root-owned git checkout that no package owns, and upstream's `omarchy-update-dev` exits without pulling for that path, while the port's `omarchy` 4.0.1-2 package sits uninstalled in the `omarchy-aarch64` repo. Evidence: `captures/sessions/2026-09-02_phase4-first-run.md`, late-evening addendum; `pacman -Qo /usr/share/omarchy/bin/omarchy-update` (no owner), `pacman -Si omarchy` (4.0.1-2 available). Suggested fix: ship the tree as the package on the image, or point the dev-checkout path at it.
- **basecamp/omarchy.** `omarchy-restart-shell` polls readiness for two seconds (20 x 0.1 s) and reports failure while the shell is still coming up on a slow machine; on this VM under a load average of 3 it took about thirty seconds. Evidence: session note, 15:08 incident. Suggested fix: a longer window, or poll until the process exits.
- **basecamp/omarchy.** A plugin hot-reload left the live bar widget answering IPC from the old code twice in a row on this build (0b3f1b7); only a shell restart replaced it. Needs a reproduction on current quattro before filing, since #9485 touched the reload path. Evidence: session note, 14:16 probe.
- **basecamp/omarchy.** `omarchy-launch-tui` blocks the caller until the launched terminal exits, which surprises any script that treats it as a launcher. Evidence: run 1, step 14. Suggested fix: document it, or detach.
- **Herdr (herdr.dev).** `agent.prompt` accepts text while `agent_status` is `idle` and `interactive_ready` is still false, and the text is lost; `agent.wait` cannot wait on `interactive_ready`. Evidence: run 1, `eval-b`. Suggested fix: an `until: ["interactive_ready"]` option, or a rejection while the harness is not ready. Also: a server restart restores every workspace with a fresh shell, so ended sessions' workspaces reappear; a way to mark a workspace ephemeral would remove the sweep this repo does.
- **ggalancs/omarchy-arm-utm.** Every Claude Code launch raises the locked-keyring prompt on the image. Evidence: `baseline-a2-two-keybinding-agents-keyring-prompt_…jpg`. Worth checking whether the image can unlock the default keyring at login.
