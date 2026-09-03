#!/bin/bash
# Run 9 on the rig: agent lanes (spec/11), two Claude Code lanes on one goal.
# Prepared 2026-09-03 while the rig was off; run it from the rig after
# deploying slice-2/lanes (rsync bin/, tests/, plugin/ to the checkout and
# the plugin dir, restart the shell, probe with omarchy-shell <id> refresh).
#
#   run9.sh all            every step in order
#   run9.sh <step>         one step: new | add | panel | send | conflict | done | finish
#
# Evidence lands in /tmp/eval-run9; copy it to
# captures/evaluation-run9-lanes_hands-on_arm-port_<date>/ and crop every
# capture to the panel before committing (CLAUDE.md, Evidence).
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
R=/tmp/eval-run9; mkdir -p "$R"
ID=io.github.mphaxise.keepalive
log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }
sid() { cat "$R/sid"; }
panel_crop() { grim "$R/$1.png"; log "captured $1 (crop to the panel before committing)"; }

step_new() {
  MAIN=/home/omarchy/Work/spike-repo
  cd "$MAIN" || exit 1
  SID=$(omarchy-agent-session-new --agent claude --mode personal --name lanes-page --base session/loop-hello \
    --goal "$(printf 'hello.html gains a footer and a test file, from two agents\nREADME.md stays untouched\nBoth lanes land on the session branch')" --cwd "$MAIN" 2>>"$R/errors.txt")
  echo "$SID" > "$R/sid"; log "session: $SID"; sleep 12
  omarchy-agent-session-lanes "$SID" | tee -a "$R/timeline.txt"
}

step_add() {
  # Signal 1: the second agent from the panel's `a` field and nothing else.
  omarchy-shell "$ID" open; sleep 3
  wtype a; sleep 1
  wtype "claude Add a file tests.md that lists three checks for hello.html: heading present, date present, footer present. Commit with the message: tests for the page. Do nothing else."; sleep 1
  panel_crop panel-add-typed
  wtype -k Return; sleep 8
  panel_crop panel-after-add
  omarchy-shell "$ID" close
  omarchy-agent-session-lanes "$(sid)" --json | tee "$R/lanes-after-add.json" | python3 -c "import sys,json; [print('  lane', l['lane'], l['kind'], l['state'], l['task']) for l in json.load(sys.stdin)['lanes']]" | tee -a "$R/timeline.txt"
  hyprctl clients -j | python3 -c "import sys,json; [print('  client', c['class'], c['at'], c['size']) for c in json.load(sys.stdin) if 'session' in c['class']]" | tee -a "$R/timeline.txt"
  herdr agent list 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); [print('  herdr', a['name'], a['agent_status'], a.get('pane_id')) for a in d['result']['agents']]" | tee -a "$R/timeline.txt"
}

step_panel() {
  # Signal 2: lane state and task on the cursor row; l walks the lanes.
  omarchy-shell "$ID" open; sleep 3; panel_crop panel-lanes-row
  wtype l; sleep 1; panel_crop panel-lane-selected
  wtype -k Escape; sleep 1; omarchy-shell "$ID" close
}

step_send() {
  # Signal 4: --lane reaches one lane; without it, every live lane and main.
  S=$(sid)
  omarchy-agent-session-send "$S" "Keep the heading as it is." --lane claude 2>&1 | tee -a "$R/timeline.txt"; log "send --lane rc=${PIPESTATUS[0]}"
  omarchy-agent-session-send "$S" "Commit as soon as your file is done." 2>&1 | tee -a "$R/timeline.txt"; log "send fan-out rc=${PIPESTATUS[0]}"
  sleep 3
  for f in "$HOME/.local/state/omarchy/sessions/$S/events.jsonl" $(python3 -c "import json;print(' '.join('$HOME/.local/state/omarchy/sessions/'+l['id']+'/events.jsonl' for l in json.load(open('$R/lanes-after-add.json'))['lanes'] if l['lane']!='main'))"); do
    echo "  $(basename "$(dirname "$f")"): $(grep -c instruction.delivered "$f") delivered" | tee -a "$R/timeline.txt"
  done
}

step_conflict() {
  # Signal 3, the conflict half: a second lane that edits README.md while main edits it too.
  S=$(sid)
  L2=$(omarchy-agent-session-add "$S" --agent claude --lane copy --task "Replace the first line of README.md with: Hello page, lane copy. Commit with the message: readme from the lane. Do nothing else." 2>>"$R/errors.txt")
  log "lane copy: $L2"; sleep 40
  MAINWT=$(python3 -c "import json;print(json.load(open('$HOME/.local/state/omarchy/sessions/$S/session.json'))['workspace']['worktree_path'])")
  (cd "$MAINWT" && sed -i '1s/.*/Hello page, from main/' README.md && git add README.md && git -c user.name=main -c user.email=main@rig commit -q -m "readme from main" && log "main edited README.md too")
  omarchy-agent-session-done "$S" --lane copy --verdict kept --note "copy lane" 2>&1 | tee -a "$R/timeline.txt"; log "done --lane copy rc=${PIPESTATUS[0]} (5 expected: conflict)"
  omarchy-agent-session-lanes "$S" | tee -a "$R/timeline.txt"
  omarchy-shell "$ID" open; sleep 3; panel_crop panel-conflict-needs-you; omarchy-shell "$ID" close
  omarchy-agent-session-stop "$S" --lane copy; log "lane copy stopped after the conflict evidence"
}

step_done() {
  # Signal 3, the merge half: the tests lane lands on the session branch.
  S=$(sid); sleep 20
  omarchy-agent-session-done "$S" --lane claude --verdict kept --note "tests lane" 2>&1 | tee -a "$R/timeline.txt"; log "done --lane claude rc=${PIPESTATUS[0]}"
  MAINWT=$(python3 -c "import json;print(json.load(open('$HOME/.local/state/omarchy/sessions/$S/session.json'))['workspace']['worktree_path'])")
  (cd "$MAINWT" && git log --oneline -5 | sed 's/^/  main branch: /') | tee -a "$R/timeline.txt"
}

step_finish() {
  S=$(sid)
  omarchy-agent-session-done "$S" --verdict kept --note "Two lanes, one merged, one conflicted and stopped; the page has its footer and its tests." 2>&1 | tee -a "$R/timeline.txt"
  omarchy-agent-session-show "$S" --loop > "$R/loop-view.txt"; cat "$R/loop-view.txt"
  omarchy-agent-session-receipt "$S" > "$R/receipt.txt" 2>&1; cp "$HOME/.local/state/omarchy/sessions/$S/receipt.json" "$R/"
  cp "$HOME/.local/state/omarchy/sessions/$S/events.jsonl" "$R/"
  cat "$R/errors.txt" 2>/dev/null | sed 's/^/  err: /'
}

case "${1:-all}" in
  all) step_new; step_add; step_panel; step_send; step_conflict; step_done; step_finish ;;
  new|add|panel|send|conflict|done|finish) "step_$1" ;;
  *) echo "usage: run9.sh all|new|add|panel|send|conflict|done|finish"; exit 2 ;;
esac
