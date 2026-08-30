#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DINSTORE_ROOT="$ROOT_DIR"

NOOBZ="$ROOT_DIR/components/noobzvpn/install.sh"
VIP="$ROOT_DIR/components/vip/setup.sh"

if [ "$(id -u)" -ne 0 ]; then
  echo "Jalankan sebagai root: sudo ./install.sh"
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "Tidak dapat mendeteksi OS."
  exit 1
fi

. /etc/os-release
case "${ID:-}" in
  debian|ubuntu) ;;
  *)
    echo "OS tidak didukung: ${PRETTY_NAME:-unknown}"
    echo "Gunakan Debian/Ubuntu 64-bit."
    exit 1
    ;;
esac

if [ "$(uname -m)" != "x86_64" ]; then
  echo "Arsitektur tidak didukung: $(uname -m)"
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "Systemd/systemctl tidak tersedia. Gunakan VPS Debian/Ubuntu dengan systemd."
  exit 1
fi

for required in "$NOOBZ" "$ROOT_DIR/components/noobzvpn/noobzvpns.x86_64" "$VIP" "$ROOT_DIR/components/vip/Cdy/menu.zip" "$ROOT_DIR/components/vip/Enc/encrypt" "$ROOT_DIR/components/vip/Cfg/config.json"; do
  if [ ! -e "$required" ]; then
    echo "File project tidak lengkap: $required"
    exit 1
  fi
done

chmod +x "$VIP" "$NOOBZ"

cat <<'BANNER'
==============================================
       DINSTORE VPN - UNIFIED PROJECT
==============================================
1) Install NoobzVPN saja
2) Install VIP stack
3) Install semuanya
0) Keluar
BANNER

read -r -p "Pilih [0-3]: " CHOICE

case "$CHOICE" in
  1)
    "$NOOBZ"
    systemctl enable --now noobzvpns.service
    ;;
  2)
    "$VIP"
    ;;
  3)
    echo
    echo "[1/2] Install NoobzVPN"
    "$NOOBZ"
    systemctl enable --now noobzvpns.service
    echo
    echo "[2/2] Install VIP stack"
    "$VIP"
    ;;
  0)
    exit 0
    ;;
  *)
    echo "Pilihan tidak valid."
    exit 1
    ;;
esac

echo
echo "Instalasi selesai."
