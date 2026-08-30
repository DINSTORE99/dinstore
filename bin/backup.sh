#!/usr/bin/env bash
set -Eeuo pipefail
CFG=/etc/dinstore/config.env
source "$CFG"
BACKUP_DIR=/var/backups/dinstore
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
ts=$(date +%Y%m%d-%H%M%S); out="$BACKUP_DIR/dinstore-$ts.tar.gz"
tar --ignore-failed-read -czf "$out" /etc/dinstore /etc/xray /etc/openvpn /etc/nginx /var/lib/dinstore 2>/dev/null
chmod 600 "$out"
ret=${BACKUP_RETENTION:-7}; find "$BACKUP_DIR" -type f -name 'dinstore-*.tar.gz' -printf '%T@ %p\n' | sort -nr | awk -v n="$ret" 'NR>n{print $2}' | xargs -r rm -f
printf '%s\n' "$out"
