#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'root diperlukan'; exit 1; }
f=${1:-}; [[ -f "$f" ]] || { echo 'Usage: restore.sh /var/backups/dinstore/dinstore-YYYY...tar.gz'; exit 1; }
read -r -p 'Restore akan menimpa konfigurasi. Ketik RESTORE: ' ok
[[ "$ok" == RESTORE ]] || exit 1
tar -xzf "$f" -C /
systemctl daemon-reload
systemctl restart xray nginx dinstore-api 2>/dev/null || true
echo 'Restore selesai.'
