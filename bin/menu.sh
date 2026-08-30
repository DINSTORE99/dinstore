#!/usr/bin/env bash

set -Eeuo pipefail

R="/opt/dinstore/bin"

# ==============================
# WARNA
# ==============================
RED='\033[1;31m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# ==============================
# CEK SCRIPT
# ==============================
run_script() {
    local file="$1"
    shift || true

    if [[ -x "$R/$file" ]]; then
        "$R/$file" "$@"
    elif [[ -f "$R/$file" ]]; then
        bash "$R/$file" "$@"
    else
        echo -e "${RED}Script tidak ditemukan: $R/$file${RESET}"
        read -r -p "Press Enter..."
    fi
}

# ==============================
# PAUSE
# ==============================
pause() {
    echo
    echo -e "${WHITE}Press Enter to return to menu${RESET}"
    read -r
}

# ==============================
# HEADER
# ==============================
header() {
    clear

    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
    printf "${BLUE}║${RESET}                  ${RED}DINSTORE VPN${RESET}                  ${BLUE}║${RESET}\n"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"
    echo
}

# ==============================
# MENU UTAMA
# ==============================
main_menu() {

    while true; do

        header

        # Status
        if [[ -x "$R/status.sh" ]]; then
            "$R/status.sh"
        elif [[ -f "$R/status.sh" ]]; then
            bash "$R/status.sh"
        fi

        echo
        echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BLUE}║${RESET}                  ${RED}MAIN MENU${RESET}                       ${BLUE}║${RESET}"
        echo -e "${BLUE}╠══════════════════════════════════════════════════════╣${RESET}"

        printf "${BLUE}║${RESET} ${RED}[1]${RESET} ${CYAN}SSH / OPENVPN${RESET}        ${BLUE}│${RESET} ${RED}[6]${RESET} ${CYAN}BACKUP / RESTORE${RESET}     ${BLUE}║${RESET}\n"
        printf "${BLUE}║${RESET} ${RED}[2]${RESET} ${CYAN}VLESS / XRAY${RESET}         ${BLUE}│${RESET} ${RED}[7]${RESET} ${CYAN}AUTO BACKUP${RESET}          ${BLUE}║${RESET}\n"
        printf "${BLUE}║${RESET} ${RED}[3]${RESET} ${CYAN}VMESS / XRAY${RESET}         ${BLUE}│${RESET} ${RED}[8]${RESET} ${CYAN}UPDATE${RESET}               ${BLUE}║${RESET}\n"
        printf "${BLUE}║${RESET} ${RED}[4]${RESET} ${CYAN}TROJAN / XRAY${RESET}        ${BLUE}│${RESET} ${RED}[9]${RESET} ${CYAN}SYSTEM${RESET}               ${BLUE}║${RESET}\n"
        printf "${BLUE}║${RESET} ${RED}[5]${RESET} ${CYAN}API / USERS${RESET}          ${BLUE}│${RESET} ${RED}[10]${RESET} ${CYAN}RESTART SERVICES${RESET}   ${BLUE}║${RESET}\n"

        echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

        echo
        printf "${GREEN}Select option [1-10 / Enter to exit]: ${RESET}"
        read -r op

        [[ -z "$op" ]] && exit 0

        case "$op" in

            # ==========================
            # SSH / OPENVPN
            # ==========================
            1)
                while true; do
                    header

                    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                    echo -e "${BLUE}║${RESET}                 ${RED}MENU SSH / OPENVPN${RESET}              ${BLUE}║${RESET}"
                    echo -e "${BLUE}╠══════════════════════════════════════════════════════╣${RESET}"

                    printf "${BLUE}║${RESET} ${RED}[1]${RESET} ${CYAN}ADD SSH${RESET}              ${BLUE}│${RESET} ${RED}[6]${RESET} ${CYAN}MEMBER SSH${RESET}          ${BLUE}║${RESET}\n"
                    printf "${BLUE}║${RESET} ${RED}[2]${RESET} ${CYAN}TRIAL SSH${RESET}            ${BLUE}│${RESET} ${RED}[7]${RESET} ${CYAN}CHANGE LIMIT${RESET}        ${BLUE}║${RESET}\n"
                    printf "${BLUE}║${RESET} ${RED}[3]${RESET} ${CYAN}DELETE USER${RESET}          ${BLUE}│${RESET} ${RED}[8]${RESET} ${CYAN}CONFIG SSH${RESET}          ${BLUE}║${RESET}\n"
                    printf "${BLUE}║${RESET} ${RED}[4]${RESET} ${CYAN}CHECK LOGIN${RESET}          ${BLUE}│${RESET} ${RED}[9]${RESET} ${CYAN}LOCK SSH${RESET}            ${BLUE}║${RESET}\n"
                    printf "${BLUE}║${RESET} ${RED}[5]${RESET} ${CYAN}RENEW USER${RESET}           ${BLUE}│${RESET} ${RED}[10]${RESET} ${CYAN}NOTIF MULEG${RESET}        ${BLUE}║${RESET}\n"

                    echo -e "${BLUE}║${RESET}"
                    printf "${BLUE}║${RESET} ${RED}[0]${RESET} ${CYAN}RESPON SSH${RESET}                                        ${BLUE}║${RESET}\n"

                    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                    echo
                    printf "${GREEN}Select option: ${RESET}"
                    read -r sshop

                    case "$sshop" in

                        1)
                            read -r -p "Username: " u
                            read -r -p "Days [30]: " d
                            run_script user.sh add "$u" "${d:-30}"
                            pause
                            ;;

                        2)
                            read -r -p "Username trial: " u
                            run_script user.sh add "$u" "1"
                            pause
                            ;;

                        3)
                            read -r -p "Username: " u
                            run_script user.sh del "$u"
                            pause
                            ;;

                        4)
                            run_script user.sh list
                            pause
                            ;;

                        5)
                            read -r -p "Username: " u
                            read -r -p "Tambah hari: " d
                            echo "Renew user: $u +${d:-30} hari"
                            pause
                            ;;

                        6)
                            run_script user.sh list
                            pause
                            ;;

                        7)
                            echo "Pengaturan limit SSH."
                            pause
                            ;;

                        8)
                            echo "Konfigurasi SSH."
                            pause
                            ;;

                        9)
                            echo "Lock SSH."
                            pause
                            ;;

                        10)
                            echo "Notifikasi."
                            pause
                            ;;

                        0)
                            break
                            ;;

                        *)
                            echo -e "${RED}Pilihan tidak valid.${RESET}"
                            sleep 1
                            ;;
                    esac
                done
                ;;

            # ==========================
            # VLESS
            # ==========================
            2)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                    ${RED}VLESS / XRAY${RESET}                  ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo
                echo -e "${CYAN}Xray core:${RESET}"

                if systemctl is-active --quiet xray; then
                    echo -e "${GREEN}● Running${RESET}"
                else
                    echo -e "${RED}● Stopped${RESET}"
                fi

                echo
                echo "Gunakan konfigurasi Xray / API untuk menambah client."
                pause
                ;;

            # ==========================
            # VMESS
            # ==========================
            3)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                    ${RED}VMESS / XRAY${RESET}                  ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo
                echo "Xray core aktif."
                echo "Client dapat dikelola melalui konfigurasi/API."
                pause
                ;;

            # ==========================
            # TROJAN
            # ==========================
            4)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                   ${RED}TROJAN / XRAY${RESET}                 ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo
                echo "Xray core aktif."
                echo "Client Trojan dapat dikelola melalui konfigurasi/API."
                pause
                ;;

            # ==========================
            # API / USERS
            # ==========================
            5)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                     ${RED}API / USERS${RESET}                  ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo
                echo -e "${CYAN}[1]${RESET} Add SSH User"
                echo -e "${CYAN}[2]${RESET} Delete SSH User"
                echo -e "${CYAN}[3]${RESET} List Users"

                echo
                printf "${GREEN}Select option: ${RESET}"
                read -r x

                case "$x" in

                    1)
                        read -r -p "Username: " u
                        read -r -p "Days [30]: " d
                        run_script user.sh add "$u" "${d:-30}"
                        ;;

                    2)
                        read -r -p "Username: " u
                        run_script user.sh del "$u"
                        ;;

                    3)
                        run_script user.sh list
                        ;;

                esac

                pause
                ;;

            # ==========================
            # BACKUP / RESTORE
            # ==========================
            6)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                 ${RED}BACKUP / RESTORE${RESET}                  ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo
                echo -e "${CYAN}[1]${RESET} Backup"
                echo -e "${CYAN}[2]${RESET} Restore"

                echo
                printf "${GREEN}Select option: ${RESET}"
                read -r x

                case "$x" in

                    1)
                        run_script backup.sh manual
                        ;;

                    2)
                        read -r -p "File backup: " f

                        if [[ -n "$f" ]]; then
                            run_script restore.sh "$f"
                        fi
                        ;;

                esac

                pause
                ;;

            # ==========================
            # AUTO BACKUP
            # ==========================
            7)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                    ${RED}AUTO BACKUP${RESET}                    ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo

                systemctl status dinstore-backup.timer --no-pager || true

                echo
                echo -e "${CYAN}Backup directory:${RESET}"
                echo "/var/backups/dinstore"

                pause
                ;;

            # ==========================
            # UPDATE
            # ==========================
            8)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                      ${RED}UPDATE${RESET}                        ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo

                if [[ -d /root/dinstore/.git ]]; then
                    cd /root/dinstore

                    echo -e "${CYAN}Checking update...${RESET}"
                    git pull || true

                    if [[ -f bin/menu.sh ]]; then
                        cp -f bin/menu.sh /opt/dinstore/bin/menu.sh
                        chmod +x /opt/dinstore/bin/menu.sh
                    fi

                    echo
                    echo -e "${GREEN}Update selesai.${RESET}"
                else
                    echo -e "${YELLOW}Git repository tidak ditemukan.${RESET}"
                fi

                pause
                ;;

            # ==========================
            # SYSTEM
            # ==========================
            9)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                      ${RED}SYSTEM${RESET}                        ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo

                echo -e "${CYAN}Failed services:${RESET}"
                systemctl --failed --no-pager || true

                echo
                echo -e "${CYAN}Disk:${RESET}"
                df -h /

                echo
                echo -e "${CYAN}Memory:${RESET}"
                free -h

                pause
                ;;

            # ==========================
            # RESTART
            # ==========================
            10)
                header

                echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BLUE}║${RESET}                ${RED}RESTART SERVICES${RESET}                  ${BLUE}║${RESET}"
                echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"

                echo
                echo "Restarting..."

                systemctl restart nginx || true
                systemctl restart xray || true
                systemctl restart dinstore-api || true

                echo
                echo -e "${GREEN}Services berhasil direstart.${RESET}"

                pause
                ;;

            *)
                echo -e "${RED}Pilihan tidak valid.${RESET}"
                sleep 1
                ;;

        esac

    done
}

main_menu
