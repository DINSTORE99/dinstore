#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# DINSTORE MENU
# ============================================================

BASE="/root/dinstore"
OPT="/opt/dinstore"
R="$OPT/bin"

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

pause() {
    echo
    read -r -p "Tekan Enter untuk kembali..." _
}

header() {
    clear

    printf '%b\n' "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
    printf '%b\n' "${RED}║                    DINSTORE                          ║${RESET}"
    printf '%b\n' "${BLUE}║                 VPN MANAGEMENT                       ║${RESET}"
    printf '%b\n' "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

    echo

    if [[ -x "$R/status.sh" ]]; then
        "$R/status.sh"
    fi

    echo
    printf '%b\n' "${BLUE}──────────────────────────────────────────────────────${RESET}"

    printf '%b\n' "${CYAN}[1] SSH / OPENVPN          [6] BACKUP / RESTORE${RESET}"
    printf '%b\n' "${CYAN}[2] VLESS / XRAY           [7] AUTO BACKUP${RESET}"
    printf '%b\n' "${CYAN}[3] VMESS / XRAY           [8] UPDATE${RESET}"
    printf '%b\n' "${CYAN}[4] TROJAN / XRAY          [9] SYSTEM${RESET}"
    printf '%b\n' "${CYAN}[5] API / USERS            [10] RESTART SERVICES${RESET}"

    echo
}

# ============================================================
# UPDATE DINSTORE
# ============================================================

update_dinstore() {
    clear

    echo "======================================================"
    echo "                 DINSTORE UPDATE"
    echo "======================================================"
    echo

    if [[ ! -d "$BASE/.git" ]]; then
        echo -e "${RED}Repository Git tidak ditemukan:${RESET}"
        echo "$BASE"
        pause
        return
    fi

    echo -e "${CYAN}[1/6] Mengambil update dari repository...${RESET}"

    cd "$BASE"

    if ! git pull --ff-only; then
        echo
        echo -e "${RED}Gagal melakukan git pull.${RESET}"
        pause
        return
    fi

    echo
    echo -e "${GREEN}✓ Repository berhasil diperbarui.${RESET}"

    echo
    echo -e "${CYAN}[2/6] Menyalin API...${RESET}"

    mkdir -p "$OPT/api"
    [[ -f "$BASE/api/server.py" ]] &&
        cp -f "$BASE/api/server.py" "$OPT/api/server.py"

    echo
    echo -e "${CYAN}[3/6] Memperbarui script DINSTORE...${RESET}"

    mkdir -p "$OPT/bin"

    if compgen -G "$BASE/bin/*.sh" > /dev/null; then
        cp -f "$BASE/bin/"*.sh "$OPT/bin/"
        chmod +x "$OPT/bin/"*.sh
    fi

    echo
    echo -e "${CYAN}[4/6] Memperbarui konfigurasi systemd...${RESET}"

    if [[ -d "$BASE/systemd" ]]; then
        cp -f "$BASE/systemd/"*.service \
            /etc/systemd/system/ 2>/dev/null || true

        cp -f "$BASE/systemd/"*.timer \
            /etc/systemd/system/ 2>/dev/null || true
    fi

    systemctl daemon-reload

    echo
    echo -e "${CYAN}[5/6] Memperbarui installer/config...${RESET}"

    [[ -f "$BASE/install_xray.sh" ]] &&
        cp -f "$BASE/install_xray.sh" "$OPT/install_xray.sh"

    [[ -f "$BASE/install_openvpn.sh" ]] &&
        cp -f "$BASE/install_openvpn.sh" "$OPT/install_openvpn.sh"

    chmod +x "$OPT/install_xray.sh" 2>/dev/null || true
    chmod +x "$OPT/install_openvpn.sh" 2>/dev/null || true

    # Pastikan command menu tetap tersedia
    ln -sf "$R/menu.sh" /usr/local/bin/menu

    echo
    echo -e "${CYAN}[6/6] Memperbarui package VPS...${RESET}"

    apt-get update

    apt-get install --only-upgrade \
        xray \
        nginx \
        openvpn \
        -y || true

    echo
    echo "======================================================"
    echo -e "${GREEN}             UPDATE DINSTORE SELESAI${RESET}"
    echo "======================================================"
    echo
    echo "Repository : $BASE"
    echo "Install    : $OPT"
    echo

    # Restart API jika service tersedia
    if systemctl list-unit-files | grep -q '^dinstore-api.service'; then
        systemctl restart dinstore-api.service 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ Update berhasil.${RESET}"
    echo
    echo "Kembali ke menu..."

    sleep 2
}

# ============================================================
# SSH / OPENVPN
# ============================================================

