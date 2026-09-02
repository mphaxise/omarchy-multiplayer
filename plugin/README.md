# Agent Sessions (praneet.agent-sessions)

Proposed Omarchy user plugin, drafted 2026-09-01. Not yet run on the rig.

## Install (on Omarchy, later)

```
mkdir -p ~/.config/omarchy/plugins
cp -r praneet.agent-sessions ~/.config/omarchy/plugins/
omarchy plugin enable praneet.agent-sessions
omarchy bar put praneet.agent-sessions
```

`omarchy plugin validate` should pass since the directory has no symlinks
anywhere in it (checked locally, see below). Settings (refresh interval,
show-when-empty, max rows) are edited through the shell's own plugin
settings UI, sourced from `manifest.json`'s `barWidget.schema`.

## What was validated locally (no Omarchy, no QML engine available here)

- `manifest.json` parses with `python3 -m json.tool` and was spot-checked in
  Python for `schemaVersion`, `id`, `kinds`, `entryPoints`, and the three
  `barWidget.defaults`/`barWidget.schema` keys (`refreshIntervalSec`,
  `showWhenEmpty`, `maxRows`) all being present and correctly shaped.
- `scripts/snapshot.sh` was run against a five-session fixture
  (`OMARCHY_SESSION_LIST_CMD="cat fixture.json"`) covering blocked, waiting,
  working, done, and orphaned states: output matched the fixture byte-for-byte
  after re-normalizing through `json.tool`.
- `scripts/snapshot.sh` was also run through five failure modes, each
  producing a well-formed `{"error": "<reason>"}` on stdout with script exit
  0 in every case: underlying command exits non-zero, underlying command
  prints invalid JSON, underlying command prints nothing, underlying output
  exceeds 64 KB (tested at ~66 KB), and no session-list command exists and
  no `OMARCHY_SESSION_LIST_CMD` override is set.
- Both scripts are `chmod +x`. No file in the plugin directory is a symlink
  (`find . -type l` returned nothing).
- `Panel.qml` and `Session.qml` were checked for balanced
  braces/parens/brackets with a small script (one false positive on a regex
  literal copied verbatim from Hermes's `scriptPath()`, confirmed as a
  checker limitation, not a real imbalance, once that literal was masked
  out). Neither file was compiled or run, there is no Quickshell/QML engine
  in this environment.

## Reference files actually read for this draft

Fetched complete via `mcp__workspace__web_fetch` on 2026-09-01, all on the
first try:

- `raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/agents/manifest.json`
- `raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/agents/Panel.qml`
- `raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/agents/Main.qml`
- `raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/agents/Agent.qml`
- `raw.githubusercontent.com/omacom/omarchy/quattro/shell/plugins/README.md`
- `raw.githubusercontent.com/stevequinn/omarchy-hermes-sessions/main/Panel.qml`
- `raw.githubusercontent.com/stevequinn/omarchy-hermes-sessions/main/manifest.json`
- `raw.githubusercontent.com/stevequinn/omarchy-hermes-sessions/main/scripts/snapshot.sh`

Note: the omarchy.agents plugin's directory in the omacom/omarchy repo is
named `agents/`, even though its manifest `id` is `omarchy.agents` (confirmed
by `shell/plugins/README.md`'s own catalogue table, which lists entry point
`agents/Panel.qml` for the `omarchy.agents` row). A path built from the
plugin id instead of its directory name (`shell/plugins/omarchy.agents/...`)
does not resolve; an earlier fetch attempt against that wrong path in this
same project is why `spec/03-sessions-panel.md` recorded "no content
returned from outside the shell repo" for these files. All eight URLs given
for this task used the correct `agents/` directory and returned full content
immediately, so the GitHub contents-API fallback was never needed.

