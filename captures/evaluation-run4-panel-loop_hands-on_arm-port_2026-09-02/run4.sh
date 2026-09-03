#!/bin/bash
# Run 4 on the rig: the panel-side loop surfaces from spec/09, driven over
# ssh with the same argv the panel runs. Steps are separate so a failure
# in one leaves the evidence of the others.
#   run4.sh shell      restart the shell, prove IPC answers from new code
#   run4.sh new        new session loop-panel on the spike repo, register a preview
#   run4.sh preview    preview --focus twice (launch, then focus), capture --preview
#   run4.sh send       send --with-capture, wait for the commit, capture after
#   run4.sh open       open (terminal + preview focus), record the window stack
#   run4.sh panel      open the panel by IPC, capture it over the row
#   run4.sh keys       drive s / text / Enter and p through wtype if present
#   run4.sh finish     done --verdict kept, loop view, receipt, collect evidence
set -uo pipefail
export PATH=$HOME/.local/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
R=/tmp/eval-run4; mkdir -p "$R"
log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }
sid() { cat "$R/sid"; }
wt() { python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['workspace']['worktree_path'])" "$HOME/.local/state/omarchy/sessions/$(sid)/session.json"; }
active() { hyprctl activewindow -j | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('class'), d.get('address'), d.get('title','')[:40])"; }
clients() { hyprctl clients -j | python3 -c "import sys,json; [print('  ', c['class'], c['address'], c['at'], c['size']) for c in json.load(sys.stdin)]"; }

