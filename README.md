# DINSTORE VPN — Unified VPS Project

Satu repository untuk komponen **VIP**, **NoobzVPN**, dan data izin. File komponen yang dibutuhkan installer disimpan di repository ini sehingga installer tidak bergantung pada repository DINSTORE lain untuk file lokal.

## Persyaratan VPS

- Debian/Ubuntu 64-bit (`x86_64`)
- Root / sudo
- Systemd
- Koneksi internet
- Untuk fitur SSL/Xray: domain milik sendiri yang sudah mengarah ke IP VPS

## Upload ke GitHub

Upload **isi folder `DINSTORE-VPN`**, bukan file ZIP. Pastikan repository tidak berisi token, private key, password, atau credential cloud.

## Cek project sebelum upload

```bash
chmod +x check.sh
./check.sh
```

Jika hasilnya `DINSTORE-VPN repository check: OK`, struktur dan syntax script dasar sudah lolos pemeriksaan.

## Install

```bash
git clone https://github.com/USERNAME/DINSTORE-VPN.git
cd DINSTORE-VPN
chmod +x install.sh
sudo ./install.sh
```

Menu installer:

- `1` — NoobzVPN saja
- `2` — VIP stack
- `3` — NoobzVPN + VIP stack

Installer menggunakan path relatif terhadap folder repository, jadi lokasi hasil `git clone` tidak harus `/root`.

## Setelah install

NoobzVPN:

```bash
systemctl status noobzvpns.service --no-pager
journalctl -u noobzvpns.service -n 100 --no-pager
```

Restart:

```bash
systemctl restart noobzvpns.service
```

VIP biasanya meminta domain saat instalasi dan membutuhkan akses internet untuk beberapa dependency pihak ketiga (Xray, acme.sh/Let's Encrypt, geo-data, dan UDP-CUSTOM). Itu memang bagian dari installer VIP lama.

## Backup / credential

Konfigurasi rclone di repository sengaja hanya berupa template. Jalankan `rclone config` di VPS jika ingin mengaktifkan backup cloud. Jangan commit access token atau refresh token ke GitHub.

## Struktur

```text
DINSTORE-VPN/
├── install.sh
├── README.md
├── .gitignore
└── components/
    ├── vip/
    ├── noobzvpn/
    └── izin/
```

## Catatan

Installer VIP dapat mengubah konfigurasi jaringan, firewall, SSH, Nginx, HAProxy, dan service systemd VPS. Gunakan pada VPS yang memang disiapkan untuk VPN dan lakukan backup konfigurasi penting terlebih dahulu. Installer tidak lagi melakukan reboot otomatis setelah selesai.
