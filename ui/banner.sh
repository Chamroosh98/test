#!/bin/sh

show_banner()
{
    detect_arch
    
    OW_VER="Unknown"
    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        OW_VER="${DISTRIB_RELEASE:-Unknown}"
    fi

    TOTAL_RAM_MB=$(get_total_ram_mb 2>/dev/null || echo 0)
    FREE_RAM_MB=$(get_free_ram_mb 2>/dev/null || echo 0)
    USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))

    TOTAL_STO_MB=$(get_total_storage_mb 2>/dev/null || echo 0)
    FREE_STO_MB=$(get_free_storage_mb 2>/dev/null || echo 0)
    USED_STO_MB=$((TOTAL_STO_MB - FREE_STO_MB))

    echo

    L1="    ____              ____"
    L2="   |  _ \  __ _ _   _|  _ \  __ _ ___ ___"
    L3="   | | | |/ _\` | | | | |_) / _\` / __/ __|"
    L4="   | |_| | (_| | |_| |  __/ (_| \__ \__ \\\\"
    L5="   |____/ \__,_|\__, |_|   \__,_|___/___/"
    L6="                |___/"

    printf " ${CYAN}%-43s${RESET}  ${CYAN}🩻 Architecture :${RESET} %s\n" "$L1" "$ARCH"
    printf " ${CYAN}%-43s${RESET}  ${CYAN}💡 OpenWrt      :${RESET} %s\n" "$L2" "$OW_VER"
    printf " ${CYAN}%-43s${RESET}  ${CYAN}🧠 Memory       :${RESET} %s/%s MB\n" "$L3" "$USED_RAM_MB" "$TOTAL_RAM_MB"
    printf " ${CYAN}%-43s${RESET}  ${CYAN}💾 Storage      :${RESET} %s/%s MB\n" "$L4" "$USED_STO_MB" "$TOTAL_STO_MB"


    printf " ${CYAN}%s${RESET}\n" "$L5"
    printf " ${CYAN}%-20s${RESET} ${GRAY}🐱 github.com/Chamroosh98${RESET}  ${YELLOW}%s${RESET}\n" "$L6" "${VERSION:-v2.1.0}"

    echo
    printf "${GRAY}─────────────── 🕊️  Remembering the IRAN Massacre on Jan 8-9, 2026 ───────────────${RESET}\n"
    echo
}