case "${1:-}" in
shell)
  log "restart shell"
  omarchy-restart-shell >/dev/null 2>&1; sleep 5
  pgrep -x quickshell >/dev/null || { log "shell not up, launching"; hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")' >/dev/null; sleep 5; }
  omarchy-shell praneet.agent-sessions refresh && log "ipc refresh ok"
  LOG=$(ls -t /run/user/1000/quickshell/by-id/*/log.log | head -1); echo "$LOG" > "$R/qslog"
  grep -c "agent-sessions" "$LOG" | sed 's/^/  agent-sessions log lines: /'
  grep -iE "error|warn" "$LOG" | grep -i "agent-sessions\|Panel.qml\|Session.qml" | tail -5
  ;;
new)
  MAIN=$(readlink -f "$(git -C ~/.herdr/worktrees/loop-hello rev-parse --git-common-dir)"); MAIN=${MAIN%/.git}
  log "spike repo: $MAIN"
  cd "$MAIN" || exit 1
  SID=$(omarchy-agent-session-new --agent claude --mode personal --name loop-panel \
    --goal "$(printf 'hello.html gets a footer line, sent from the panel with a capture of the page\nREADME.md and everything else stay untouched\nThe capture that travels with the instruction is the evidence')" \
    --cwd "$MAIN" 2>>"$R/errors.txt")
  echo "$SID" > "$R/sid"; log "session: $SID"
  sleep 12
  omarchy-agent-session-list | grep "$SID" | tee -a "$R/timeline.txt"
  PAGE="file://$(wt)/hello.html"
  omarchy-agent-session-preview "$SID" "$PAGE" && log "preview registered: $PAGE"
  omarchy-agent-session-list --json | python3 -c "import sys,json; d=json.load(sys.stdin); s=[x for x in d['sessions'] if x['id']=='$SID'][0]; print('  list entry preview:', s['preview'], 'loop:', s['loop'])" | tee -a "$R/timeline.txt"
  ;;
preview)
  SID=$(sid)
  log "preview --focus (no window yet)"; omarchy-agent-session-preview "$SID" --focus | tee -a "$R/timeline.txt"; sleep 9
  log "active: $(active)"
  log "preview --focus (window exists)"; omarchy-agent-session-preview "$SID" --focus | tee -a "$R/timeline.txt"; sleep 1
  log "active: $(active)"
  log "capture --preview"
  P=$(omarchy-agent-session-capture "$SID" --preview --label before-footer 2>>"$R/errors.txt"); log "capture: $P"
  python3 -c "import struct,sys; f=open(sys.argv[1],'rb'); f.read(16); w,h=struct.unpack('>II', f.read(8)); print('  capture size:', w, 'x', h)" "$P" | tee -a "$R/timeline.txt"
  cp "$P" "$R/before-footer.png"
  ;;
send)
  SID=$(sid)
  log "send --with-capture (the panel's argv, plus --wait so the script can see the commit)"
  omarchy-agent-session-send "$SID" "Add a footer line to hello.html that reads: sent from the sessions panel. Keep the heading and the date. Commit with the message: hello, footer from the panel. Do nothing else." --with-capture --wait --until idle --timeout 180000 2>&1 | tee -a "$R/timeline.txt"
  log "send rc=${PIPESTATUS[0]}"
  (cd "$(wt)" && git log --oneline -1 | sed 's/^/  commit: /' && sed 's/^/  page: /' hello.html) | tee -a "$R/timeline.txt"
  omarchy-agent-session-list --json | python3 -c "import sys,json; d=json.load(sys.stdin); s=[x for x in d['sessions'] if x['id']=='$SID'][0]; print('  loop:', s['loop'])" | tee -a "$R/timeline.txt"
  grep -h "instruction.delivered\|artifact.added" "$HOME/.local/state/omarchy/sessions/$SID/events.jsonl" | python3 -c "import sys,json; [print('  event:', (e:=json.loads(l))['kind'], {k:v for k,v in e.get('data',{}).items() if k in ('label','about_artifact','wait_timed_out','source')}) for l in sys.stdin]" | tee -a "$R/timeline.txt"
  ;;
open)
  SID=$(sid)
  log "open (terminal + preview focus)"
  omarchy-agent-session-open "$SID" 2>&1 | tee -a "$R/timeline.txt"; log "open rc=${PIPESTATUS[0]}"
  sleep 6
  log "active after open: $(active)"
  log "clients:"; clients | tee -a "$R/timeline.txt"
  grim "$R/after-open.png"
  ;;
panel)
  SID=$(sid)
  omarchy-shell praneet.agent-sessions refresh; sleep 2
  omarchy-shell praneet.agent-sessions open; sleep 3
  grim "$R/panel-row.png"; log "panel captured with the loop-panel row"
  LOG=$(cat "$R/qslog"); grep -i "agent-sessions" "$LOG" | tail -5 | sed 's/^/  qs: /'
  ;;
keys)
  SID=$(sid)
  if ! command -v wtype >/dev/null; then log "wtype not installed; the s / p key path waits for the sitting"; omarchy-shell praneet.agent-sessions close; exit 0; fi
  log "keys: s, text, Enter through wtype"
  wtype s; sleep 1; wtype "Also make the footer italic. Commit with the message: hello, italic footer. Do nothing else."; sleep 1; wtype -k Return
  sleep 25
  omarchy-agent-session-list --json | python3 -c "import sys,json; d=json.load(sys.stdin); s=[x for x in d['sessions'] if x['id']=='$SID'][0]; print('  loop after keys:', s['loop'])" | tee -a "$R/timeline.txt"
  omarchy-shell praneet.agent-sessions open; sleep 3; wtype p; sleep 2
  log "active after p: $(active)"
  ;;
finish)
  SID=$(sid)
  sleep 5
  omarchy-agent-session-done "$SID" --verdict kept --note "Footer sent from the panel's argv with a capture of the page; the instruction carries the capture it was about. Kept." 2>&1 | tee -a "$R/timeline.txt"
  omarchy-agent-session-show "$SID" --loop > "$R/loop-view.txt"; cat "$R/loop-view.txt"
  omarchy-agent-session-receipt "$SID" > "$R/receipt.txt" 2>&1
  cp "$HOME/.local/state/omarchy/sessions/$SID/events.jsonl" "$R/events.jsonl"
  cp -r "$HOME/.local/state/omarchy/sessions/$SID/artifacts" "$R/artifacts"
  cp "$HOME/.local/state/omarchy/sessions/$SID/receipt.json" "$R/receipt.json" 2>/dev/null
  cat "$R/errors.txt" 2>/dev/null | sed 's/^/  err: /'
  ;;
redo)
  # The first loop-panel branched from main, which never had hello.html
  # (the run-3 commits live on session/loop-hello); the agent asked where
  # the footer should go and went blocked, which is the right behaviour
  # and the wrong scenario. Stop it, close its preview window, start
  # again from session/loop-hello.
  OLD=$(sid)
  log "redo: stopping $OLD (blocked on a question the scenario caused)"
  omarchy-agent-session-stop "$OLD" 2>&1 | tee -a "$R/timeline.txt"
  for a in $(hyprctl clients -j | python3 -c "import sys,json; [print(c['address']) for c in json.load(sys.stdin) if c['class'].startswith('chrome-__home_omarchy_.herdr_worktrees_loop-panel_')]"); do
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$a\" })" >/dev/null; sleep 1; hyprctl dispatch "hl.dsp.window.close()" >/dev/null; sleep 1
  done
  MAIN=/home/omarchy/Work/spike-repo
  cd "$MAIN" || exit 1
  SID=$(omarchy-agent-session-new --agent claude --mode personal --name loop-panel2 --base session/loop-hello \
    --goal "$(printf 'hello.html gets a footer line, sent from the panel with a capture of the page\nREADME.md and everything else stay untouched\nThe capture that travels with the instruction is the evidence')" \
    --cwd "$MAIN" 2>>"$R/errors.txt")
  echo "$SID" > "$R/sid"; log "session: $SID (base session/loop-hello)"
  sleep 12
  omarchy-agent-session-list | grep "$SID" | tee -a "$R/timeline.txt"
  ls "$(wt)" | sed 's/^/  worktree file: /' | tee -a "$R/timeline.txt"
  PAGE="file://$(wt)/hello.html"
  omarchy-agent-session-preview "$SID" "$PAGE" && log "preview registered: $PAGE"
  ;;
*) echo "usage: run4.sh shell|new|preview|send|open|panel|keys|finish|redo"; exit 2 ;;
esac
