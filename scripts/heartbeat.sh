#!/usr/bin/env bash
trap 'printf "stopped\n"; exit 0' TERM INT
while true; do
  date -Is
  sleep 5 & wait $!
done
