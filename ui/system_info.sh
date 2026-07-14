#!/bin/sh

C_RESET="\033[0m"
C_CYAN="\033[36m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_DIM="\033[2m"

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

draw_bar()
{
    # $1=percent  $2=bar_width(default 20)  -> نتیجه رو مستقیم چاپ می‌کنه
    PCT="$1"
    BW="${2:-20}"
    FILLED=$(( PCT * BW / 100 ))
    [ "$FILLED" -gt "$BW" ] && FILLED="$BW"

    if [ "$PCT" -ge 85 ]; then COLOR="$C_RED"
    elif [ "$PCT" -ge 60 ]; then COLOR="$C_YELLOW"
    else COLOR="$C_GREEN"
    fi

    BAR=""
    i=0
    while [ "$i" -lt "$FILLED" ]; do BAR="${BAR}█"; i=$((i+1)); done
    while [ "$i" -lt "$BW" ]; do BAR="${BAR}░"; i=$((i+1)); done

    printf "${COLOR}%s${C_RESET}" "$BAR"
}

show_system_info()
{
    echo
    printf "${C_CYAN}${C_BOLD}🖥  System Information${C_RESET}\n"
    printf "${C_DIM}────────────────────────────────────────────────────────${C_RESET}\n"

    detect_arch
    printf "${C_CYAN}▏${C_RESET} 🩻 Architecture     : %s\n" "$ARCH"

    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        printf "${C_CYAN}▏${C_RESET} 💡 OpenWrt version  : %s\n" "${DISTRIB_RELEASE:-Unknown}"
    fi

    printf "${C_CYAN}▏${C_RESET}\n"

    # --- Memory ---
    if command -v free >/dev/null 2>&1; then
        FREE_RAM_KB="$(free | awk '/Mem:/ {print $4}')"
        TOTAL_RAM_KB="$(free | awk '/Mem:/ {print $2}')"
        FREE_RAM_MB=$((FREE_RAM_KB / 1024))
        TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
        USED_RAM_MB=$((TOTAL_RAM_MB - FREE_RAM_MB))
        MEM_PCT=0
        [ "$TOTAL_RAM_MB" -gt 0 ] && MEM_PCT=$((USED_RAM_MB * 100 / TOTAL_RAM_MB))

        printf "${C_CYAN}▏${C_RESET} 🧠 Memory  "
        draw_bar "$MEM_PCT" 20
        printf " %s%% (%s/%s MB)\n" "$MEM_PCT" "$USED_RAM_MB" "$TOTAL_RAM_MB"
    fi

    # --- Storage ---
    STORAGE_LINE="$(df -m / | awk 'NR==2')"
    STOTAL="$(echo "$STORAGE_LINE" | awk '{print $2}')"
    SUSED="$(echo "$STORAGE_LINE" | awk '{print $3}')"
    STO_PCT=0
    [ "$STOTAL" -gt 0 ] && STO_PCT=$((SUSED * 100 / STOTAL))

    printf "${C_CYAN}▏${C_RESET} 💾 Storage "
    draw_bar "$STO_PCT" 20
    printf " %s%% (%s/%s MB)\n" "$STO_PCT" "$SUSED" "$STOTAL"

    printf "${C_DIM}────────────────────────────────────────────────────────${C_RESET}\n"
}

show_system_info