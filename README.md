# DINSTORE VIP

Script instalasi VPN/VPS DINSTORE berbasis Ubuntu/Debian.

## Install

```bash
apt update -y
apt install -y git curl wget
cd /root
git clone https://github.com/DINSTORE99/dinstore.git
cd dinstore
chmod +x setup.sh
./setup.sh
```

### IP License

Sebelum instalasi dilanjutkan, `setup.sh` mengambil IP publik VPS lalu memeriksa:

- IP terdaftar di `license/licenses.txt`
- tanggal expired
- jumlah hari tersisa

Format license:

```text
IP|YYYY-MM-DD|LABEL
```

Contoh:

```text
123.123.123.123|2026-09-30|CLIENT-01
```

Setelah instalasi selesai, script langsung membuka menu DINSTORE tanpa reboot. Saat login SSH berikutnya, `/root/.profile` otomatis menjalankan `menu`.

## Update menu

```bash
wget -qO /opt/dinstore/bin/menu.sh https://raw.githubusercontent.com/DINSTORE99/dinstore/main/bin/menu.sh
chmod +x /opt/dinstore/bin/menu.sh
ln -sf /opt/dinstore/bin/menu.sh /usr/local/bin/menu
hash -r
menu
```

## Membuat tanggal license

Jalankan di komputer/admin:

```bash
./license-admin.sh 123.123.123.123 30 CLIENT-01
```

Output contoh:

```text
123.123.123.123|2026-10-01|CLIENT-01
```

Salin baris tersebut ke `license/licenses.txt` lalu commit/push ke repository.
