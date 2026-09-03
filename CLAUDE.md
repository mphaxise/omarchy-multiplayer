# Working rules for omarchy-multiplayer

Read at the start of every session in this repository. `PLAN.md` is the plan, `decisions.md` the dated log, `README.md` the map.

## One source, one build output

- This repository is the only source. The core (`bin/`), the plugin (`plugin/io.github.mphaxise.keepalive/`), the units (`systemd/`), the tests (`tests/`), the specs, and the findings all live here.
- Keepalive (`github.com/mphaxise/omarchy-keepalive`, marketplace id `io.github.mphaxise.keepalive`) is a build output of this repository, assembled by `outbound/build-listing.sh`. Never edit the listing repository by hand; change the source here and rebuild.
- Every listing build writes `SOURCE` naming the dev commit it came from. Every release is tagged here as `keepalive-v<version>`.

## Branches

- `main` is shippable at all times. A Keepalive hotfix is cut from `main`.
- Slice work goes on `slice-N/<topic>` branches (for example `slice-2/lanes`) and merges into `main` when the slice's success signals pass on the rig with captures.
- Commit locally at each increment without asking. Pushing is a separate, approved step.

## Releasing Keepalive

1. On a clean `main`: `outbound/release-keepalive.sh <version>`. It runs the tests, bumps the manifest version, commits, tags, and builds one commit onto the listing clone at `~/Work/omarchy-keepalive`.
2. Praneet says push. Then `git push origin main --tags` here and `git push origin main` in the clone.
3. Praneet says post. Then the marketplace's "Verify and publish a newer upstream commit" form with the listing's 40-character SHA.
4. Record the outcome in `findings/upstream-contributions.md`.

A bug against the listing: reproduce on the rig, fix on `main` with a test, release. In that order.

## The rig

- `omarchy-rig` over ssh (the aarch64 UTM image). Deploy with rsync into `~/Work/omarchy-multiplayer/` (checkout) and `~/.config/omarchy/plugins/io.github.mphaxise.keepalive/` (the plugin, a git checkout of the listing since run 8). The commands in `~/.local/bin` are symlinks into the checkout.
- After any QML change: `omarchy-restart-shell`, then `omarchy-shell io.github.mphaxise.keepalive refresh` as the probe. Hot reload leaves the old code live.
- Tests: `python3 -m unittest discover -s tests -p "test_*.py"`, here and on the rig. Lint: `/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" Panel.qml Session.qml` (the `/usr/bin/qmllint` wrapper exits 255 silently).
- Never type the guest password, never use sudo in the guest, never install beyond user-space files. Never restart the Herdr server while Praneet has live sessions.

## Evidence

- One directory per run under `captures/evaluation-runN-<topic>_hands-on_arm-port_<date>/` with `timeline.txt`, the records, the captures, the script, and a README.
- Captures follow the Omarchy-UX labels: provenance, version, date, `proposed` or `live`. Crop captures to what the evidence needs before committing; Praneet's own sessions and terminals never land in the public repository.
- Findings separate measured outcomes from judgment calls and say what they cannot claim.

## Publishing and writing

- Nothing is pushed, created, posted, or filed on GitHub without Praneet's word for that exact text and target. Drafts live in `outbound/`.
- Outward text follows Praneet's editorial rules: lead with the claim, plain words, short sentences, first person, claims that match the evidence.
- This repository is public. No private personal context, credentials, or raw communications go into it.
