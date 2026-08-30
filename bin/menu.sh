#!/usr/bin/env bash
set -Eeuo pipefail
R=/opt/dinstore/bin
RED='\033[1;31m'; BLUE='\033[1;34m'; GREEN='\033[1;32m'; CYAN='\033[1;36m'; RESET='\033[0m'
while true; do clear
printf '%b\n' "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
printf '%b\n' "${RED}║                 BY DINSTORE                 ║${RESET}"
printf '%b\n' "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"
$R/status.sh
printf '%b\n' "${BLUE}──────────────────────────────────────────────────────${RESET}"
printf '%b\n' "${CYAN}[1] SSH / OPENVPN          [6] BACKUP / RESTORE${RESET}"
printf '%b\n' "${CYAN}[2] VLESS / XRAY           [7] AUTO BACKUP${RESET}"
printf '%b\n' "${CYAN}[3] VMESS / XRAY            [8] UPDATE${RESET}"
printf '%b\n' "${CYAN}[4] TROJAN / XRAY           [9] SYSTEM${RESET}"
printf '%b\n' "${CYAN}[5] API / USERS             [10] RESTART SERVICES${RESET}"
printf '\n%b' "${GREEN}Select Options [1-10 / Enter to exit]: ${RESET}"; read -r op; [[ -z "$op" ]] && exit 0
case "$op" in
1) echo 'OpenVPN: jalankan make-openvpn-pki lalu buat client sesuai kebutuhan.'; read -r -p 'Enter...' ;;
2|3|4) echo 'Xray core aktif. Tambahkan client melalui API /api/v1/xray/clients atau config JSON.'; read -r -p 'Enter...' ;;
5) echo '1) Add SSH user  2) Delete SSH user  3) List users'; read -r -p '> ' x; case $x in 1) read -r -p 'Username: ' u; read -r -p 'Days: ' d; $R/user.sh add "$u" "${d:-30}";; 2) read -r -p 'Username: ' u; $R/user.sh del "$u";; 3) $R/user.sh list;; esac; read -r -p 'Enter...' ;;
6) echo '1) Backup  2) Restore'; read -r -p '> ' x; [[ $x == 1 ]] && $R/backup.sh manual; [[ $x == 2 ]] && { read -r -p 'File backup: ' f; $R/restore.sh "$f"; }; read -r -p 'Enter...' ;;
7) systemctl status dinstore-backup.timer --no-pager; read -r -p 'Enter...' ;;
8) apt-get update && apt-get install --only-upgrade xray nginx openvpn -y || true; read -r -p 'Enter...' ;;
9) systemctl --failed --no-pager; read -r -p 'Enter...' ;;
10) systemctl restart nginx xray dinstore-api; read -r -p 'Enter...' ;;
esac
done
