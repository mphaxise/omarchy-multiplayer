#!/bin/bash
# Run 6 on the rig: the plugin under its listing id, io.github.mphaxise.keepalive,
# through plugins.omarchy.org's pre-share checklist: validate, qmllint, shell
# restart, shell summon/hide, our IPC, Escape, disable, re-enable, removal
# and re-add, then one session started from the panel.
#   run6.sh switch     retire praneet.agent-sessions, install the built listing dir, rebind keys
#   run6.sh check      the checklist
#   run6.sh session    n, a prompt, Enter under the new id
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
export OMARCHY_PATH=${OMARCHY_PATH:-/usr/share/omarchy}
R=/tmp/eval-run6; mkdir -p "$R"
log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }
NEW=io.github.mphaxise.keepalive
OLD=praneet.agent-sessions
P=$HOME/.config/omarchy/plugins
listed() { omarchy-plugin-list --json | python3 -c "import sys,json; d=json.load(sys.stdin); print([(p['id'], p.get('enabled')) for p in d if p['id'] in ('$NEW','$OLD')])"; }
qslog() { ls -t /run/user/1000/quickshell/by-id/*/log.log | head -1; }
restart_shell() { omarchy-restart-shell >/dev/null 2>&1; sleep 5; pgrep -x quickshell >/dev/null || { hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")' >/dev/null; sleep 6; }; }

case "${1:-}" in
switch)
  log "plugins before: $(listed)"
  omarchy-plugin-disable "$OLD" 2>&1 | sed 's/^/  /'
  mkdir -p ~/Work/plugins-retired
  [[ -d $P/$OLD ]] && mv "$P/$OLD" ~/Work/plugins-retired/"$OLD.$(date +%s)" && log "retired $P/$OLD to ~/Work/plugins-retired/"
  rm -rf "$P/$NEW"; cp -R /tmp/omarchy-keepalive "$P/$NEW"; rm -f "$P/$NEW/.built-by-build-listing"
  log "installed $P/$NEW ($(ls "$P/$NEW" | tr '\n' ' '))"
  omarchy-plugin-validate "$P/$NEW" && log "validate: ok"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1; sleep 1
  omarchy-plugin-enable "$NEW" --section right 2>&1 | sed 's/^/  /'
  sleep 2
  log "plugins after: $(listed)"
  # keybindings: same two lines, the new id
  sed -i "s/omarchy-shell $OLD /omarchy-shell $NEW /g" ~/.config/hypr/bindings.lua
  grep -n "$NEW\|$OLD" ~/.config/hypr/bindings.lua | sed 's/^/  bindings: /' | tee -a "$R/timeline.txt"
  hyprctl reload >/dev/null 2>&1 && log "hyprland reloaded"
  ;;
check)
  log "== qmllint"
  qmllint -I "$OMARCHY_PATH/shell" "$P/$NEW/Panel.qml" "$P/$NEW/Session.qml" > "$R/qmllint.txt" 2>&1; rc=$?
  log "qmllint rc=$rc, $(wc -l < "$R/qmllint.txt") lines"; grep -c "warning" "$R/qmllint.txt" | sed 's/^/  warnings: /'
  head -12 "$R/qmllint.txt" | sed 's/^/  /'
  log "== shell restart"
  restart_shell
  omarchy-shell "$NEW" refresh && log "our IPC target answers: $NEW refresh"
  grep -iE "error|warn" "$(qslog)" | grep -i "$NEW\|Panel.qml\|Session.qml" | tail -4 | sed 's/^/  qs: /'
  log "== shell summon / hide"
  omarchy-shell shell summon "$NEW" '{}' 2>&1 | sed 's/^/  /'; sleep 2; grim "$R/summon.png"; log "captured after summon"
  omarchy-shell shell hide "$NEW" 2>&1 | sed 's/^/  /'; sleep 1; grim "$R/hide.png"; log "captured after hide"
  log "== our IPC: toggle open, Escape closes"
  omarchy-shell "$NEW" toggle; sleep 2; grim "$R/toggle-open.png"
  wtype -k Escape; sleep 1; grim "$R/escape-closed.png"; log "captured toggle-open and escape-closed"
  log "== disable / enable"
  omarchy-plugin-disable "$NEW" 2>&1 | sed 's/^/  /'; sleep 2; grim "$R/disabled.png"; log "disabled: $(listed)"
  omarchy-plugin-enable "$NEW" --section right 2>&1 | sed 's/^/  /'; sleep 2; grim "$R/enabled.png"; log "enabled: $(listed)"
  omarchy-shell "$NEW" refresh && log "IPC answers after re-enable"
  log "== remove / re-add"
  omarchy-plugin-remove "$NEW" --yes 2>&1 | sed 's/^/  /'; sleep 2
  log "after remove: $(listed); dir exists: $([[ -d $P/$NEW ]] && echo yes || echo no)"
  ls -d "$P"/.backup* "$P"/*backup* "$P"/.*"$NEW"* 2>/dev/null | sed 's/^/  backup: /'
  cp -R /tmp/omarchy-keepalive "$P/$NEW"; rm -f "$P/$NEW/.built-by-build-listing"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1; sleep 1
  omarchy-plugin-enable "$NEW" --section right 2>&1 | sed 's/^/  /'; sleep 2
  log "re-added: $(listed)"
  omarchy-shell "$NEW" refresh && log "IPC answers after re-add"
  ;;
session)
  BEFORE=$(omarchy-agent-session-list --json | python3 -c "import sys,json; print(len(json.load(sys.stdin)['sessions']))")
  omarchy-shell "$NEW" open; sleep 3
  wtype n; sleep 1
  wtype "Create a file named keepalive-check.txt containing the single line: started under the listing id. Do nothing else."; sleep 1
  grim "$R/new-typed.png"
  wtype -k Return; sleep 16
  AFTER=$(omarchy-agent-session-list --json | python3 -c "import sys,json; print(len(json.load(sys.stdin)['sessions']))")
  log "sessions before $BEFORE after $AFTER"
  SID=$(omarchy-agent-session-list --json | python3 -c "
import sys,json
ss=[s for s in json.load(sys.stdin)['sessions'] if s['status']['state'] in ('starting','working','idle','waiting','blocked')]
ss.sort(key=lambda s: s['status']['since']); print(ss[-1]['id'] if ss else '')")
  echo "$SID" > "$R/sid"; log "session: $SID"
  hyprctl clients -j | python3 -c "import sys,json; [print('  client:', c['class']) for c in json.load(sys.stdin) if 'session' in c['class']]" | tee -a "$R/timeline.txt"
  sleep 20; cat ~/Work/keepalive-check.txt 2>/dev/null | sed 's/^/  file: /' | tee -a "$R/timeline.txt"
  omarchy-shell "$NEW" open; sleep 3; grim "$R/panel-new-id.png"; omarchy-shell "$NEW" close
  [[ -n $SID ]] && omarchy-agent-session-stop "$SID" >/dev/null 2>&1 && log "test session stopped"
  rm -f ~/Work/keepalive-check.txt
  ;;
*) echo "usage: run6.sh switch|check|session"; exit 2 ;;
esac
