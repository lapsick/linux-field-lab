#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s OUTPUT_DIRECTORY\n' "$0" >&2
  exit 2
fi
out="$1"
if mkdir -p -- "$out"; then
  :
else
  status=$?
  printf 'Cannot create output directory: %s (mkdir exit %s)\n' "$out" "$status" >&2
  exit 1
fi

if timestamp=$(date +%Y%m%d-%H%M%S); then
  :
else
  status=$?
  printf 'Cannot obtain timestamp (exit %s)\n' "$status" >&2
  exit "$status"
fi
file="$out/report-$timestamp-$$.txt"
if exec 3> "$file"; then
  :
else
  status=$?
  printf 'Cannot write report in directory: %s (open exit %s)\n' "$out" "$status" >&2
  exit 1
fi

run() {
  printf '\n## %s\n' "$1" || return "$?"
  shift
  "$@"
}

if {
  run TIME date -Is &&
  run DISK df -h &&
  run MEMORY free -h &&
  run PID1 ps -p 1 -o pid,comm &&
  run NETWORK ip -br addr &&
  run PORTS ss -lntup
} >&3; then
  exec 3>&-
else
  status=$?
  exec 3>&-
  printf 'Report command or write failed (exit %s): %s\n' "$status" "$file" >&2
  exit "$status"
fi
printf 'Report: %s\n' "$file"
