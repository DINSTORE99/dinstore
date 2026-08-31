#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 IP DAYS [LABEL]"
  echo "Example: $0 1.2.3.4 30 CLIENT-01"
  exit 1
fi

IP="$1"
DAYS="$2"
LABEL="${3:-CLIENT}"

[[ "$DAYS" =~ ^[0-9]+$ ]] || { echo "DAYS harus angka."; exit 1; }
[[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo "IP IPv4 tidak valid."; exit 1; }

EXP=$(date -d "+${DAYS} days" +%Y-%m-%d)
printf '%s|%s|%s\n' "$IP" "$EXP" "$LABEL"
