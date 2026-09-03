# Outbound: Phase 6 drafts

Written 2026-09-02, late evening, as drafts for Praneet. On his "go all four" at about 22:45 the listing repository was created and pushed (`mphaxise/omarchy-keepalive`), the submission opened (`omacom/omarchy-plugin-marketplace#4566`), and the discussion posted (`omacom/omarchy#9936`); the dev repository was pushed first so the links resolve. The six upstream issue texts are still unfiled. Outcomes are tracked in `findings/upstream-contributions.md`.

| File | What it is |
|---|---|
| `listing/README.md` | The README of the public listing repository: what the plugin does, requirements, install, use, remove, what it writes, known issues, license. `@PLUGIN_ID@` is filled in by the build. |
| `listing/install.sh`, `listing/uninstall.sh` | Link the commands into `~/.local/bin`, install and enable the two user units; undo exactly that. Neither needs root, downloads anything, or replaces a file it did not create. |
| `listing/preview.png` | The marketplace preview: a crop of the needs-you capture from the rig (`captures/screenshots/sessions-panel-needs-you-goal-mode_…_live.jpg`). |
| `build-listing.sh` | Assembles the listing repository from this checkout into a directory (default `/tmp/omarchy-keepalive`), runs `omarchy plugin validate` when it can, and writes `submission-issue-body.md`. `LISTING_ID=…` sets the plugin id. |
| `submission-issue.md` | The marketplace submission in their exact six-heading form, with the five checklist statements laid out for confirmation and the `gh issue create` command for when it is approved. |
| `discussion-post.md` | A discussion post for `omacom/omarchy` proposing the session model and asking whether it belongs upstream or stays a plugin. |
| `upstream-candidates.md` | Six issue texts, one per finding in `findings/upstream-contributions.md`, each with its target. |
| `discussion-followup-lanes.md` | A follow-up comment for #9936 with the lanes result, the two Herdr lessons, and the two-people proxy; drafted 2026-09-03, unposted, and it links the 0.2.0 tag so it goes after the pushes. |

## Decisions that are Praneet's

1. **Target: both, decided and done** (2026-09-02, "go all four").
2. **Name and id: decided and applied.** The plugin is Keepalive (Praneet, 2026-09-02, from five options). The id is `io.github.mphaxise.keepalive`, namespaced and lowercase as the marketplace prefers, permanent once listed. The dev checkout, the rig's plugin directory, its `omarchy-shell` IPC target, and the rig's two keybindings all carry it since 2026-09-02 22:27 (run 6).
3. **Listing repository name.** The drafts say `mphaxise/omarchy-keepalive`, created by pushing the built directory. The development repository stays `mphaxise/omarchy-multiplayer`.
4. **The five checklist statements**: confirmed by Praneet's go, with the listing repository public and validated on the rig from its public URL (run 8).
5. **Which of the six upstream texts go**, and whether the aarch64 ones go to the image repository or the package repository.

## What was verified

`build-listing.sh` runs from this checkout and produces a directory that `omarchy plugin validate` accepts on the rig; the rig runs that exact directory as its plugin under the listing id, and it passed plugins.omarchy.org's pre-share checklist there (run 6). `install.sh` and `uninstall.sh` were run on the rig against a throwaway HOME with a shim in place of `systemctl`, so the real units were untouched; the links, unit files, refusals, and removals behaved as the README says. The scripts have not been run against a clean Omarchy install. The listing repository is built and committed locally on the Mac (`/tmp/omarchy-keepalive`, 36 files) and does not exist on GitHub until Praneet says push.