ssh_openvpn() {
    clear

    echo "======================================================"
    echo "                 SSH / OPENVPN"
    echo "======================================================"
    echo

    echo "1) Add SSH User"
    echo "2) Delete SSH User"
    echo "3) List SSH User"
    echo "4) OpenVPN"
    echo

    read -r -p "Pilih [1-4]: " x

    case "$x" in

        1)
            read -r -p "Username: " u
            read -r -p "Days [30]: " d

            d="${d:-30}"

            "$R/user.sh" add "$u" "$d"
            pause
            ;;

        2)
            read -r -p "Username: " u

            if [[ -n "$u" ]]; then
                "$R/user.sh" del "$u"
            fi

            pause
            ;;

        3)
            "$R/user.sh" list
            pause
            ;;

        4)
            echo
            echo "OpenVPN:"
            echo
            echo "Gunakan konfigurasi OpenVPN yang tersedia."
            echo

            pause
            ;;

        *)
            echo "Pilihan tidak valid."
            sleep 1
            ;;
    esac
}

# ============================================================
# XRAY
# ============================================================

xray_menu() {
    clear

    echo "======================================================"
    echo "                    XRAY"
    echo "======================================================"
    echo

    echo "1) VLESS"
    echo "2) VMESS"
    echo "3) TROJAN"
    echo

    read -r -p "Pilih [1-3]: " x

    case "$x" in
        1)
            echo
            echo "VLESS"
            echo "Tambahkan client melalui API/config Xray."
            pause
            ;;

        2)
            echo
            echo "VMESS"
            echo "Tambahkan client melalui API/config Xray."
            pause
            ;;

        3)
            echo
            echo "TROJAN"
            echo "Tambahkan client melalui API/config Xray."
            pause
            ;;

        *)
            echo "Pilihan tidak valid."
            sleep 1
            ;;
    esac
}

# ============================================================
# API / USERS
# ============================================================

api_users() {
    clear

    echo "======================================================"
    echo "                   API / USERS"
    echo "======================================================"
    echo

    echo "1) Add User"
    echo "2) Delete User"
    echo "3) List Users"
    echo

    read -r -p "Pilih [1-3]: " x

    case "$x" in

        1)
            read -r -p "Username: " u
            read -r -p "Days [30]: " d

            d="${d:-30}"

            "$R/user.sh" add "$u" "$d"
            pause
            ;;

        2)
            read -r -p "Username: " u

            [[ -n "$u" ]] && "$R/user.sh" del "$u"

            pause
            ;;

        3)
            "$R/user.sh" list
            pause
            ;;

        *)
            echo "Pilihan tidak valid."
            sleep 1
            ;;
    esac
}

# ============================================================
# BACKUP
# ============================================================

backup_menu() {
    clear

    echo "======================================================"
    echo "                 BACKUP / RESTORE"
    echo "======================================================"
    echo

    echo "1) Manual Backup"
    echo "2) Restore"
    echo

    read -r -p "Pilih [1-2]: " x

    case "$x" in

        1)
            "$R/backup.sh" manual
            pause
            ;;

        2)
            read -r -p "File backup: " f

            if [[ -n "$f" ]]; then
                "$R/restore.sh" "$f"
            fi

            pause
            ;;

        *)
            echo "Pilihan tidak valid."
            sleep 1
            ;;
    esac
}

# ============================================================
# AUTO BACKUP
# ============================================================

auto_backup() {
    clear

    echo "======================================================"
    echo "                   AUTO BACKUP"
    echo "======================================================"
    echo

    systemctl status \
        dinstore-backup.timer \
        --no-pager

    echo

    echo "Timer:"
    systemctl list-timers \
        dinstore-backup.timer \
        --no-pager

    pause
}

# ============================================================
# SYSTEM
# ============================================================

system_menu() {
    clear

    echo "======================================================"
    echo "                     SYSTEM"
    echo "======================================================"
    echo

    echo "Failed services:"
    echo

    systemctl --failed --no-pager

    echo
    pause
}

# ============================================================
# RESTART SERVICES
# ============================================================

restart_services() {
    clear

    echo "======================================================"
    echo "                RESTART SERVICES"
    echo "======================================================"
    echo

    services=(
        nginx
        xray
        dinstore-api
    )

    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            echo -n "Restart $service ... "

            if systemctl restart "$service" 2>/dev/null; then
                echo -e "${GREEN}OK${RESET}"
            else
                echo -e "${RED}FAILED${RESET}"
            fi
        fi
    done

    echo
    echo -e "${GREEN}Service selesai direstart.${RESET}"

    pause
}

# ============================================================
# MAIN MENU
# ============================================================

while true; do

    header

    printf '%b' "${GREEN}Select Options [1-10 / Enter to exit]: ${RESET}"
    read -r op

    # Enter = keluar
    [[ -z "$op" ]] && exit 0

    case "$op" in

        1)
            ssh_openvpn
            ;;

        2|3|4)
            xray_menu
            ;;

        5)
            api_users
            ;;

        6)
            backup_menu
            ;;

        7)
            auto_backup
            ;;

        8)
            update_dinstore
            ;;

        9)
            system_menu
            ;;

        10)
            restart_services
            ;;

        *)
            echo
            echo -e "${RED}Pilihan tidak valid.${RESET}"
            sleep 1
            ;;

    esac

done
