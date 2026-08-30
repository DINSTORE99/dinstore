#!/usr/bin/env bash
set -Eeuo pipefail
R="$(cd "$(dirname "$0")" && pwd)"; fail=0
for f in "$R/install.sh" "$R/install_xray.sh" "$R/install_openvpn.sh" "$R/bin/backup.sh" "$R/bin/restore.sh" "$R/bin/status.sh" "$R/bin/menu.sh"; do bash -n "$f" || fail=1; done
python3 -m py_compile "$R/api/server.py" || fail=1
[[ -f "$R/config/config.env.example" ]] || fail=1
((fail==0)) && echo 'DINSTORE project check: OK' || { echo 'DINSTORE project check: FAILED'; exit 1; }
