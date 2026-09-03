# Outbound: Phase 6 drafts

Everything here is a draft for Praneet to read. Nothing in this directory has been posted, filed, or pushed anywhere, and nothing will be until he approves the exact text and the target (PLAN.md, Phase 6 gate). Written 2026-09-02, late evening.

| File | What it is |
|---|---|
| `listing/README.md` | The README of the public listing repository: what the plugin does, requirements, install, use, remove, what it writes, known issues, license. `@PLUGIN_ID@` is filled in by the build. |
| `listing/install.sh`, `listing/uninstall.sh` | Link the commands into `~/.local/bin`, install and enable the two user units; undo exactly that. Neither needs root, downloads anything, or replaces a file it did not create. |
| `listing/preview.png` | The marketplace preview: a crop of the needs-you capture from the rig (`captures/screenshots/sessions-panel-needs-you-goal-mode_…_live.jpg`). |
| `build-listing.sh` | Assembles the listing repository from this checkout into a directory (default `/tmp/omarchy-keepalive`), runs `omarchy plugin validate` when it can, and writes `submission-issue-body.md`. `LISTING_ID=…` sets the plugin id. |
| `submission-issue.md` | The marketplace submission in their exact six-heading form, with the five checklist statements laid out for confirmation and the `gh issue create` command for when it is approved. |
| `discussion-post.md` | A discussion post for `omacom/omarchy` proposing the session model and asking whether it belongs upstream or stays a plugin. |
| `upstream-candidates.md` | Six issue texts, one per finding in `findings/upstream-contributions.md`, each with its target. |

## Decisions that are Praneet's

1. **Target.** Marketplace listing, discussion post, both, or neither. PLAN.md says choose one; both are drafted so the choice is made on the texts.
2. **Name and id: decided.** The plugin is Keepalive (Praneet, 2026-09-02, from five options). The listing id is `io.github.mphaxise.keepalive`, namespaced and lowercase as the marketplace prefers, permanent once listed. The dev checkout and the rig still run under `praneet.agent-sessions` (plugin directory, `omarchy-shell` IPC target, the rig's two keybindings); `build-listing.sh` substitutes the listing id into the manifest and `Panel.qml`. Before the listing is pushed, the rig should run one session under the listing id so what is tested is what ships. That rename touches `~/.config/hypr/bindings.lua` on the rig, so it waits for a go.
3. **Listing repository name.** The drafts say `mphaxise/omarchy-keepalive`, created by pushing the built directory. The development repository stays `mphaxise/omarchy-multiplayer`.
4. **The five checklist statements** in `submission-issue.md`, each of which the marketplace asks the owner to confirm.
5. **Which of the six upstream texts go**, and whether the aarch64 ones go to the image repository or the package repository.

## What was verified

`build-listing.sh` runs from this checkout and produces a directory that `omarchy plugin validate` accepts on the rig (recorded in `captures/sessions/2026-09-02_phase4-first-run.md`). `install.sh` and `uninstall.sh` were run on the rig against a throwaway HOME with a shim in place of `systemctl`, so the real units were untouched; the links, unit files, refusals, and removals behaved as the README says. The scripts have not been run against a clean Omarchy install, and the listing repository does not exist.
