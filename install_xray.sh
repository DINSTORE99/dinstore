#!/usr/bin/env bash
set -Eeuo pipefail
command -v jq >/dev/null || apt-get update && apt-get install -y curl jq unzip ca-certificates
mkdir -p /etc/xray /usr/local/bin
json=$(curl -fsSL https://api.github.com/repos/XTLS/Xray-core/releases/latest)
url=$(printf '%s' "$json" | jq -r '.assets[] | select(.name|test("Xray-linux-64.zip$")) | .browser_download_url' | head -1)
[[ -n "$url" && "$url" != null ]] || { echo 'Asset Xray x86_64 tidak ditemukan'; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fL "$url" -o "$tmp/xray.zip"
unzip -oq "$tmp/xray.zip" -d "$tmp/xray"
install -m 0755 "$tmp/xray/xray" /usr/local/bin/xray
mkdir -p /var/log/xray
cat > /etc/xray/config.json <<'JSON'
{
  "log": {"loglevel":"warning","access":"/var/log/xray/access.log","error":"/var/log/xray/error.log"},
  "inbounds": [
    {"listen":"127.0.0.1","port":10085,"protocol":"vless","settings":{"clients":[],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/vless"}}}
  ],
  "outbounds":[{"protocol":"freedom","settings":{}}]
}
JSON
if ! id xray >/dev/null 2>&1; then useradd --system --no-create-home --shell /usr/sbin/nologin xray; fi
chown -R xray:xray /etc/xray /var/log/xray
cat > /etc/systemd/system/xray.service <<'UNIT'
[Unit]
Description=Xray Service
After=network-online.target
Wants=network-online.target
[Service]
User=xray
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
