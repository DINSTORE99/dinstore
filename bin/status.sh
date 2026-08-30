#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/dinstore/config.env
os=$(. /etc/os-release; echo "$PRETTY_NAME")
ram=$(free -m | awk '/Mem:/{print $3" MB / "$2" MB"}')
ip=$(curl -4fsS --max-time 3 https://api.ipify.org 2>/dev/null || echo '-')
for svc in nginx xray openvpn-server@server dinstore-api; do systemctl is-active --quiet "$svc" && s='Running' || s='Stopped'; printf '%-24s %s\n' "$svc" "$s"; done
printf 'OS                       %s\nCPU                      %s\nRAM                      %s\nIP VPS                   %s\nSC ORDER                 %s\n' "$os" "$(nproc)" "$ram" "$ip" "${SC_ORDER:-@DINSTORE}"
