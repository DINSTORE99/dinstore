#!/usr/bin/env bash
set -Eeuo pipefail
CFG=/etc/dinstore/users.json
mkdir -p "$(dirname "$CFG")"; [[ -f "$CFG" ]] || echo '{"users":[]}' > "$CFG"
add(){
 local u=${1:?username}; local days=${2:-30}
 [[ $u =~ ^[a-zA-Z][a-zA-Z0-9_.-]{2,31}$ ]] || { echo 'Username tidak valid'; exit 1; }
 id "$u" >/dev/null 2>&1 && { echo 'Username sudah ada'; exit 1; }
 local pw; pw=$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 10)
 useradd -M -s /usr/sbin/nologin "$u"; echo "$u:$pw" | chpasswd
 local exp; exp=$(date -d "+$days days" +%s)
 tmp=$(mktemp); jq --arg u "$u" --arg p "$pw" --argjson e "$exp" '.users += [{username:$u,type:"ssh",password:$p,expires_at:$e,created_at:now|floor}]' "$CFG" > "$tmp"; mv "$tmp" "$CFG"; chmod 600 "$CFG"
 echo "username=$u"; echo "password=$pw"; echo "expires=$(date -d @$exp '+%Y-%m-%d')"
}
del(){ local u=${1:?username}; id "$u" >/dev/null 2>&1 && userdel "$u" || true; local tmp=$(mktemp); jq --arg u "$u" '.users |= map(select(.username != $u))' "$CFG" > "$tmp"; mv "$tmp" "$CFG"; }
case "${1:-}" in add) add "$2" "${3:-30}";; del) del "$2";; list) jq -r '.users[]? | [.username,.type,.expires_at] | @tsv' "$CFG";; *) echo 'Usage: user.sh add USER [DAYS] | del USER | list'; exit 1;; esac
