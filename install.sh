#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIN_ROOT="$ROOT_DIR"
source "$ROOT_DIR/lib/common.sh"
require_root
check_os
check_arch
install_dependencies
install_xray
install_openvpn
install_dinstore_files
install_services
configure_firewall
print_done
