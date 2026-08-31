#!/usr/bin/env bash
set -Eeuo pipefail

REPO_RAW="https://raw.githubusercontent.com/DINSTORE99/dinstore/main/license/licenses.txt"
LICENSE_DIR="/etc/dinstore"
LICENSE_FILE="$LICENSE_DIR/license"
mkdir -p "$LICENSE_DIR"

get_ip() { curl -4 -fsS --max-time 10 https://api.ipify.org; }

check() {
  local ip data line exp label today
  ip="${1:-$(get_ip)}"
  data=$(curl -4 -fsS --max-time 15 "$REPO_RAW")
  line=$(printf '%s\n' "$data" | awk -F'|' -v ip="$ip" '$1 == ip {print; exit}')
  [[ -n "$line" ]] || { echo "NOT REGISTERED: $ip"; return 1; }
  IFS='|' read -r _ exp label <<< "$line"
  date -d "$exp" +%s >/dev/null 2>&1 || { echo "INVALID DATE: $exp"; return 1; }
  today=$(date +%Y-%m-%d)
  if (( $(date -d "$exp" +%s) < $(date -d "$today" +%s) )); then
    echo "EXPIRED: $ip ($exp)"
    return 1
  fi
  printf '%s\n' "$line" > "$LICENSE_FILE"
  chmod 600 "$LICENSE_FILE"
  echo "ACTIVE: $ip | $exp | ${label:--}"
}

case "${1:-check}" in
  check) check "${2:-}" ;;
  *) echo "Usage: $0 check [IP]"; exit 2 ;;
esac
