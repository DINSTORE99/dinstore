#!/bin/bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0

required=(
  install.sh
  README.md
  components/noobzvpn/install.sh
  components/noobzvpn/noobzvpns.x86_64
  components/noobzvpn/noobzvpns.service
  components/noobzvpn/config.json
  components/vip/setup.sh
  components/vip/update.sh
  components/vip/Cdy/menu.zip
  components/vip/Enc/encrypt
  components/vip/Cfg/config.json
  components/vip/Cfg/haproxy.cfg
  components/vip/Cfg/nginx.conf
  components/vip/Cfg/xray.conf
  components/izin/ip
)

for rel in "${required[@]}"; do
  if [[ ! -e "$ROOT_DIR/$rel" ]]; then
    echo "MISSING: $rel"
    fail=1
  fi
done

while IFS= read -r -d '' script; do
  if ! bash -n "$script"; then
    echo "SYNTAX ERROR: ${script#$ROOT_DIR/}"
    fail=1
  fi
done < <(find "$ROOT_DIR" -type f -name '*.sh' -print0)

python3 - "$ROOT_DIR/components/vip/Cfg/config.json" "$ROOT_DIR/components/noobzvpn/config.json" <<'PY'
import json, sys
for path in sys.argv[1:]:
    try:
        with open(path, encoding='utf-8') as f:
            json.load(f)
        print('JSON OK:', path)
    except Exception as e:
        print('JSON ERROR:', path, e)
        raise SystemExit(1)
PY

if ! file "$ROOT_DIR/components/noobzvpn/noobzvpns.x86_64" | grep -q 'ELF 64-bit.*x86-64'; then
  echo "BINARY ERROR: noobzvpns.x86_64 bukan binary x86_64."
  fail=1
fi

if grep -RniE 'ya29\.|AIza[0-9A-Za-z_-]{20,}|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|bot[0-9]{6,}:[A-Za-z0-9_-]{20,}' "$ROOT_DIR" \
  --exclude='*.zip' --exclude='*.x86_64' --exclude='ws' --exclude='ftvpn' --exclude='dnstt-*' >/dev/null 2>&1; then
  echo "POTENTIAL SECRET FOUND: hapus credential sebelum push ke GitHub."
  fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "DINSTORE-VPN check: FAILED"
  exit 1
fi

echo "DINSTORE-VPN check: OK"
