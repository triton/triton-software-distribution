#!/usr/bin/env bash
set -e
set -o pipefail

RW_GATEWAYS=(
  "https://ipfs.works"
  "https://ipfs.work"
)
RO_GATEWAYS=(
  "${RW_GATEWAYS[@]}"
  "https://ipfs.io"
  "https://hardbin.com"
  "https://ipfs.wak.io"
)

# Save our arguments usefully
SCRIPT="$(readlink -f "$0")"
URLS=("$@")

# Print out usage if needed
if [ "${#URLS[@]}" -eq "0" ]; then
  echo "Usage: $SCRIPT [urls to add...]" >&2
  exit 1
fi

# Setup the temporary storage area
TMPDIR=""
cleanup() {
  CODE="$?"
  echo "Cleaning up..." >&2
  if [ -n "$TMPDIR" ]; then
    rm -rf "$TMPDIR"
  fi
  trap - EXIT ERR INT QUIT PIPE TERM
  exit "$CODE"
}
trap cleanup EXIT ERR INT QUIT PIPE TERM
TMPDIR="$(mktemp -d /tmp/ipfs-upload.XXXXXXXXXX)"

# Include the concurrent library
source "$(dirname "$SCRIPT")/concurrent.lib.sh"
CONCURRENT_LOG_DIR="$TMPDIR/logs"

cd "$TMPDIR"

# Concurrent file handling stuff
open_hash_file() {
  exec 9<> "$TMPDIR"/mh
}

close_hash_file() {
  exec 9>&-
}

write_hash() {
  local n="$1"
  local hash="$2"

  flock -x 9
  echo "$n $hash" >&9
  flock -u 9
}

write_status() {
  flock -x 9
  echo "$1" >>"$TMPDIR"/status
  flock -u 9
}

find_hash() {
  local n="$1"

  flock -s 9
  grep "^$n " "$TMPDIR"/mh | awk '{print $2}'
  flock -u 9
}

# Concurrent functions
fetch() {
  local n="$1"
  local url="$2"

  curl -v -L "$url" -o "$TMPDIR/$n"
}

upload_fail() {
  echo "$gw failed" >&3
  write_status "$gw failed to upload $url"
}

upload() {
  local n="$1"
  local url="$2"

  local gw
  for gw in "${RW_GATEWAYS[@]}"; do
    local output
    if ! output="$(curl -svL "$gw/ipfs/" -X POST --data-binary "@$TMPDIR/$n" 2>&1)"; then
      upload_fail
      continue
    fi
    local mh
    if ! mh="$(echo "$output" | grep '^< ipfs-hash: ' | tr -d '\r' | awk '{print $3}')"; then
      upload_fail
      continue
    fi
    if [ -z "$mh" ]; then
      upload_fail
      continue
    fi

    echo "$mh" >&3
    write_hash "$n" "$mh"
    return 0
  done
  return 1
}

verify() {
  local n="$1"
  local gw="$2"

  local mh
  mh="$(find_hash "$n")"

  local sha256
  if ! sha256="$(curl -L "$gw/ipfs/$mh" | sha256sum | awk '{print $1}')"; then
    echo "Failed to download the file" >&2
    return 1
  fi

  if [ "$sha256" != "$(sha256sum "$TMPDIR"/"$n" | awk '{print $1}')" ]; then
    echo "Hashes don't match" >&2
    return 1
  fi
}

ARGS=()
n=0
for url in "${URLS[@]}"; do
  f="Fetch $url"
  ARGS+=("-" "$f" fetch "$n" "$url")
  u="Upload $url"
  ARGS+=("-" "$u" upload "$n" "$url")
  ARGS+=("--require" "$f" "--before" "$u")
  for gw in "${RO_GATEWAYS[@]}"; do
    v="Verify $url $gw"
    ARGS+=("-" "$v" verify "$n" "$gw")
    ARGS+=("--require" "$u" "--before" "$v")
  done
  n=$(( $n + 1 ))
done

open_hash_file
concurrent "${ARGS[@]}"
echo ""
echo "#######################"
n=0
for url in "${URLS[@]}"; do
  mh="$(find_hash "$n")"
  echo "$mh -> $url"
  n=$(( $n + 1 ))
done
close_hash_file
