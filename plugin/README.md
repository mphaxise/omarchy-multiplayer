# Keepalive (io.github.mphaxise.keepalive)

The Omarchy shell plugin: `Panel.qml` (bar icon, panel, data layer), `Session.qml` (one row), `scripts/` (snapshot, receipt pager, new session), `manifest.json`. Live on the rig since 2026-09-02 under this id; before that as `praneet.agent-sessions`.

The listing repository is assembled from this directory plus `bin/`, `systemd/`, `tests/`, and `outbound/listing/` by `outbound/build-listing.sh`; the listing README (`outbound/listing/README.md`) is the user-facing description, install, and removal. `spec/03-sessions-panel.md` is the design, with what the rig changed marked by date.

Develop on the rig: rsync this directory to `~/.config/omarchy/plugins/io.github.mphaxise.keepalive/`, then `omarchy-restart-shell` (hot reload leaves the live widget on old code), then `omarchy-shell io.github.mphaxise.keepalive refresh` as the probe. Validate with `omarchy plugin validate <dir>` and `/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" Panel.qml Session.qml` (the `/usr/bin/qmllint` wrapper on the aarch64 image exits 255 without output).
