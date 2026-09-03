#!/bin/bash
# Run 12 on the rig: history and resume (slice-4/history, 2026-09-03).
# The panel reads through a window (list --ended-within 24h), names what
# ended before it ("N earlier · e"), and `e` opens History; a stopped
# session with a transcript resumes on Enter (⏎ Resume). Deploy first:
# rsync bin/, tests/, plugin/ to the checkout and the plugin dir, link
# omarchy-agent-session-history into ~/.local/bin.
#
#   run12.sh all            every step in order
#   run12.sh <step>         one step: restart | panel | resume | history | finish
#
# Evidence lands in /tmp/eval-run12; copy it to
# captures/evaluation-run12-history_hands-on_arm-port_<date>/ and crop every
# capture to the panel or the history window before committing.
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
R=/tmp/eval-run12; mkdir -p "$R"
ID=io.github.mphaxise.keepalive
S=restart-page   # run 11's session: stopped, a transcript, a worktree of the spike repo
log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }
panel_crop() { grim "$R/$1.png"; log "captured $1 (crop to the panel before committing)"; }
state() { omarchy-agent-session-show "$S" --json 2>/dev/null | python3 -c "import sys,json; s=json.load(sys.stdin)['session']; print(s['status']['state'], '·', s['status'].get('detail'))"; }

step_restart() {
  omarchy-restart-shell; sleep 8
  omarchy-shell "$ID" refresh; log "shell restarted, refresh probe rc=$?"
  omarchy-agent-session-core list --ended-within 24h --json > "$R/list-window.json"
  log "list --ended-within 24h --json: $(wc -c < "$R/list-window.json") bytes, $(python3 -c "import json;d=json.load(open('$R/list-window.json'));print(len(d['sessions']),'sessions, window',d['window'])")"
  log "list --json (no window): $(omarchy-agent-session-core list --json | wc -c) bytes"
}

step_panel() {
  # The day the panel shows, and the pointer to the days it does not.
  omarchy-shell "$ID" open; sleep 3; panel_crop panel-done-today-earlier
  wtype -k Right; sleep 2; panel_crop panel-done-expanded
  wtype -k Escape; sleep 1; omarchy-shell "$ID" close
}

step_resume() {
  # A stopped session with a transcript: the row says Resume, and open
  # brings it back through the orphan path with the same harness ref.
  log "before: $S is $(state)"
  REF_BEFORE=$(python3 -c "import json,glob; [print(json.load(open(p))['agent']['harness_session_ref']) for p in glob.glob('$HOME/.local/state/omarchy/sessions/*/session.json') if json.load(open(p))['name']=='$S']" | tail -1)
  omarchy-agent-session-open "$S" 2>&1 | tee -a "$R/timeline.txt"; log "open rc=${PIPESTATUS[0]}"
  for i in 1 2 3 4 5 6 7 8 9 10; do sleep 3; st=$(state); log "  $S: $st"; case "$st" in idle*|waiting*|blocked*) break;; esac; done
  REF_AFTER=$(python3 -c "import json,glob; [print(json.load(open(p))['agent']['harness_session_ref']) for p in glob.glob('$HOME/.local/state/omarchy/sessions/*/session.json') if json.load(open(p))['name']=='$S']" | tail -1)
  log "harness ref before ${REF_BEFORE:0:8}… after ${REF_AFTER:0:8}… $([ "$REF_BEFORE" = "$REF_AFTER" ] && echo same || echo DIFFERENT)"
  herdr agent list 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); [print('  herdr', a['name'], a['agent_status'], a.get('pane_id')) for a in d['result']['agents']]" | tee -a "$R/timeline.txt"
  omarchy-shell "$ID" open; sleep 3; panel_crop panel-resumed-working; omarchy-shell "$ID" close
  omarchy-agent-session-log "$S" 2>/dev/null | tail -12 > "$R/events-tail.txt"
}

step_history() {
  # `e` from the panel opens History in a TUI window; the text is saved too.
  omarchy-agent-session-history > "$R/history.txt"; log "history: $(head -1 "$R/history.txt")"
  omarchy-shell "$ID" open; sleep 3
  wtype e; sleep 4
  GEO=$(hyprctl clients -j | python3 -c "import sys,json; c=[c for c in json.load(sys.stdin) if c['class']=='org.omarchy.session-history']; print('%d,%d %dx%d' % (c[0]['at'][0], c[0]['at'][1], c[0]['size'][0], c[0]['size'][1]) if c else '')")
  if [ -n "$GEO" ]; then grim -g "$GEO" "$R/history-window.png"; log "captured history-window at $GEO"; else grim "$R/history-window.png"; log "history window not found by class; full-screen capture, crop it"; fi
  wtype q; sleep 1
}

step_finish() {
  # Leave the rig as found: the session stopped again, the record keeping both ends.
  omarchy-agent-session-stop "$S" 2>&1 | tee -a "$R/timeline.txt"; log "stop rc=${PIPESTATUS[0]}: $S is $(state)"
  SID=$(python3 -c "import json,glob; [print(json.load(open(p))['id']) for p in glob.glob('$HOME/.local/state/omarchy/sessions/*/session.json') if json.load(open(p))['name']=='$S']" | tail -1)
  cp "$HOME/.local/state/omarchy/sessions/$SID/events.jsonl" "$R/events.jsonl"; echo "$SID" > "$R/sid"
  omarchy-agent-session-show "$S" --loop > "$R/loop-view.txt" 2>&1
  log "done; evidence in $R"
}

case "${1:-all}" in
  all) step_restart; step_panel; step_resume; step_history; step_finish ;;
  restart|panel|resume|history|finish) "step_$1" ;;
  *) echo "usage: $0 [all|restart|panel|resume|history|finish]" >&2; exit 2 ;;
esac
