#!/bin/bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DINSTORE_ROOT="$ROOT_DIR"
LOG_FILE=/root/dinstore-vpn-install.log
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo; echo "[ERROR] Instalasi berhenti pada baris $LINENO. Log: $LOG_FILE"; exit 1' ERR

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Jalankan sebagai root: sudo ./install.sh"
    exit 1
  fi
}

check_platform() {
  [[ -r /etc/os-release ]] || { echo "Tidak dapat membaca /etc/os-release"; exit 1; }
  . /etc/os-release
  case "${ID:-}" in
    debian|ubuntu) ;;
    *)
      echo "OS tidak didukung: ${PRETTY_NAME:-unknown}"
      echo "Gunakan Debian 11/12/13 atau Ubuntu 20.04/22.04/24.04 64-bit."
      exit 1
      ;;
  esac
  [[ "$(uname -m)" == "x86_64" ]] || { echo "Arsitektur harus x86_64, terdeteksi: $(uname -m)"; exit 1; }
  command -v systemctl >/dev/null 2>&1 || { echo "systemctl/systemd diperlukan."; exit 1; }
  command -v apt-get >/dev/null 2>&1 || { echo "apt-get diperlukan."; exit 1; }
}

check_files() {
  local f
  while IFS= read -r -d '' f; do
    [[ -e "$f" ]] || { echo "File hilang: ${f#$ROOT_DIR/}"; return 1; }
  done < <(printf '%s\0' \
    "$ROOT_DIR/components/noobzvpn/install.sh" \
    "$ROOT_DIR/components/noobzvpn/noobzvpns.x86_64" \
    "$ROOT_DIR/components/noobzvpn/noobzvpns.service" \
    "$ROOT_DIR/components/noobzvpn/config.json" \
    "$ROOT_DIR/components/vip/setup.sh" \
    "$ROOT_DIR/components/vip/update.sh" \
    "$ROOT_DIR/components/vip/Cdy/menu.zip" \
    "$ROOT_DIR/components/vip/Enc/encrypt" \
    "$ROOT_DIR/components/vip/Cfg/config.json")
}

install_noobz() {
  echo
  echo "========== INSTALL NOOBZVPN =========="
  chmod +x "$ROOT_DIR/components/noobzvpn/install.sh"
  "$ROOT_DIR/components/noobzvpn/install.sh"
  systemctl daemon-reload
  systemctl enable --now noobzvpns.service
  if ! systemctl is-active --quiet noobzvpns.service; then
    echo "NoobzVPN gagal aktif. Menampilkan status:"
    systemctl --no-pager -l status noobzvpns.service || true
    return 1
  fi
  echo "NoobzVPN: ACTIVE"
}

install_vip() {
  echo
  echo "========== INSTALL VIP =========="
  chmod +x "$ROOT_DIR/components/vip/setup.sh"
  "$ROOT_DIR/components/vip/setup.sh"
}

main() {
  require_root
  check_platform
  check_files

  echo "=============================================="
  echo "        DINSTORE VPN - INSTALLER"
  echo "=============================================="
  echo "OS   : ${PRETTY_NAME:-unknown}"
  echo "ARCH : $(uname -m)"
  echo "ROOT : $ROOT_DIR"
  echo
  echo "1) NoobzVPN saja"
  echo "2) VIP stack saja"
  echo "3) NoobzVPN + VIP stack"
  echo "0) Keluar"
  echo
  read -r -p "Pilih [0-3]: " choice

  case "$choice" in
    1) install_noobz ;;
    2) install_vip ;;
    3) install_noobz; install_vip ;;
    0) exit 0 ;;
    *) echo "Pilihan tidak valid."; exit 1 ;;
  esac

  echo
  echo "=============================================="
  echo "INSTALASI SELESAI"
  echo "Log: $LOG_FILE"
  echo "=============================================="
}

main "$@"
