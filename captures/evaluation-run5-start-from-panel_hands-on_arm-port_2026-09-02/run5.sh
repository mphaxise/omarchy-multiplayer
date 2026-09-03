#!/bin/bash
# Run 5 on the rig: start a session from the panel. Restart the shell,
# open the panel, press n, type a prompt, Enter; expect a new session in
# ~/Work with its terminal open and the panel closed.
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
R=/tmp/eval-run5; mkdir -p "$R"; : > "$R/timeline.txt"
log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }
active() { hyprctl activewindow -j | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('class'), d.get('title','')[:40])"; }

log "default agent: $(omarchy-default-agent 2>&1)"
log "restart shell"
omarchy-restart-shell >/dev/null 2>&1; sleep 5
pgrep -x quickshell >/dev/null || { log "shell not up, launching"; hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")' >/dev/null; sleep 5; }
omarchy-shell praneet.agent-sessions refresh && log "ipc refresh ok"
LOG=$(ls -t /run/user/1000/quickshell/by-id/*/log.log | head -1)
grep -iE "error|warn" "$LOG" | grep -i "agent-sessions\|Panel.qml\|Session.qml\|new-session" | tail -5 | sed 's/^/  qs: /'

BEFORE=$(omarchy-agent-session-list --json | python3 -c "import sys,json; print(len(json.load(sys.stdin)['sessions']))")
log "sessions before: $BEFORE"

omarchy-shell praneet.agent-sessions open; sleep 3
grim "$R/panel-rest.png"; log "captured: starter row at rest"
wtype n; sleep 1
grim "$R/panel-new-open.png"; log "captured: field open"
wtype "Create a file named started-from-the-panel.txt containing the single line: hello from the panel. Do nothing else."; sleep 1
grim "$R/panel-new-typed.png"; log "captured: text typed"
wtype -k Return
sleep 4
log "active after Enter: $(active)"
sleep 12
AFTER=$(omarchy-agent-session-list --json | python3 -c "import sys,json; print(len(json.load(sys.stdin)['sessions']))")
log "sessions after: $AFTER"
NEW=$(omarchy-agent-session-list --json | python3 -c "
import sys,json
ss=json.load(sys.stdin)['sessions']
ss=[s for s in ss if s['status']['state'] in ('starting','working','idle','waiting','blocked')]
ss.sort(key=lambda s: s['status']['since'])
print(ss[-1]['id'] if ss else '')")
echo "$NEW" > "$R/sid"; log "newest live session: $NEW"
[[ -n $NEW ]] && omarchy-agent-session-show "$NEW" | head -12 | sed 's/^/  /' | tee -a "$R/timeline.txt"
hyprctl clients -j | python3 -c "import sys,json; [print('  client:', c['class'], c['title'][:40]) for c in json.load(sys.stdin)]" | tee -a "$R/timeline.txt"
grim "$R/after-start.png"; log "captured: after start"
sleep 20
ls -la ~/Work/started-from-the-panel.txt 2>&1 | sed 's/^/  /' | tee -a "$R/timeline.txt"
cat ~/Work/started-from-the-panel.txt 2>/dev/null | sed 's/^/  file: /' | tee -a "$R/timeline.txt"
# the panel again: the new row, and n with the legend
omarchy-shell praneet.agent-sessions open; sleep 3
grim "$R/panel-after.png"; log "captured: panel with the new row"
omarchy-shell praneet.agent-sessions close
