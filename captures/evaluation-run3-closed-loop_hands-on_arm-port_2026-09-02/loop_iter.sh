#!/bin/bash
# One closed-loop iteration on the rig, per spec/09: capture the preview,
# send an instruction tied to that capture, wait for the harness, relaunch
# the preview window, capture the result.
# Usage: loop_iter.sh <session-id> <n> "<instruction>"
set -uo pipefail
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
L=$1; N=$2; INSTR=$3
R=/tmp/eval-run3
URL=file:///home/omarchy/.herdr/worktrees/loop-hello/hello.html
CLASS_PREFIX="chrome-__home_omarchy_.herdr_worktrees_loop-hello_hello.html"

log() { echo "$(date -u +%H:%M:%SZ) $*" | tee -a "$R/timeline.txt"; }

relaunch_preview() {
  for i in 1 2 3; do
    addr=$(hyprctl clients -j | python3 -c "import sys,json; cs=[c for c in json.load(sys.stdin) if c['class'].startswith('$CLASS_PREFIX')]; print(cs[0]['address'] if cs else '')")
    [ -z "$addr" ] && break
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null 2>&1
    sleep 1
    hyprctl dispatch "hl.dsp.window.close()" >/dev/null
    sleep 2
  done
  setsid -f omarchy-launch-webapp "$URL" >/dev/null 2>&1 < /dev/null
  sleep 9
}

log "iteration $N: capture before"
grim "$R/iter$N-before.png"
BEFORE=$(omarchy-agent-session-capture "$L" --file "$R/iter$N-before.png" --label "iter$N-before")
log "before artifact: $BEFORE"
log "iteration $N: send (about the before capture): $INSTR"
omarchy-agent-session-send "$L" "$INSTR" --about "$BEFORE" --wait --timeout 150000
log "send rc=$?"
(cd ~/.herdr/worktrees/loop-hello && git log --oneline -1 | sed 's/^/  commit: /' && sed 's/^/  page: /' hello.html) | tee -a "$R/timeline.txt"
relaunch_preview
grim "$R/iter$N-after.png"
AFTER=$(omarchy-agent-session-capture "$L" --file "$R/iter$N-after.png" --label "iter$N-after")
log "after artifact: $AFTER"
