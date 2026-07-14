#!/bin/sh

detect_arch()
{
    case "$(uname -m)" in
        armv7l)
            ARCH="arm_cortex-a7_neon-vfpv4"
            ;;
        aarch64)
            ARCH="aarch64_generic"
            ;;
        x86_64)
            ARCH="x86_64"
            ;;
        *)
            ARCH="$(uname -m)"
            ;;
    esac
    export ARCH
}

# --- رنگ‌ها (ANSI) ---
C_RESET="\033[0m"
C_CYAN="\033[36m"
C_DIM="\033[2m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"

box_header()
{
    # $1 = آیکون + عنوان   |   $2 = عرض کل باکس (پیش‌فرض 60)
    TITLE="$1"
    WIDTH="${2:-58}"
    TITLE_LEN=$(printf "%s" "$TITLE" | wc -m)
    # 3 تا کاراکتر برای "╭─ " و یک فاصله بعد از عنوان
    DASH_COUNT=$((WIDTH - TITLE_LEN - 4))
    [ "$DASH_COUNT" -lt 0 ] && DASH_COUNT=0

    DASHES=""
    i=0
    while [ "$i" -lt "$DASH_COUNT" ]; do
        DASHES="${DASHES}─"
        i=$((i + 1))
    done

    printf "${C_CYAN}╭─ ${C_RESET}${C_BOLD}%s${C_RESET} ${C_CYAN}%s╮${C_RESET}\n" "$TITLE" "$DASHES"
}

box_footer()
{
    WIDTH="${1:-58}"
    DASHES=""
    i=0
    while [ "$i" -lt "$WIDTH" ]; do
        DASHES="${DASHES}─"
        i=$((i + 1))
    done
    printf "${C_CYAN}╰%s╯${C_RESET}\n" "$DASHES"
}

show_system_info()
{
    echo
    box_header "🖥️  System Information"

    detect_arch
    printf "${C_CYAN}│${C_RESET} 🩻 Architecture     : %s\n" "$ARCH"

    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        printf "${C_CYAN}│${C_RESET} 💡 OpenWrt version  : %s\n" "${DISTRIB_RELEASE:-Unknown}"
    fi

    printf "${C_CYAN}│${C_RESET}\n"

    if command -v free >/dev/null 2>&1; then
        FREE_RAM_KB="$(free | awk '/Mem:/ {print $4}')"
        TOTAL_RAM_KB="$(free | awk '/Mem:/ {print $2}')"
        FREE_RAM_MB=$((FREE_RAM_KB / 1024))
        TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
        printf "${C_CYAN}│${C_RESET} 🧠 Memory (MB) : %s (Total), %s (Free)\n" "${TOTAL_RAM_MB:-0}" "${FREE_RAM_MB:-0}"
    fi

    printf "${C_CYAN}│${C_RESET}\n"

    df -m / | awk -v cyan="$C_CYAN" -v reset="$C_RESET" '
        NR==2 {
            printf "%s│%s 💾 Storage (MB) : %s (Total), %s (Used), %s (Free)\n", cyan, reset, $2, $3, $4
        }
        '

    box_footer
}

show_system_info