#!/bin/bash
# Run 13 on the rig: pause and prune (slice-4/pause, 2026-09-03).
# A live session pauses from the panel with one press of z (the harness
# exits, the pane closes, a checkpoint receipt is written, the worktree
# stays), sits in a Paused section with no window, and resumes on Enter
# with its transcript; prune is a dry run unless --yes and refuses what it
# must. Deploy first: rsync bin/, tests/, plugin/ to the checkout and the
# plugin dir; link omarchy-agent-session-pause and -prune into ~/.local/bin.
#
#   run13.sh all            every step in order
#   run13.sh <step>         one step: restart | new | pause | resume | prune | finish
#
# The session is created as the panel's own identity (OMARCHY_ACTOR), so
# the panel's z and Enter act with own access; run 10's rule would
# otherwise name the ssh client as the owner and refuse the panel.
#
# Evidence lands in /tmp/eval-run13; copy it to
# captures/evaluation-run13-pause_hands-on_arm-port_<date>/ and crop every
# capture to the panel before committing.
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
export OMARCHY_ACTOR="human:$USER@$(hostname -s)"
R=/tmp/eval-run13; mkdir -p "$R"
ID=io.github.mphaxise.keepalive
S=pause-page
log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }
panel_crop() { grim "$R/$1.png"; log "captured $1 (crop to the panel before committing)"; }
state() { omarchy-agent-session-show "$S" --json 2>/dev/null | python3 -c "import sys,json; s=json.load(sys.stdin)['session']; print(s['status']['state'], '·', s['status'].get('detail'), '· runtime', 'bound' if s.get('runtime') else 'none')"; }
sdir() { python3 -c "import json,glob; [print(p.rsplit('/',1)[0]) for p in glob.glob('$HOME/.local/state/omarchy/sessions/*/session.json') if json.load(open(p))['name']=='$S']" | tail -1; }
agents() { herdr agent list 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); a=d['result']['agents']; print('  herdr agents:', len(a), [(x['name'], x['agent_status']) for x in a])" | tee -a "$R/timeline.txt"; }

step_restart() {
  omarchy-restart-shell; sleep 8
  omarchy-shell "$ID" refresh; log "shell restarted, refresh probe rc=$?"
}

step_new() {
  MAIN=/home/omarchy/Work/spike-repo
  cd "$MAIN" || exit 1
  SID=$(omarchy-agent-session-new --agent claude --mode personal --name "$S" --base session/loop-hello \
    --goal "hello.html: pause and come back" --prompt "Say hello in one line and nothing else." --cwd "$MAIN" 2>>"$R/errors.txt")
  echo "$SID" > "$R/sid"; log "session: $SID"
  for i in 1 2 3 4 5 6 7 8; do sleep 3; st=$(state); log "  $S: $st"; case "$st" in idle*) break;; esac; done
  agents
}

step_pause() {
  # One press of z on the live row: the harness exits, the record waits.
  omarchy-shell "$ID" open; sleep 3; panel_crop panel-live-row
  wtype z; sleep 5; panel_crop panel-paused
  omarchy-shell "$ID" close
  log "after z: $S is $(state)"
  agents
  D=$(sdir); cp "$D/receipt.json" "$R/receipt-checkpoint.json"
  log "checkpoint receipt end_state: $(python3 -c "import json; print(json.load(open('$R/receipt-checkpoint.json'))['end_state'])")"
  WT=$(python3 -c "import json; print(json.load(open('$D/session.json'))['workspace']['worktree_path'])")
  log "worktree $WT $([ -d "$WT" ] && echo present || echo MISSING)"
}

step_resume() {
  # Enter on the paused row: the orphan path from paused, same harness ref.
  REF_BEFORE=$(python3 -c "import json; print(json.load(open('$(sdir)/session.json'))['agent']['harness_session_ref'])")
  omarchy-shell "$ID" open; sleep 3; wtype -k Return; sleep 2; omarchy-shell "$ID" close
  for i in 1 2 3 4 5 6 7 8 9 10; do sleep 3; st=$(state); log "  $S: $st"; case "$st" in idle*|waiting*|blocked*) break;; esac; done
  REF_AFTER=$(python3 -c "import json; print(json.load(open('$(sdir)/session.json'))['agent']['harness_session_ref'])")
  log "harness ref before ${REF_BEFORE:0:8}… after ${REF_AFTER:0:8}… $([ "$REF_BEFORE" = "$REF_AFTER" ] && echo same || echo DIFFERENT)"
  agents
  omarchy-agent-session-log "$S" --transcript 200 2>/dev/null | python3 -c "
import sys,ast
d=ast.literal_eval(sys.stdin.read().strip()); lines=[l.rstrip() for l in d['read']['text'].splitlines() if l.strip()]
print('non-empty lines:', len(lines)); [print('  ', l[:110]) for l in lines[-10:]]" | tee "$R/pane-after-resume.txt"
  omarchy-shell "$ID" open; sleep 3; panel_crop panel-resumed; omarchy-shell "$ID" close
}

step_prune() {
  # Dry run by default; refusals for a live session and for today. As the
  # panel's identity: the pre-run-10 records are its, the ssh identity's
  # are "someone else's" and stay kept, which is the rule at work.
  omarchy-agent-session-prune --older-than 30d 2>&1 | tee "$R/prune-dry-run-30d.txt"; log "prune --older-than 30d rc=${PIPESTATUS[0]} (dry run)"
  omarchy-agent-session-prune --session rig-smoke 2>&1 | tee "$R/prune-dry-run-one.txt"; log "prune --session rig-smoke rc=${PIPESTATUS[0]} (dry run, nothing deleted)"
  omarchy-agent-session-prune --session "$S" 2>&1 | tee -a "$R/prune-refusals.txt"; log "prune --session $S (live) rc=${PIPESTATUS[0]} (5 expected)"
  omarchy-agent-session-prune --older-than 2h 2>&1 | tee -a "$R/prune-refusals.txt"; log "prune --older-than 2h rc=${PIPESTATUS[0]} (2 expected)"
  log "records on disk: $(ls -1d $HOME/.local/state/omarchy/sessions/*/ | wc -l)"
}

step_finish() {
  omarchy-agent-session-stop "$S" 2>&1 | tee -a "$R/timeline.txt"; log "stop rc=${PIPESTATUS[0]}: $S is $(state)"
  agents
  D=$(sdir); cp "$D/events.jsonl" "$R/events.jsonl"
  omarchy-agent-session-show "$S" --loop > "$R/loop-view.txt" 2>&1
  log "done; evidence in $R"
}

case "${1:-all}" in
  all) step_restart; step_new; step_pause; step_resume; step_prune; step_finish ;;
  restart|new|pause|resume|prune|finish) "step_$1" ;;
  *) echo "usage: $0 [all|restart|new|pause|resume|prune|finish]" >&2; exit 2 ;;
esac
