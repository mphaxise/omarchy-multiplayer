#!/bin/bash
# Run 14: two people, two machines, one session (spec/12, for real).
# Every step runs ON THE RIG (the host). The host steps run in a rig terminal
# or over ssh from Praneet's Mac; the guest steps run over ssh from the
# friend's VM, which is what makes him the second person:
#
#   host  (rig terminal):  bash ~/Work/omarchy-multiplayer/setup/run14-two-hosts.sh host-new
#   guest (friend's VM):   ssh omarchy@<RIG> 'FRIEND=alex FRIEND_HOST=alex-vm bash ~/Work/omarchy-multiplayer/setup/run14-two-hosts.sh guest-look'
#
# Order: host-new, guest-look, host-grant, guest-suggest, [y on the panel],
# host-accepted, host-ask, host-assign, guest-answer (herdr --remote from the
# friend's VM), guest-done, host-finish. Evidence lands in /tmp/eval-run14.
#
# FRIEND and FRIEND_HOST name the second person on every surface as
# human:<FRIEND>@<FRIEND_HOST>; without them the guest would be
# omarchy@<his ip>, and both people would read as "omarchy".
set -uo pipefail
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH
export $(systemctl --user show-environment 2>/dev/null | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs)
R=/tmp/eval-run14; mkdir -p "$R"
ID=io.github.mphaxise.keepalive
HOST_ACTOR=human:omarchy@omarchy
# The guest names himself once (FRIEND, FRIEND_HOST on his first step); the
# host steps read the names back from $R/guest so nobody retypes them.
if [[ -z ${FRIEND:-} && -f $R/guest ]]; then read -r FRIEND FRIEND_HOST < "$R/guest"; fi
FRIEND=${FRIEND:-friend}; FRIEND_HOST=${FRIEND_HOST:-guest-vm}
GUEST_ACTOR="human:$FRIEND@$FRIEND_HOST"
NAME=${NAME:-pair-page}
S() { cat "$R/sid"; }
log() { echo "$(date -u +%H:%M:%SZ) [${OMARCHY_ACTOR:-local}] $*" | tee -a "$R/timeline.txt"; }
panel_capture() { omarchy-shell "$ID" open; sleep 3; grim "$R/$1.png"; log "captured $1 (crop to the panel before committing)"; omarchy-shell "$ID" close; }
state() { python3 -c "import json; print(json.load(open('$HOME/.local/state/omarchy/sessions/$1/session.json'))['status']['state'])"; }

case "${1:-}" in
host-new)
  export OMARCHY_ACTOR=$HOST_ACTOR
  cd /home/omarchy/Work/spike-repo || exit 1
  SID=$(omarchy-agent-session-new --agent claude --mode personal --name "$NAME" --base session/loop-hello \
    --goal "$(printf 'hello.html gains a footer from two people on two machines\nThe owner decides; the guest suggests, then owns')" --cwd "$PWD" 2>>"$R/errors.txt")
  echo "$SID" > "$R/sid"; log "session: $SID ($NAME)"
  DRAFT=$(omarchy-agent-session-new --agent claude --mode personal --name my-draft --no-worktree --cwd "$HOME/Work" 2>>"$R/errors.txt")
  echo "$DRAFT" > "$R/draft"; omarchy-agent-session-visibility "$DRAFT" draft | tee -a "$R/timeline.txt"
  sleep 12; omarchy-agent-session-list | grep -E "$NAME|my-draft" | tee -a "$R/timeline.txt"
  panel_capture panel-host-two-sessions
  ;;
guest-look)
  # Signal 1: the guest sees the shared session and never the draft; send is refused.
  export OMARCHY_ACTOR=$GUEST_ACTOR; echo "$FRIEND $FRIEND_HOST" > "$R/guest"
  log "guest is $OMARCHY_ACTOR, ssh from ${SSH_CONNECTION:-no ssh}"
  omarchy-agent-session-list --json | python3 -c "import sys,json; [print('  sees', s['id'], s['name'], s['visibility'], 'owner', s['owner']['id']) for s in json.load(sys.stdin)['sessions'] if s['name'] in ('$NAME','my-draft')]" | tee -a "$R/timeline.txt"
  omarchy-agent-session-send "$(S)" "Make the footer italic" 2>&1 | tee -a "$R/timeline.txt"; log "send without access rc=${PIPESTATUS[0]} (5 expected)"
  ;;
host-grant)
  export OMARCHY_ACTOR=$HOST_ACTOR
  omarchy-agent-session-grant "$(S)" --to "$FRIEND@$FRIEND_HOST" --level suggest | tee -a "$R/timeline.txt"
  ;;
guest-suggest)
  # Signal 2, first half: the suggestion waits; presence shows the guest.
  export OMARCHY_ACTOR=$GUEST_ACTOR
  omarchy-agent-session-presence "$(S)" --here | tee -a "$R/timeline.txt"
  omarchy-agent-session-send "$(S)" "Add a footer line to hello.html that says: Built by two people. Commit with the message: footer, suggested. Do nothing else." --suggest 2>&1 | tee -a "$R/timeline.txt"; log "send --suggest rc=${PIPESTATUS[0]}"
  omarchy-agent-session-accept "$(S)" 2>&1 | tee -a "$R/timeline.txt"; log "accept as the guest rc=${PIPESTATUS[0]} (5 expected)"
  log "now the host opens the panel: the row should read '$FRIEND suggests …' with y and d; press y"
  ;;
