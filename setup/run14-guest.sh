#!/bin/bash
# Run 14, guest side: everything the second person runs on his own Omarchy VM.
#
#   bash run14-guest.sh check      Wi-Fi address, the rig on port 22, the tools
#   bash run14-guest.sh install    Keepalive from the public listing, then verify
#   bash run14-guest.sh part1      guided: one session, close, send, receipt, pause, history
#   bash run14-guest.sh part1b     after the reboot: the orphaned row, Enter, capture
#   bash run14-guest.sh pair       your key onto the rig, then a check
#   bash run14-guest.sh look       guest-look on the rig, under your name
#   bash run14-guest.sh suggest    guest-suggest on the rig
#   bash run14-guest.sh answer     herdr --remote to the rig; answer-ssh is the fallback
#   bash run14-guest.sh watch      guest-answer: watches the record while you answer
#   bash run14-guest.sh finish     guest-done: you end the session you now own
#   bash run14-guest.sh story      the session's loop view, any time
#   bash run14-guest.sh part3      ten minutes alone, with a notes prompt
#   bash run14-guest.sh remove     uninstall Keepalive
#
# Asks once for RIG (the host's address), FRIEND, and FRIEND_HOST, and keeps
# them in ~/eval-run14/guest.env. Nothing here needs root, and nothing here
# types a password for you: ssh-copy-id asks for the rig's once.
set -u
E=$HOME/eval-run14; mkdir -p "$E"; ENV="$E/guest.env"
ID=io.github.mphaxise.keepalive
LISTING=https://github.com/mphaxise/omarchy-keepalive
NAME=pair-page
# shellcheck disable=SC1090
[[ -f $ENV ]] && . "$ENV"
export PATH=$HOME/.local/bin:/usr/share/omarchy/bin:$PATH

ask() { local v=$1 p=$2 cur=${3:-} x; read -r -p "$p${cur:+ [$cur]}: " x; printf -v "$v" '%s' "${x:-$cur}"; }
names() {
  ask RIG "Praneet's rig address" "${RIG:-}"
  ask FRIEND "Your name, as the panel should show it" "${FRIEND:-}"
  ask FRIEND_HOST "A name for this VM" "${FRIEND_HOST:-}"
  printf 'RIG=%q\nFRIEND=%q\nFRIEND_HOST=%q\n' "$RIG" "$FRIEND" "$FRIEND_HOST" > "$ENV"
  echo "  saved to $ENV"
}
need_names() { [[ -n ${RIG:-} && -n ${FRIEND:-} && -n ${FRIEND_HOST:-} ]] || names; }
wayland() { export $(systemctl --user show-environment 2>/dev/null | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|OMARCHY_PATH)=" | xargs); }
ok() { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; }
step() { echo; echo "== $1"; }
pause() { read -r -p "  ...press Enter when done "; }
capture() {
  wayland; omarchy-shell "$ID" open; sleep 3
  grim "$E/panel-$1.png" && echo "  captured $E/panel-$1.png"
  omarchy-shell "$ID" close
  omarchy-agent-session-list > "$E/list-$1.txt" 2>&1
}
rig() { ssh "omarchy@$RIG" "FRIEND=$(printf %q "$FRIEND") FRIEND_HOST=$(printf %q "$FRIEND_HOST") bash ~/Work/omarchy-multiplayer/setup/run14-two-hosts.sh $1"; }

case "${1:-}" in
names) names ;;
check)
  need_names
  step "your address on the Wi-Fi"; ip -4 -br addr | grep -v "^lo" | sed 's/^/  /'
  step "the rig at $RIG"
  if (exec 3<>"/dev/tcp/$RIG/22") 2>/dev/null; then ok "port 22 answers"; else bad "no answer on $RIG:22 (same Wi-Fi? VM bridged?)"; fi
  step "tools"
  for c in omarchy claude git grim herdr; do command -v "$c" >/dev/null && ok "$c" || bad "$c missing"; done
  [[ -d $HOME/scratch/.git ]] && ok "~/scratch repo" || echo "  note  ~/scratch repo missing; install makes it"
  ;;
