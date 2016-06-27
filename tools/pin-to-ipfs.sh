#!/usr/bin/env bash
set -e
set -o pipefail

cd "$(dirname "$(readlink -f "$0")")"

cleanup() {
  excode=$?
  rm -rf "$TMPDIR"
  trap - EXIT
  exit $excode
}
TMPDIR="$(mktemp -d)"
trap cleanup EXIT HUP INT QUIT PIPE TERM

CONCURRENT_LOG_DIR=$TMPDIR/logs
source concurrent.lib.sh

TOPDIR="$(pwd)"
while [ ! -d "$TOPDIR/pkgs" ]; do
  TOPDIR="$(dirname "$TOPDIR")"
done

cp pin-to-ipfs-hashes "$TMPDIR/hashes"
REV="$(cat pin-to-ipfs-rev)"
pushd "$TOPDIR" >/dev/null
while read obj; do
  git cat-file --batch | sed -n 's,.*"\(Qm[a-zA-Z0-9]*\)".*,\1,p' >> "$TMPDIR/hashes"
done < <(git rev-list "$REV"..HEAD --objects | grep '\.nix$' | awk '{print $1}')
popd >/dev/null
cat "$TMPDIR/hashes" | sort | uniq > "$TMPDIR/hashes.tmp"

if ! diff -q "$TMPDIR/hashes.tmp" pin-to-ipfs-hashes >/dev/null 2>&1; then
  cp "$TMPDIR/hashes.tmp" pin-to-ipfs-hashes
  git rev-list HEAD^..HEAD > pin-to-ipfs-rev
fi

declare -A current
while read h; do
  current["$h"]=1
done < <(ipfs pin ls -t recursive | awk '{print $1}' | sort | uniq)

fetch() {
  ipfs pin add "$1"
}

ARGS=()
while read HASH; do
  if [ "${current[$HASH]}" != "1" ]; then
    ARGS+=("-" "$HASH" "fetch" "$HASH")
  fi
done < <(cat pin-to-ipfs-hashes)
if [ "${#ARGS[@]}" -gt "0" ]; then
  concurrent "${ARGS[@]}"
fi
