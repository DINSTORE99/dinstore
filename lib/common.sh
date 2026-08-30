#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
DIN_DIR=/opt/dinstore
CFG_DIR=/etc/dinstore
BACKUP_DIR=/var/backups/dinstore
log(){ printf '\033[1;36m[DINSTORE]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; exit 1; }
require_root(){ [[ $EUID -eq 0 ]] || die 'Jalankan sebagai root/sudo.'; }
check_os(){ [[ -f /etc/os-release ]] || die 'OS tidak didukung.'; . /etc/os-release; case "$ID" in ubuntu|debian) ;; *) die "OS $ID belum didukung. Gunakan Ubuntu/Debian.";; esac; (( ${VERSION_ID%%.*} >= 20 )) || die 'Versi OS terlalu lama.'; command -v systemctl >/dev/null || die 'systemd diperlukan.'; }
check_arch(){ [[ "$(uname -m)" == x86_64 ]] || die 'Saat ini hanya x86_64 yang didukung.'; }
install_dependencies(){ apt-get update; apt-get install -y curl ca-certificates jq unzip tar gzip openssl python3 python3-venv python3-pip nginx openvpn easy-rsa ufw cron; }
install_xray(){ bash "$DIN_ROOT/install_xray.sh"; }
install_openvpn(){ bash "$DIN_ROOT/install_openvpn.sh"; }
install_dinstore_files(){
 mkdir -p "$DIN_DIR" "$CFG_DIR" "$BACKUP_DIR" /var/lib/dinstore
 cp -a "$DIN_ROOT/bin/." "$DIN_DIR/bin/"
 cp -a "$DIN_ROOT/api/." "$DIN_DIR/api/"
 cp -a "$DIN_ROOT/config/." "$CFG_DIR/"
 cp -a "$DIN_ROOT/systemd/." /etc/systemd/system/
 chmod 700 "$DIN_DIR/bin" "$CFG_DIR" "$BACKUP_DIR"
 chmod +x "$DIN_DIR/bin/"*.sh "$DIN_DIR/api/server.py"
 [[ -f "$CFG_DIR/config.env" ]] || cp "$DIN_ROOT/config/config.env.example" "$CFG_DIR/config.env"
 source "$CFG_DIR/config.env"
 if [[ -z "${API_KEY:-}" ]]; then sed -i "s/^API_KEY=.*/API_KEY=$(openssl rand -hex 32)/" "$CFG_DIR/config.env"; source "$CFG_DIR/config.env"; fi
 [[ -f "$CFG_DIR/users.json" ]] || printf '{"users":[]}\n' > "$CFG_DIR/users.json"
 sed -i "s|^DIN_ROOT=.*|DIN_ROOT=$DIN_ROOT|" "$CFG_DIR/config.env" 2>/dev/null || true
 cp "$DIN_ROOT/install_xray.sh" "$DIN_ROOT/install_openvpn.sh" "$DIN_DIR/" || true
}
install_services(){
 systemctl daemon-reload
 systemctl enable --now nginx
 systemctl enable --now xray || warn 'Xray belum aktif; periksa /etc/xray/config.json.'
 systemctl enable --now dinstore-api
 configure_backup_timer
 systemctl enable --now dinstore-backup.timer
}
configure_firewall(){ ufw allow OpenSSH >/dev/null 2>&1 || true; ufw allow 80/tcp >/dev/null 2>&1 || true; ufw allow 443/tcp >/dev/null 2>&1 || true; ufw --force enable >/dev/null 2>&1 || true; }
configure_backup_timer(){
 local t=${BACKUP_TIME:-03:30}
 if [[ $t =~ ^([01][0-9]|2[0-3]):([0-5][0-9])$ ]]; then
   local h=${BASH_REMATCH[1]} m=${BASH_REMATCH[2]}
   sed -i -E "s/^OnCalendar=.*/OnCalendar=*-*-* ${h}:${m}:00/" /etc/systemd/system/dinstore-backup.timer
 else
   warn "BACKUP_TIME tidak valid; memakai 03:30"
 fi
 systemctl daemon-reload
}

print_done(){
 echo; printf '\033[1;35m============================================================\033[0m\n'; printf '                 DINSTORE VPN INSTALLED\n'; printf '\033[1;35m============================================================\033[0m\n';
 echo '  Menu       : menu'; echo '  API        : http://127.0.0.1:8080'; echo '  Config     : /etc/dinstore'; echo '  Backup     : /var/backups/dinstore'; echo; echo '  Cek status : systemctl --type=service | grep dinstore'; echo '  Cek backup : systemctl status dinstore-backup.timer'; echo; }
