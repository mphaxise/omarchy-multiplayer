# Evaluation run 6, the plugin under its listing id through the marketplace's pre-share checklist: raw evidence

Run 6 on 2026-09-02, 22:27 to 22:30 PDT (UTC 05:27Z to 05:30Z in the files), driven over ssh. The checklist is the one plugins.omarchy.org's development guide (updated 13 Aug 2026) asks for before sharing: validate, `qmllint`, click, Escape, shell open and close, disable, re-enable, shell restart, removal.

| File | What it is |
|---|---|
| `timeline.txt` | the step log: `praneet.agent-sessions` retired, `io.github.mphaxise.keepalive` installed from the built listing directory, validated, enabled, the two keybindings rebound; then the checklist; then one session started from the panel under the new id |
| `qmllint.txt` | `/usr/lib/qt6/bin/qmllint -I $OMARCHY_PATH/shell Panel.qml Session.qml`: exit 0, 190 warnings (151 unqualified access to `Style` and friends, 27 import, 5 unresolved-type, 4 required, 2 signal-handler-parameters, 1 inheritance-cycle), no errors |
| `qmllint-clock.txt`, `qmllint-agents.txt` | the same command on the built-in clock (157 warnings, 9 missing-property) and agents (166, 6 missing-property) plugins on this build, for comparison; the `qs.*` import warnings come from the shell modules, which `-I` does not resolve on this image |
| `summon.jpg`, `hide.jpg` | `omarchy-shell shell summon <id> '{}'` opened the panel; `shell hide <id>` closed it. Every capture in this directory is cropped to the panel, or to the bar strip when the panel was closed, because Praneet's own sessions had terminals open across the rest of the screen during the run |
| `toggle-open.jpg`, `escape-closed.jpg` | our own IPC target's `toggle` opened it; Escape closed it |
| `disabled.jpg`, `enabled.jpg` | `omarchy plugin disable` took the icon off the bar; `enable --section right` put it back and IPC answered again |
| `new-typed.jpg`, `panel-new-id.jpg` | a session started from the panel under the new id: the prompt typed, then the row under Working; the agent wrote the file the prompt asked for |
| `run6.sh` | the step script |

Removal: `omarchy plugin remove <id> --yes` unloaded the plugin and left a backup at `~/.config/omarchy/plugins/.io.github.mphaxise.keepalive.bak.<stamp>`; the directory was copied back, rescanned, and enabled, and IPC answered. Click was tested by Praneet at the rig earlier the same evening; `/usr/bin/qmllint` on this image exits 255 with no output, the Qt 6 binary under `/usr/lib/qt6/bin` is the one that works.
