#!/usr/bin/env bash
set -Eeuo pipefail
apt-get update
apt-get install -y openvpn easy-rsa
mkdir -p /etc/dinstore/openvpn
cat > /etc/openvpn/server.conf <<'CONF'
port 1194
proto udp
dev tun
server 10.8.0.0 255.255.255.0
keepalive 10 120
persist-key
persist-tun
user nobody
group nogroup
status /var/log/openvpn-status.log
verb 3
CONF
# PKI/certificates are intentionally not generated with placeholder secrets.
# Run: make-openvpn-pki after configuring the server identity.
cat > /usr/local/bin/make-openvpn-pki <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
PKI=/etc/dinstore/openvpn/pki
make-cadir "$PKI"
cd "$PKI"
./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch build-server-full server nopass
./easyrsa gen-dh
./easyrsa --batch gen-crl
install -m 600 pki/private/server.key /etc/openvpn/server.key
install -m 644 pki/issued/server.crt pki/ca.crt pki/dh.pem /etc/openvpn/
install -m 644 pki/crl.pem /etc/openvpn/
sed -i '/^crl-verify/d' /etc/openvpn/server.conf; echo 'crl-verify /etc/openvpn/crl.pem' >> /etc/openvpn/server.conf
systemctl enable --now openvpn-server@server || systemctl enable --now openvpn@server
SCRIPT
chmod +x /usr/local/bin/make-openvpn-pki
