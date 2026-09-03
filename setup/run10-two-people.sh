#!/bin/bash
# Run 10: two people on one session, in proxy form (spec/12). The second
# person is the Mac driving the rig over ssh, which the commands report as
# human:omarchy@<mac> through SSH_CONNECTION; OMARCHY_ACTOR=human:sam@mac
# is the fallback when the client host does not resolve.
#
# Every step here runs over ssh from the Mac, so every command would see
# the ssh identity (omarchy@_gateway on this rig, from SSH_CONNECTION's
# reverse lookup). The "rig" steps therefore pin the rig's local identity,
# which is what the panel's own Processes carry; the "mac" steps run bare
# and get the ssh identity, the second person of this proxy.
#   ssh omarchy-rig 'OMARCHY_ACTOR=human:omarchy@omarchy bash run10.sh rig-new'
#   ssh omarchy-rig 'bash run10.sh mac-look'
#   ssh omarchy-rig 'OMARCHY_ACTOR=human:omarchy@omarchy bash run10.sh rig-grant'
#   ssh omarchy-rig 'bash run10.sh mac-suggest'
#   ssh omarchy-rig 'OMARCHY_ACTOR=human:omarchy@omarchy bash run10.sh rig-decide'
#   ssh omarchy-rig 'OMARCHY_ACTOR=human:omarchy@omarchy bash run10.sh rig-finish'
MAC_ACTOR=${MAC_ACTOR:-omarchy@_gateway}
NAME=${NAME:-shared-page}
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
R=/tmp/eval-run10; mkdir -p "$R"
ID=io.github.mphaxise.keepalive
log() { echo "$(date -u +%H:%M:%SZ) [$(python3 -c "import os;print(os.environ.get('OMARCHY_ACTOR') or 'local')")] $*" | tee -a "$R/timeline.txt"; }
sid() { cat "$R/sid"; }

case "${1:-}" in
rig-new)
  cd /home/omarchy/Work/spike-repo || exit 1
  SID=$(omarchy-agent-session-new --agent claude --mode personal --name "$NAME" --base session/loop-hello \
    --goal "hello.html: the owner decides, a second person suggests" --cwd "$PWD" 2>>"$R/errors.txt")
  echo "$SID" > "$R/sid"; log "session: $SID"
  DRAFT=$(omarchy-agent-session-new --agent claude --mode personal --name my-draft --no-worktree --cwd "$HOME/Work" 2>>"$R/errors.txt")
  echo "$DRAFT" > "$R/draft"; omarchy-agent-session-visibility "$DRAFT" draft | tee -a "$R/timeline.txt"
  ;;
mac-look)
  # Signal 1: the second person sees the shared session and never the draft.
  log "actor as the commands see it: $(python3 - <<'PY'
import os,socket
o=os.environ.get("OMARCHY_ACTOR"); s=os.environ.get("SSH_CONNECTION","")
print(o or ("ssh from " + s.split()[0] if s else "local"))
PY
)"
  omarchy-agent-session-list --json | python3 -c "import sys,json; [print('  sees', s['id'], s['name'], s['visibility']) for s in json.load(sys.stdin)['sessions'] if s['name'] in ('$NAME','my-draft')]" | tee -a "$R/timeline.txt"
  omarchy-agent-session-send "$(sid)" "Make the footer italic" 2>&1 | tee -a "$R/timeline.txt"; log "send without access rc=${PIPESTATUS[0]} (5 expected)"
  ;;
rig-grant)
  omarchy-agent-session-grant "$(sid)" --to "$MAC_ACTOR" --level suggest | tee -a "$R/timeline.txt"
  ;;
mac-suggest)
  # Signal 2: a suggestion waits; presence shows the second person.
  omarchy-agent-session-presence "$(sid)" --here | tee -a "$R/timeline.txt"
  omarchy-agent-session-send "$(sid)" "Make the footer italic. Commit with the message: italic footer, suggested. Do nothing else." --suggest 2>&1 | tee -a "$R/timeline.txt"; log "send --suggest rc=${PIPESTATUS[0]}"
  omarchy-agent-session-accept "$(sid)" 2>&1 | tee -a "$R/timeline.txt"; log "accept as the suggester rc=${PIPESTATUS[0]} (5 expected)"
  ;;
rig-decide)
  S=$(sid)
  omarchy-shell "$ID" open; sleep 3; grim "$R/panel-suggests.png"; log "captured panel-suggests (crop to the panel)"
  wtype y; sleep 3; grim "$R/panel-accepted.png"; log "captured panel-accepted"
  omarchy-shell "$ID" close
  sleep 30
  MAINWT=$(python3 -c "import json;print(json.load(open('$HOME/.local/state/omarchy/sessions/$S/session.json'))['workspace']['worktree_path'])")
  (cd "$MAINWT" && git log --oneline -3 | sed 's/^/  branch: /') | tee -a "$R/timeline.txt"
  grep -h "suggestion\|instruction.delivered\|access\|visibility" "$HOME/.local/state/omarchy/sessions/$S/events.jsonl" | python3 -c "import sys,json; [print('  event', (e:=json.loads(l))['ts'][11:19], e['type'], e['actor']['id'], {k:v for k,v in e['data'].items() if k in ('level','to','text')}) for l in sys.stdin]" | cut -c1-160 | tee -a "$R/timeline.txt"
  # Signal 3: assignment moves responsibility and nothing else.
  omarchy-agent-session-assign "$S" "$MAC_ACTOR" | tee -a "$R/timeline.txt"; log "assigned to $MAC_ACTOR"
  python3 -c "import json; d=json.load(open('$HOME/.local/state/omarchy/sessions/$S/session.json')); print('  owner', d['owner']['actor']['id'], 'access', [(a['actor']['id'], a['level']) for a in d['access']])" | tee -a "$R/timeline.txt"
  omarchy-shell "$ID" open; sleep 3; grim "$R/panel-owned-by.png"; log "captured panel-owned-by (the row names the owner when it is someone else)"; omarchy-shell "$ID" close
  # Signal 4: presence never reaches the record.
  grep -c presence "$HOME/.local/state/omarchy/sessions/$S/session.json" "$HOME/.local/state/omarchy/sessions/$S/events.jsonl" | sed 's/^/  presence mentions in the record: /' | tee -a "$R/timeline.txt"
  omarchy-agent-session-presence "$S" | sed 's/^/  present: /' | tee -a "$R/timeline.txt"
  ;;
rig-finish)
  S=$(sid)
  OMARCHY_ACTOR="human:$MAC_ACTOR" omarchy-agent-session-done "$S" --verdict kept --note "Suggested by the second person, accepted by the owner, landed." 2>&1 | tee -a "$R/timeline.txt"
  omarchy-agent-session-show "$S" --loop > "$R/loop-view.txt"; omarchy-agent-session-receipt "$S" > "$R/receipt.txt" 2>&1
  cp "$HOME/.local/state/omarchy/sessions/$S/events.jsonl" "$R/"
  omarchy-agent-session-stop "$(cat "$R/draft")" >/dev/null 2>&1
  cat "$R/errors.txt" 2>/dev/null | sed 's/^/  err: /'
  ;;
*) echo "usage: run10.sh rig-new|mac-look|rig-grant|mac-suggest|rig-decide|rig-finish"; exit 2 ;;
esac
