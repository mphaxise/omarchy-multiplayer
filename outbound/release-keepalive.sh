#!/bin/bash
# Cut a Keepalive release from this checkout: bump the manifest version,
# commit and tag here, build into a clone of the listing repository, and
# commit there with the source commit named. Pushing and the marketplace's
# verification form are printed as the next steps and never run here;
# each of them publishes and waits for Praneet's word.
#
#   outbound/release-keepalive.sh <version> [listing-clone]
#   outbound/release-keepalive.sh 0.2.0 ~/Work/omarchy-keepalive
#
# Rules this script enforces: the checkout is clean and on main; main is
# what ships (slice work lives on branches until its signals pass); the
# tag keepalive-v<version> marks the exact dev commit a listing was built
# from, so any release can be rebuilt.
set -euo pipefail

root=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
version=${1:?usage: release-keepalive.sh <version> [listing-clone]}
clone=${2:-$HOME/Work/omarchy-keepalive}
listing_url=https://github.com/mphaxise/omarchy-keepalive.git
id=io.github.mphaxise.keepalive
manifest=$root/plugin/$id/manifest.json

fail() { printf 'release-keepalive: %s\n' "$*" >&2; exit 1; }

[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "version must look like 0.2.0"
cd "$root"
[[ $(git branch --show-current) == main ]] || fail "release from main; slice work merges first"
[[ -z $(git status --porcelain --untracked-files=no) ]] || fail "the checkout has uncommitted changes"
git rev-parse -q --verify "refs/tags/keepalive-v$version" >/dev/null && fail "tag keepalive-v$version exists"

python3 -m unittest discover -s tests -p "test_*.py" >/dev/null 2>&1 || fail "tests fail; nothing released"

# Version in the manifest, committed and tagged here.
python3 - "$manifest" "$version" <<'PY'
import json, sys
path, version = sys.argv[1], sys.argv[2]
m = json.load(open(path)); m["version"] = version
json.dump(m, open(path, "w"), indent=2); open(path, "a").write("\n")
PY
git add "$manifest"
git commit -q -m "Keepalive $version" || true
git tag -a "keepalive-v$version" -m "Keepalive $version"
src_sha=$(git rev-parse --short HEAD)

# The listing clone: fresh or existing, with history kept.
if [[ ! -d $clone/.git ]]; then
  git clone -q "$listing_url" "$clone"
fi
git -C "$clone" fetch -q origin
git -C "$clone" checkout -q main
git -C "$clone" reset -q --hard origin/main

bash "$root/outbound/build-listing.sh" "$clone" >/dev/null
git -C "$clone" add -A
git -C "$clone" commit -q -m "Keepalive $version

Built from mphaxise/omarchy-multiplayer@$src_sha (tag keepalive-v$version)
by outbound/build-listing.sh." || fail "nothing changed in the listing; is this version already built?"
listing_sha=$(git -C "$clone" rev-parse HEAD)

cat <<MSG

Keepalive $version is built and committed locally.
  dev:      $root  tag keepalive-v$version at $src_sha
  listing:  $clone  commit $listing_sha

Next, each on Praneet's word:
  1. git -C "$root" push origin main --tags
  2. git -C "$clone" push origin main
  3. Marketplace: https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=verify-plugin.yml
     "Verify and publish a newer upstream commit": id $id, repo $listing_url, SHA $listing_sha
MSG