The three spec files were not reachable at the literal paths given
(`/Users/praneet/Omarchy-Multiplayer/spec/...` is outside this session's
connected folders). Matching content was found already staged in this
session's own `outputs/drafts/` directory as `spec-00-overview.md`,
`spec-02-command-surface.md`, and `spec-03-sessions-panel.md` (naming, not
path structure, differs from the task's request), and `context-pack.md` in
the same directory, cited as spec-03's own source for the plugin manifest
schema and component contracts. All four were read in full.

## Assumptions the spec and references did not settle

- **File split**: 03-sessions-panel.md describes a three-file Panel/Main/
  Session split mirroring `omarchy.agents`. This task's own file list asks
  for only `Panel.qml` and `Session.qml`, and describes Panel.qml as owning
  the Process/Timer/parsing directly, matching Hermes's simpler one-file
  pattern instead. Built as instructed: no `Main.qml`; the data layer
  (Process, Timer, and the index.json FileView) lives in `Panel.qml`.
- **Two data sources, not one**: the task's Panel.qml field list only
  mentions the `snapshot.sh` Process/Timer path, but 03-sessions-panel.md's
  "stale marker" requires `index.json`'s `generated_at`, which only the
  spec's secondary `FileView` source provides. Kept both: `snapshot.sh` for
  session content, the `index.json` `FileView` solely for staleness.
- **Command-surface naming conflicts among the sources themselves**: three
  different forms appear across the inputs for "list the sessions as JSON" , 
  `omarchy-agent-session-list` (spec-02's stated binary convention),
  `omarchy agent session list` / bare `omarchy-agent-session list` (spec-02's
  and spec-03's own worked examples), and `omarchy-agent-session-core list`
  (this task's literal instruction). `scripts/snapshot.sh` tries `-core`
  first, then `-list`, per the task's literal wording; see the file's own
  `VERIFY ON RIG` note. `Stop`'s command name was not given explicitly
  anywhere; `omarchy-agent-session-stop` was inferred by matching the
  hyphenation the task did give for Open and Send.
- **Bar-widget visibility test**: read as "hide when there are zero session
  rows of any kind and `showWhenEmpty` is false," matching the literal
  `sessions.length > 0` / `providers.length > 0` tests in the two reference
  plugins, instead of a narrower "hide unless something is live" reading of
  the spec's "Bar widget" section (whose urgent/foreground/muted color table
  only covers live states, but never says to hide on a panel that's all
  Done/Orphaned rows).
- **Section sort order for Working, Done today, and Orphaned**: the spec
  only specifies a sort rule for Needs You (blocked before waiting, oldest
  first). The other three sections sort most-recent-`since`-first here, an
  unstated default.
- **`maxRows` truncation**: applied as a cap on the flattened total across
  all four sections, trimming lowest-priority sections first (Orphaned, then
  Done, then Working, Needs You last). Not stated in the spec.
- **Two different "most urgent" orderings, kept distinct on purpose**: the
  Needs You panel section sorts oldest-`since`-first (surfaces the
  longest-neglected session); the bar's middle-click target sorts
  newest-`since`-first ("most recently needing attention"). Both are
  written that way, explicitly and separately, in 03-sessions-panel.md, and
  are implemented as two separate functions in `Panel.qml` instead of
  reused as one.
- **"No Herdr running" empty state** (03-sessions-panel.md, "States and
  empty states") was deliberately left out. `list --json` is documented in
  02-command-surface.md as making no Herdr call at all ("Herdr: none"), so
  nothing in this data path can actually distinguish "Herdr isn't running"
  from any other reason the list came back empty; the task's own Panel.qml
  field list also does not ask for this state. The generic "No sessions
  yet." empty state and three-strikes error row cover the rest.
- **`status.source` field**: 02-command-surface.md's own `list --json`
  example does not show a `source` key on `status`, only 03-sessions-panel.md
  mentions it (for the low-confidence dot). Treated as optional; the dot is
  hidden whenever the field is absent, shown only when present and equal to
  `"herdr-manifest"`.
- **Extra manifest fields**: `license`, `activation`, and `barWidget.description`
  were added beyond the task's explicit field list because both fetched
  reference manifests (`omarchy.agents` and Hermes) carry all three; treated
  as part of the real contract, and is no guess.

## Every `VERIFY ON RIG` line

| File | Line | What's uncertain |
|---|---|---|
| `Panel.qml` | 207 | Whether `FileView.watchChanges` fires when `index.json` is replaced by rename instead of edited in place (spec-03 names this exact risk; the Timer-driven `snapshot.sh` poll is the fallback either way). |
| `Panel.qml` | 355 | Whether `omarchy-launch-tui`'s `-e "$1" "${@:2}"` form runs a bare vendored script path directly, and whether it needs an app id at all, context-pack.md shows it reading `$APP_ID` from the environment instead of taking a `--app-id` flag the way `omarchy-launch-or-focus-tui` does. |
| `Panel.qml` | 406 | The bar glyph codepoint is a guess (a nerd-font private-use point); neither reference plugin renders an agent/session glyph, so this needs a real look on the rig's font. |
| `Panel.qml` | 420 | The `needs_attention` badge is a manual Rectangle+Text overlay on `BarIconButton`; neither reference plugin shows a numeric badge, so a native badge/count property may already exist and wasn't used. |
| `Panel.qml` | 467 | Keyboard selection does not scroll the selected row into view. Hermes's own scroll math assumes a fixed ~52px row height; rows here vary in height (the inline Send field grows a row), so that fixed-offset approach would misplace the scroll. Needs real per-row positions (e.g. a `ListView`) to do properly. |
| `Session.qml` | 193 | The inline Send field is a plain `QtQuick.Controls.TextField`. Neither reference plugin uses a text input, so there is no confirmed Omarchy-themed equivalent; it may look inconsistent against the shell's own controls until checked on the rig. |
| `scripts/snapshot.sh` | 15 | The real binary name for "list the sessions as JSON" is unconfirmed, three different forms appear across the spec files and this task's own instructions (see "Assumptions" above); the script tries `omarchy-agent-session-core` then `omarchy-agent-session-list`. |
