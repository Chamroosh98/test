#!/bin/sh

detect_arch()
{
    if [ -f /etc/openwrt_release ]; then
        ARCH=$(grep "DISTRIB_ARCH" /etc/openwrt_release | cut -d"'" -f2)
    else
        case "$(uname -m)" in
            armv7l)  ARCH="arm_cortex-a7_neon-vfpv4" ;;
            aarch64) ARCH="aarch64_generic" ;;
            x86_64)  ARCH="x86_64" ;;
            *)       ARCH="$(uname -m)" ;;
        esac
    fi
    export ARCH
}

show_system_info_content()
{
    detect_arch
    box_line "🩻 Architecture     : $ARCH"

    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        box_line "💡 OpenWrt version  : ${DISTRIB_RELEASE:-Unknown}"
    fi

    TOTAL_RAM_MB=$(get_total_ram_mb)
    FREE_RAM_MB=$(get_free_ram_mb)
    USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))
    
    MEM_PCT=0
    [ "$TOTAL_RAM_MB" -gt 0 ] && MEM_PCT=$((USED_RAM_MB * 100 / TOTAL_RAM_MB))

    printf "   ${CYAN}│${RESET} 🧠 Memory  "
    draw_bar "$MEM_PCT" 20
    printf " %s%% (%s/%s MB)\n" "$MEM_PCT" "$USED_RAM_MB" "$TOTAL_RAM_MB"

    TOTAL_STO_MB=$(get_total_storage_mb)
    FREE_STO_MB=$(get_free_storage_mb)
    USED_STO_MB=$((TOTAL_STO_MB - FREE_STO_MB))
    
    STO_PCT=0
    [ "$TOTAL_STO_MB" -gt 0 ] && STO_PCT=$((USED_STO_MB * 100 / TOTAL_STO_MB))

    printf "   ${CYAN}│${RESET} 💾 Storage "
    draw_bar "$STO_PCT" 20
    printf " %s%% (%s/%s MB)\n" "$STO_PCT" "$USED_STO_MB" "$TOTAL_STO_MB"
}

show_system_info()
{
    echo
    box_header " 🖥️ System Information"
    show_system_info_content
    box_footer
}

case "$0" in
    *system_info.sh) show_system_info ;;
esac