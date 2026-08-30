#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/dinstore"

echo "=============================================="
echo "        DINSTORE VPN INSTALLER"
echo "=============================================="

echo "[1/6] Membuat direktori..."

mkdir -p "$INSTALL_DIR"/{bin,api,lib,config,systemd}

echo "[2/6] Menyalin file installer..."

# File utama
[ -f "$BASE_DIR/install_xray.sh" ] &&
    cp "$BASE_DIR/install_xray.sh" "$INSTALL_DIR/install_xray.sh"

[ -f "$BASE_DIR/install_openvpn.sh" ] &&
    cp "$BASE_DIR/install_openvpn.sh" "$INSTALL_DIR/install_openvpn.sh"

# Library
[ -d "$BASE_DIR/lib" ] &&
    cp -r "$BASE_DIR/lib/." "$INSTALL_DIR/lib/"

# Config
[ -d "$BASE_DIR/config" ] &&
    cp -r "$BASE_DIR/config/." "$INSTALL_DIR/config/"

# API
[ -d "$BASE_DIR/api" ] &&
    cp -r "$BASE_DIR/api/." "$INSTALL_DIR/api/"

# Systemd
[ -d "$BASE_DIR/systemd" ] &&
    cp -r "$BASE_DIR/systemd/." "$INSTALL_DIR/systemd/"

# Bin
[ -d "$BASE_DIR/bin" ] &&
    cp -r "$BASE_DIR/bin/." "$INSTALL_DIR/bin/"

echo "[3/6] Memberikan permission..."

find "$INSTALL_DIR/bin" -type f -name "*.sh" -exec chmod +x {} \;

chmod +x "$INSTALL_DIR/install_xray.sh" 2>/dev/null || true
chmod +x "$INSTALL_DIR/install_openvpn.sh" 2>/dev/null || true

echo "[4/6] Menjalankan installer Xray..."

if [ -f "$INSTALL_DIR/install_xray.sh" ]; then
    bash "$INSTALL_DIR/install_xray.sh"
else
    echo "WARNING: install_xray.sh tidak ditemukan."
fi

echo "[5/6] Menjalankan installer OpenVPN..."

if [ -f "$INSTALL_DIR/install_openvpn.sh" ]; then
    bash "$INSTALL_DIR/install_openvpn.sh"
else
    echo "WARNING: install_openvpn.sh tidak ditemukan."
fi

echo "[6/6] Mengaktifkan menu..."

if [ -f "$INSTALL_DIR/bin/menu.sh" ]; then
    chmod +x "$INSTALL_DIR/bin/menu.sh"
    ln -sf "$INSTALL_DIR/bin/menu.sh" /usr/local/bin/menu
fi

hash -r 2>/dev/null || true

echo
echo "=============================================="
echo "          DINSTORE VPN INSTALLED"
echo "=============================================="
echo
echo "Menu : ketik menu"
echo "API  : http://127.0.0.1:8080"
echo "Config : /etc/dinstore"
echo "Backup : /var/backups/dinstore"
echo
echo "=============================================="

if command -v menu >/dev/null 2>&1; then
    menu
else
    echo "Menu belum tersedia."
    echo "Jalankan: bash /opt/dinstore/bin/menu.sh"
fi