install)
  step "scratch repo"
  if [[ ! -d $HOME/scratch/.git ]]; then
    (git init -q "$HOME/scratch" && cd "$HOME/scratch" && echo hi > hello.md && git add . && git commit -q -m start && echo "  made ~/scratch")
  fi
  step "Keepalive from $LISTING"
  omarchy plugin add "$LISTING" --enable 2>&1 | tee -a "$E/install.log"
  "$HOME/.config/omarchy/plugins/$ID/install.sh" 2>&1 | tee -a "$E/install.log"
  step "verify"
  n=$(ls "$HOME"/.local/bin/omarchy-agent-session-* 2>/dev/null | wc -l)
  (( n > 0 )) && ok "$n commands in ~/.local/bin" || bad "no commands linked"
  for u in omarchy-agent-session-herdr omarchy-agent-session-watch; do
    systemctl --user is-active --quiet "$u" && ok "$u active" || bad "$u not active"
  done
  wayland
  if omarchy-shell "$ID" refresh >/dev/null 2>&1; then ok "panel answers"
  else
    echo "  restarting the shell"; omarchy-restart-shell; sleep 3
    omarchy-shell "$ID" refresh >/dev/null 2>&1 && ok "panel answers" || bad "panel silent; tell Praneet"
  fi
  grep -m1 '"version"' "$HOME/.config/omarchy/plugins/$ID/manifest.json" | sed 's/^/  /'
  echo; echo "Look at the top bar: a robot icon should be there."
  ;;
part1)
  step "1. Click the robot in the bar. Press n, type: add a README that lists the files, commit it. Press Enter."; pause; capture 1
  step "2. Close the agent's terminal window. Click the robot again: the session should still be listed."; pause; capture 2
  step "3. Press s on the row and send a second instruction. When it finishes, press r for the receipt."; pause; capture 3
  step "4. Press z to pause it, then Enter to resume it."; pause; capture 4
  step "5. Press e to open History, then close it."; pause; capture 5
  echo; echo "Now reboot (Omarchy menu > System > Restart). When it is back: bash $0 part1b"
  ;;
part1b)
  step "6. Click the robot: the session shows as orphaned."; pause; capture 6
  step "7. Press Enter on it: the agent comes back on its own transcript."; pause; capture 7
  echo; echo "Part 1 done. Captures and list output are in $E."
  ;;
pair)
  need_names
  step "your key onto the rig (type the rig password once)"; ssh-copy-id "omarchy@$RIG"
  step "check"; ssh -o BatchMode=yes -o ConnectTimeout=5 "omarchy@$RIG" hostname && ok "key login works" || bad "key login failed"
  ;;
look) need_names; rig guest-look ;;
suggest) need_names; rig guest-suggest ;;
watch) need_names; rig guest-answer ;;
finish) need_names; rig guest-done ;;
answer)
  need_names
  echo "Pick the $NAME workspace, click into the agent's pane, type the answer, press Enter, then detach as the status line says."
  if command -v herdr >/dev/null; then herdr --remote "omarchy@$RIG"; else echo "  no herdr here"; fi
  echo; echo "If that refused to connect: bash $0 answer-ssh"
  ;;
answer-ssh) need_names; ssh -t "omarchy@$RIG" herdr ;;
story) need_names; ssh "omarchy@$RIG" omarchy-agent-session-show "$NAME" --loop ;;
part3)
  step "Ten minutes on your own, on this VM"
  echo "  Start a second session with n. Press a on it and give a second agent its own task."
  echo "  Press w to walk between the two. Press x twice to stop one. Close the panel, open it again."
  echo; echo "Type every word that did not mean what you expected, and everything you pressed that did nothing. One per line; an empty line finishes."
  while read -r -p "  > " line && [[ -n $line ]]; do echo "$(date +%H:%M) $line" >> "$E/notes.txt"; done
  echo "  saved to $E/notes.txt"
  ;;
remove)
  read -r -p "Remove Keepalive from this VM? [y/N] " a; [[ $a == y ]] || exit 0
  "$HOME/.config/omarchy/plugins/$ID/uninstall.sh"; omarchy plugin remove "$ID"
  echo "Session records stay in ~/.local/state/omarchy/sessions/"
  ;;
*) sed -n '2,20p' "$0"; exit 2 ;;
esac
