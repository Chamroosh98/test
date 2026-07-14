#!/bin/sh

detect_arch()
{
    case "$(uname -m)" in
        armv7l)   ARCH="arm_cortex-a7_neon-vfpv4" ;;
        aarch64)  ARCH="aarch64_generic" ;;
        x86_64)   ARCH="x86_64" ;;
        *)        ARCH="$(uname -m)" ;;
    esac
    export ARCH
}

show_system_info()
{
    echo
    box_header "🖥️  System Information"

    detect_arch
    box_line "🩻 Architecture     : $ARCH"

    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        box_line " 💡 OpenWrt version  : ${DISTRIB_RELEASE:-Unknown}"
    fi

    box_empty

    # --- Memory ---
    if command -v free >/dev/null 2>&1; then
        FREE_RAM_KB="$(free | awk '/Mem:/ {print $4}')"
        TOTAL_RAM_KB="$(free | awk '/Mem:/ {print $2}')"
        FREE_RAM_MB=$((FREE_RAM_KB / 1024))
        TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
        USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))
        MEM_PCT=0
        [ "$TOTAL_RAM_MB" -gt 0 ] && MEM_PCT=$((USED_RAM_MB * 100 / TOTAL_RAM_MB))

        printf "${CYAN}│${RESET} 🧠 Memory  "
        draw_bar "$MEM_PCT" 20
        printf " %s%% (%s/%s MB)\n" "$MEM_PCT" "$USED_RAM_MB" "$TOTAL_RAM_MB"
    fi

    # --- Storage ---
    STORAGE_LINE="$(df -m / | awk 'NR==2')"
    STOTAL="$(echo "$STORAGE_LINE" | awk '{print $2}')"
    SUSED="$(echo "$STORAGE_LINE" | awk '{print $3}')"
    STO_PCT=0
    [ "$STOTAL" -gt 0 ] && STO_PCT=$((SUSED * 100 / STOTAL))

    printf "${CYAN}│${RESET} 💾 Storage "
    draw_bar "$STO_PCT" 20
    printf " %s%% (%s/%s MB)\n" "$STO_PCT" "$SUSED" "$STOTAL"

    box_footer
}

# اگه مستقیم اجرا شد (نه source شد)، خودش رو نمایش بده
case "$0" in
    *system_info.sh) show_system_info ;;
esac