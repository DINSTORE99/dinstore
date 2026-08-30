# DINSTORE VPN — rebuilt from zero

Installer/menu/API/backup dalam satu repository. Target: Ubuntu 20.04+ dan Debian 11+ x86_64 dengan systemd.

## Install

```bash
git clone https://github.com/DINSTORE99/dinstore.git
cd dinstore
chmod +x check.sh install.sh
./check.sh
sudo ./install.sh
```

Setelah install:

```bash
menu
systemctl status dinstore-api
systemctl status dinstore-backup.timer
```

## API

API bind ke `127.0.0.1:8080` secara default. Isi `API_KEY` di `/etc/dinstore/config.env`, restart service, lalu gunakan header `X-API-Key`.

Endpoint:

- `GET /health`
- `GET /api/v1/status`
- `GET /api/v1/users`
- `POST /api/v1/users`
- `GET /api/v1/backups`
- `POST /api/v1/backup`
- `POST /api/v1/backup/config`

API sengaja tidak diekspos ke internet secara default. Untuk website/bot, letakkan reverse proxy HTTPS + autentikasi tambahan di depan API.

## Backup

Backup manual:

```bash
/opt/dinstore/bin/backup.sh manual
```

Restore:

```bash
/opt/dinstore/bin/restore.sh /var/backups/dinstore/dinstore-YYYYMMDD-HHMMSS.tar.gz
```

Auto backup dijalankan oleh `dinstore-backup.timer` setiap hari pukul 03:30 dengan retention default 7 file. Ubah `BACKUP_TIME` di config lalu buat override systemd jika ingin jadwal berbeda.

## VPN

- Xray core: VLESS/VMess/Trojan dapat dikembangkan lewat config/API.
- OpenVPN: paket dan server base disiapkan; jalankan `make-openvpn-pki` untuk membuat PKI milik server.
- Nginx: dipasang sebagai reverse proxy layer.

Jangan commit private key, API key, sertifikat, atau database user ke GitHub.
