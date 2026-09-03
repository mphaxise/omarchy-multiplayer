#!/bin/bash
# Assemble the public listing repository for the Omarchy plugin marketplace
# from this checkout: the plugin files at the root (where omarchy plugin add
# and the marketplace expect manifest.json), the commands, the units, the
# tests, the license, the preview, install.sh and uninstall.sh, and the
# README with the plugin id filled in. Also writes the submission issue body.
#
#   outbound/build-listing.sh [output-dir]                 default /tmp/omarchy-agent-sessions
#   LISTING_ID=io.github.mphaxise.agent-sessions outbound/build-listing.sh
#
# The output directory is created fresh; an existing one is reused only when
# this script built it (it leaves a marker), so a stray path is never emptied.
# Nothing here touches git remotes or GitHub; publishing is a separate,
# approved step.

set -euo pipefail

root=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
out=${1:-/tmp/omarchy-agent-sessions}
src_id=praneet.agent-sessions
id=${LISTING_ID:-$src_id}
marker=.built-by-build-listing

fail() { printf 'build-listing: %s\n' "$*" >&2; exit 1; }

[[ $id =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $id != *..* && $id != omarchy.* ]] || fail "invalid plugin id: $id"

if [[ -e $out ]]; then
  [[ -f $out/$marker ]] || fail "$out exists and was not built by this script; choose another path"
  rm -rf "$out"
fi
mkdir -p "$out"

# Plugin files at the root.
cp "$root/plugin/$src_id/Panel.qml" "$root/plugin/$src_id/Session.qml" "$root/plugin/$src_id/manifest.json" "$out/"
cp -R "$root/plugin/$src_id/scripts" "$out/scripts"

# Commands, units, tests, license.
mkdir -p "$out/bin" "$out/systemd" "$out/tests"
for f in "$root"/bin/omarchy-agent-session*; do [[ -f $f ]] && cp "$f" "$out/bin/"; done
cp "$root"/systemd/*.service "$out/systemd/"
for f in "$root"/tests/*.py; do cp "$f" "$out/tests/"; done
cp "$root/LICENSE" "$out/LICENSE"

# Listing-only files.
cp "$root/outbound/listing/install.sh" "$root/outbound/listing/uninstall.sh" "$root/outbound/listing/preview.png" "$out/"
sed "s/@PLUGIN_ID@/$id/g" "$root/outbound/listing/README.md" > "$out/README.md"

# The id: manifest, and the widget's module and IPC names.
if [[ $id != "$src_id" ]]; then
  python3 - "$out/manifest.json" "$id" <<'PY'
import json, sys
path, new_id = sys.argv[1], sys.argv[2]
m = json.load(open(path))
m["id"] = new_id
json.dump(m, open(path, "w"), indent=2)
open(path, "a").write("\n")
PY
  sed -i.bak -e "s/moduleName: \"$src_id\"/moduleName: \"$id\"/" -e "s/ipcTarget: \"$src_id\"/ipcTarget: \"$id\"/" "$out/Panel.qml"
  rm -f "$out/Panel.qml.bak"
fi

chmod +x "$out"/bin/* "$out"/scripts/* "$out/install.sh" "$out/uninstall.sh"
find "$out" -name __pycache__ -type d -prune -exec rm -rf {} +

# The submission body with the id filled in, next to the draft that explains it.
sed -n '/^```markdown$/,/^```$/p' "$root/outbound/submission-issue.md" | sed '1d;$d' | sed "s/@PLUGIN_ID@/$id/g" > "$root/outbound/submission-issue-body.md"

touch "$out/$marker"

echo "built $out with id $id"
if command -v omarchy-plugin-validate >/dev/null; then
  omarchy-plugin-validate "$out" && echo "omarchy-plugin-validate: ok"
else
  echo "validate on an Omarchy machine:  omarchy plugin validate $out"
fi
( cd "$out" && find . -path ./.git -prune -o -type f -print | sort )