host-accepted)
  # Run after y was pressed on the panel: signal 2, second half.
  export OMARCHY_ACTOR=$HOST_ACTOR
  panel_capture panel-host-after-accept
  grep -h "suggestion\|instruction.delivered\|access" "$HOME/.local/state/omarchy/sessions/$(S)/events.jsonl" | python3 -c "import sys,json; [print('  event', (e:=json.loads(l))['ts'][11:19], e['type'], e['actor']['id']) for l in sys.stdin]" | tee -a "$R/timeline.txt"
  sleep 40; (cd "$(python3 -c "import json;print(json.load(open('$HOME/.local/state/omarchy/sessions/$(S)/session.json'))['workspace']['worktree_path'])")" && git log --oneline -2 | sed 's/^/  branch: /') | tee -a "$R/timeline.txt"
  ;;
host-ask)
  # A question the guest will answer from his machine.
  export OMARCHY_ACTOR=$HOST_ACTOR
  omarchy-agent-session-send "$(S)" "Before you change anything else, ask me which color the footer text should be, blue or green, and wait for my answer. Then set it and commit with the message: footer color, answered from the other machine." 2>&1 | tee -a "$R/timeline.txt"
  for i in $(seq 1 24); do sleep 5; st=$(state "$(S)"); [[ $st == blocked ]] && break; done
  log "state after the ask: $st (blocked expected)"
  panel_capture panel-host-blocked
  ;;
host-assign)
  # Signal 3: responsibility moves, access does not.
  export OMARCHY_ACTOR=$HOST_ACTOR
  omarchy-agent-session-assign "$(S)" "$FRIEND@$FRIEND_HOST" | tee -a "$R/timeline.txt"
  python3 -c "import json; d=json.load(open('$HOME/.local/state/omarchy/sessions/$(S)/session.json')); print('  owner', d['owner']['actor']['id'], 'access', [(a['actor']['id'], a['level']) for a in d['access']])" | tee -a "$R/timeline.txt"
  panel_capture panel-host-owned-by-guest
  log "guest: from your VM run   herdr --remote omarchy@<RIG>   attach to the $NAME workspace, answer the question in the pane, detach (ctrl+b d or Herdr's leave key)"
  ;;
guest-answer)
  # The path run 10 could not test: a second person answers a blocked agent
  # from another machine. The attach itself happens on the guest's VM; this
  # step only watches the record while he does it.
  export OMARCHY_ACTOR=$GUEST_ACTOR
  log "waiting for the agent to leave blocked (the guest is attached through herdr --remote)"
  for i in $(seq 1 60); do sleep 5; st=$(state "$(S)"); [[ $st != blocked ]] && break; done
  log "state now: $st"
  for i in $(seq 1 24); do sleep 5; st=$(state "$(S)"); [[ $st == idle ]] && break; done
  log "state now: $st (idle expected once the commit is in)"
  (cd "$(python3 -c "import json;print(json.load(open('$HOME/.local/state/omarchy/sessions/$(S)/session.json'))['workspace']['worktree_path'])")" && git log --oneline -3 | sed 's/^/  branch: /') | tee -a "$R/timeline.txt"
  omarchy-agent-session-presence "$(S)" | sed 's/^/  present: /' | tee -a "$R/timeline.txt"
  ;;
guest-done)
  # The guest ends the session he now owns.
  export OMARCHY_ACTOR=$GUEST_ACTOR
  omarchy-agent-session-done "$(S)" --verdict kept --note "Suggested from my machine, accepted at the host's panel, answered from my machine, ended by me." 2>&1 | tee -a "$R/timeline.txt"; log "done as the guest rc=${PIPESTATUS[0]}"
  omarchy-agent-session-presence "$(S)" --leave >/dev/null 2>&1
  ;;
host-finish)
  export OMARCHY_ACTOR=$HOST_ACTOR
  omarchy-agent-session-show "$(S)" --loop > "$R/loop-view.txt"; cat "$R/loop-view.txt"
  omarchy-agent-session-receipt "$(S)" > "$R/receipt.txt" 2>&1; grep -A6 "^People\|^Owner" "$R/receipt.txt"
  cp "$HOME/.local/state/omarchy/sessions/$(S)/events.jsonl" "$R/"
  grep -c presence "$HOME/.local/state/omarchy/sessions/$(S)/session.json" "$HOME/.local/state/omarchy/sessions/$(S)/events.jsonl" | sed 's/^/  presence mentions in the record: /' | tee -a "$R/timeline.txt"
  omarchy-agent-session-stop "$(cat "$R/draft")" >/dev/null 2>&1
  panel_capture panel-host-done
  cat "$R/errors.txt" 2>/dev/null | sed 's/^/  err: /'
  ;;
*) echo "usage: run14-two-hosts.sh host-new|guest-look|host-grant|guest-suggest|host-accepted|host-ask|host-assign|guest-answer|guest-done|host-finish"; exit 2 ;;
esac
