#!/usr/bin/env bash
set -uo pipefail
if [ "$#" -ne 1 ]; then printf 'Pass one directory\n' >&2; exit 2; fi
out="$1"
if ! mkdir -p -- "$out"; then
  printf 'Cannot create output directory\n' >&2; exit 1
fi
file="$out/report-$(date +%Y%m%d-%H%M%S).txt"
run() { printf '\n## %s\n' "$1"; shift; "$@"; }
if ! {
  run TIME date -Is &&  
  run DISK df -h &&  
  run MEMORY free -h &&
  run PID1 ps -p 1 -o pid,comm &&
  run NETWORK ip -br addr &&
  run PORTS ss -lntup
} > "$file"; then
  printf 'Report command or write failed\n' >&2; exit 1
fi
printf 'Report: %s\n' "$file"
