#!/bin/sh

show_banner()
{
    detect_arch
    
    OW_VER="Unknown"
    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        OW_VER="${DISTRIB_RELEASE:-Unknown}"
    fi

    TOTAL_RAM_MB=$(get_total_ram_mb)
    FREE_RAM_MB=$(get_free_ram_mb)
    USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))

    TOTAL_STO_MB=$(get_total_storage_mb)
    FREE_STO_MB=$(get_free_storage_mb)
    USED_STO_MB=$((TOTAL_STO_MB - FREE_STO_MB))

    echo

    L1="    ____              ____"
    L2="   |  _ \  __ _ _   _|  _ \  __ _ ___ ___"
    L3="   | |_| | (_| | |_| |  __/ (_| \__ \__ \\"
    L4="   |____/ \__,_|\__, |_|   \__,_|___/___/"
    L5="                |___/"

    printf " ${CYAN}%-42s${RESET}  ${GRAY}🐱 github.com/Chamroosh98${RESET}\n" "$L1"
    printf " ${CYAN}%-42s${RESET}  ${CYAN}🩻 Architecture :${RESET} %s\n" "$L2" "$ARCH"
    printf " ${CYAN}%-42s${RESET}  ${CYAN}💡 OpenWrt      :${RESET} %s\n" "$L3" "$OW_VER"
    printf " ${CYAN}%-42s${RESET}  ${CYAN}🧠 Memory       :${RESET} %s/%s MB\n" "$L4" "$USED_RAM_MB" "$TOTAL_RAM_MB"
    printf " ${CYAN}%-42s${RESET}${YELLOW}%-8s${RESET} ${CYAN}💾 Storage      :${RESET} %s/%s MB\n" "$L5" "${VERSION:-v2.1.0}" "$USED_STO_MB" "$TOTAL_STO_MB"

    echo
    printf "${GRAY}─────────────── 🕊️  Remembering the IRAN Massacre on Jan 8-9, 2026 ───────────────${RESET}\n"
    echo
}