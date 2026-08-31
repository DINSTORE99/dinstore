#!/usr/bin/env bash
set -Eeuo pipefail

RAW="https://raw.githubusercontent.com/DINSTORE99/dinstore/main"
GREEN='\033[1;32m'; CYAN='\033[1;36m'; RED='\033[1;31m'; RESET='\033[0m'

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}           DINSTORE UPDATE${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

apt-get update -y
apt-get install -y curl wget p7zip-full || true

mkdir -p /opt/dinstore/bin /opt/dinstore/license

fetch() {
    local src="$1" dst="$2"
    echo -e "${CYAN}Updating ${dst}${RESET}"
    curl -4 -fsSL "$RAW/$src" -o "$dst"
}

fetch "setup.sh" "/root/dinstore-setup.sh"
fetch "license.sh" "/opt/dinstore/license.sh"
fetch "license/licenses.txt" "/opt/dinstore/license/licenses.txt"

# Menu tetap mengikuti paket Cdy/menu.zip dari repository.
if curl -4 -fsSL "$RAW/Cdy/menu.zip" -o /tmp/dinstore-menu.zip; then
    rm -rf /tmp/dinstore-menu
    mkdir -p /tmp/dinstore-menu
    if 7z x -y -p'pas123@Newbie' /tmp/dinstore-menu.zip -o/tmp/dinstore-menu >/dev/null 2>&1; then
        chmod +x /tmp/dinstore-menu/* 2>/dev/null || true
        cp -af /tmp/dinstore-menu/* /usr/local/sbin/ 2>/dev/null || true
    fi
    rm -rf /tmp/dinstore-menu /tmp/dinstore-menu.zip
fi

chmod +x /opt/dinstore/license.sh 2>/dev/null || true

ln -sf /usr/local/sbin/menu /usr/local/bin/menu 2>/dev/null || true
hash -r 2>/dev/null || true

echo
echo -e "${GREEN}Update DINSTORE selesai.${RESET}"
echo
if command -v menu >/dev/null 2>&1; then
    exec menu
fi
