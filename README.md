# DINSTORE VPN

Unified installer untuk komponen **NoobzVPN** dan **VIP stack** dalam satu repository.

## Dukungan

- Debian 11/12/13, 64-bit x86_64
- Ubuntu 20.04/22.04/24.04, 64-bit x86_64
- VPS wajib menggunakan systemd dan apt
- Jalankan sebagai `root` atau melalui `sudo`
- Internet diperlukan untuk paket Debian/Ubuntu dan beberapa dependency upstream

## Instalasi

```bash
git clone https://github.com/DINSTORE99/dinstore.git
cd dinstore
chmod +x check.sh install.sh
./check.sh
sudo ./install.sh
```

Pilih:

```text
1 = NoobzVPN
2 = VIP stack
3 = NoobzVPN + VIP stack
```

## Setelah instalasi

NoobzVPN:

```bash
systemctl status noobzvpns --no-pager
journalctl -u noobzvpns -n 100 --no-pager
```

VIP/Xray:

```bash
systemctl status xray --no-pager
systemctl status nginx --no-pager
systemctl status haproxy --no-pager
```

Log installer:

```bash
tail -n 100 /root/dinstore-vpn-install.log
```

## Catatan domain

VIP stack meminta domain saat instalasi. Domain harus sudah diarahkan ke IP VPS sebelum proses SSL dijalankan. Port 80/443 harus dapat diakses dari internet.

## Catatan keamanan

Jangan menyimpan token Telegram, password, private key, atau credential cloud di repository GitHub. Konfigurasi yang membutuhkan credential harus diisi setelah repository di-clone.

## Struktur

```text
DINSTORE-VPN/
├── install.sh
├── check.sh
├── README.md
├── .gitignore
├── components/
│   ├── noobzvpn/
│   ├── vip/
│   └── izin/
```
