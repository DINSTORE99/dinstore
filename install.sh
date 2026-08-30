#!/usr/bin/env bash
set -e

BASE="/root/dinstore"
OPT="/opt/dinstore"

clear

echo "=============================================="
echo "          DINSTORE VPN INSTALLER"
echo "=============================================="
echo

echo "[1/7] Membuat directory..."
mkdir -p "$OPT"/{api,bin,config,lib,systemd}
mkdir -p /etc/dinstore
mkdir -p /var/backups/dinstore

echo "[2/7] Menyalin API..."
cp -f "$BASE/api/server.py" "$OPT/api/server.py"

echo "[3/7] Menyalin script..."
cp -f "$BASE/bin/"*.sh "$OPT/bin/"

echo "[4/7] Menyalin installer..."
cp -f "$BASE/install_xray.sh" "$OPT/install_xray.sh"
cp -f "$BASE/install_openvpn.sh" "$OPT/install_openvpn.sh"

echo "[5/7] Menyalin library dan systemd..."
cp -f "$BASE/lib/"*.sh "$OPT/lib/" 2>/dev/null || true
cp -f "$BASE/systemd/"*.service "$OPT/systemd/" 2>/dev/null || true
cp -f "$BASE/systemd/"*.timer "$OPT/systemd/" 2>/dev/null || true

echo "[6/7] Mengatur permission..."

chmod +x "$OPT/bin/"*.sh
chmod +x "$OPT/install_xray.sh"
chmod +x "$OPT/install_openvpn.sh"

# Command global
ln -sf "$OPT/bin/menu.sh" /usr/local/bin/menu
ln -sf "$OPT/bin/status.sh" /usr/local/bin/dinstore-status
ln -sf "$OPT/bin/backup.sh" /usr/local/bin/dinstore-backup
ln -sf "$OPT/bin/restore.sh" /usr/local/bin/dinstore-restore

# Systemd
cp -f "$BASE/systemd/dinstore-api.service" \
    /etc/systemd/system/dinstore-api.service 2>/dev/null || true

cp -f "$BASE/systemd/dinstore-backup.service" \
    /etc/systemd/system/dinstore-backup.service 2>/dev/null || true

cp -f "$BASE/systemd/dinstore-backup.timer" \
    /etc/systemd/system/dinstore-backup.timer 2>/dev/null || true

systemctl daemon-reload

echo "[7/7] Mengaktifkan service..."

systemctl enable nginx 2>/dev/null || true

if [ -f /etc/systemd/system/dinstore-api.service ]; then
    systemctl enable --now dinstore-api.service 2>/dev/null || \
    systemctl restart dinstore-api.service 2>/dev/null || true
fi

if [ -f /etc/systemd/system/dinstore-backup.timer ]; then
    systemctl enable --now dinstore-backup.timer 2>/dev/null || true
fi

# Auto menu ketika login SSH
cat > /etc/profile.d/dinstore.sh <<'EOF'
# DINSTORE AUTO MENU
if [ -t 1 ] && [ -x /opt/dinstore/bin/menu.sh ]; then
    /opt/dinstore/bin/menu.sh
fi
EOF

chmod 644 /etc/profile.d/dinstore.sh

clear

echo "============================================================"
echo "                 DINSTORE VPN INSTALLED"
echo "============================================================"
echo
echo "  Menu   : menu"
echo "  API    : http://127.0.0.1:8080"
echo "  Config : /etc/dinstore"
echo "  Backup : /var/backups/dinstore"
echo
echo "============================================================"
echo "              MEMBUKA DINSTORE MENU..."
echo "============================================================"
sleep 2

# Langsung masuk ke SC
exec "$OPT/bin/menu.sh"
