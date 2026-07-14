#!/bin/sh

TOTAL_CHECKS=0
PASSED_CHECKS=0

section()
{
    echo
    printf "${BOLD}%s${RESET}\n" "$1"
    printf "${DIM}────────────────────────────────────────${RESET}\n"
}

info() { printf "${CYAN}ℹ️  %s${RESET}\n" "$1"; }

# --- توابع خام چک (فقط exit code، بدون هیچ چاپی) ---
_check_dns()   { getent hosts "$1" >/dev/null 2>&1; }
_check_ping()  { ping -c 2 -W 2 "$1" >/dev/null 2>&1; }
_check_https() { curl -fsSI --connect-timeout 5 "$1" >/dev/null 2>&1; }

# --- اجرای یک چک با اسپینر زنده، بعد جایگزینی با 🟢/🔴 ---
spin_check()
{
    KIND="$1"     # DNS / Ping / HTTPS -> ستون دوم
    LABEL="$2"    # اسم هاست/سرویس -> ستون سوم
    shift 2

    "$@" >/dev/null 2>&1 &
    PID=$!

    I=0
    while kill -0 "$PID" 2>/dev/null; do
        FRAME="$(spinner_frame "$I")"
        printf "\r\033[K  ${GRAY}%s${RESET} %-6s %s" "$FRAME" "$KIND" "$LABEL"
        I=$((I + 1))
        sleep 0.1
    done

    wait "$PID"
    STATUS=$?

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$STATUS" -eq 0 ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        printf "\r\033[K  🟢 %-6s %s\n" "$KIND" "$LABEL"
    else
        printf "\r\033[K  🔴 %-6s %s\n" "$KIND" "$LABEL"
    fi

    return "$STATUS"
}

is_openwrt() { [ -f /etc/openwrt_release ]; }

backup_network()
{
    mkdir -p /tmp/daypass
    if is_openwrt; then
        cp /etc/config/network /tmp/daypass/network.backup
        printf "  🟢 %s\n" "Network backup created!"
    fi
}

get_current_dns()
{
    echo
    info "Current DNS :"
    if is_openwrt; then
        uci get network.lan.dns 2>/dev/null || echo "   default!"
    else
        cat /etc/resolv.conf
    fi
}

apply_dns()
{
    if ! is_openwrt; then
        printf "  🔴 %s\n" "Automatic DNS fix only supports OpenWrt!"
        return 1
    fi

    info "Applying DNS..."
    uci set network.lan.peerdns='0'
    uci set network.lan.dns='1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4'
    uci commit network
    /etc/init.d/network restart
    printf "  🟢 %s\n" "DNS updated"
}

dns_fix_menu()
{
    section "🛠️  DNS Fix"
    get_current_dns
    echo
    echo "  ✅ Recommended :"
    echo "      🌐 Google      (8.8.8.8, 8.8.4.4)"
    echo "      🌥️  Cloudflare  (1.1.1.1, 1.0.0.1)"
    echo

    while true; do
        printf "  🤔 Apply DNS fix? [y/N]: "
        read -r answer </dev/tty

        case "$answer" in
            y|Y) apply_dns; break ;;
            n|N|"") info "DNS fix skipped."; break ;;
            *) echo "  😒 Invalid input! Please enter just y or n." ;;
        esac
    done
}

network_check()
{
    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    DNS_FAILED=0

    echo
    printf "${BOLD}${CYAN}🔎 DayPass Network Check${RESET}\n"

    section "DNS Resolution"
    spin_check "DNS" "google.com"     _check_dns google.com     || DNS_FAILED=1
    spin_check "DNS" "github.com"     _check_dns github.com     || DNS_FAILED=1
    spin_check "DNS" "cloudflare.com" _check_dns cloudflare.com || DNS_FAILED=1
    spin_check "DNS" "openwrt.org"    _check_dns openwrt.org    || DNS_FAILED=1

    section "Connectivity (ping)"
    spin_check "Ping" "google.com"     _check_ping google.com
    spin_check "Ping" "github.com"     _check_ping github.com
    spin_check "Ping" "cloudflare.com" _check_ping cloudflare.com
    spin_check "Ping" "openwrt.org"    _check_ping openwrt.org

    section "HTTPS Reachability"
    spin_check "HTTPS" "Google"     _check_https "https://google.com"
    spin_check "HTTPS" "GitHub"     _check_https "https://github.com"
    spin_check "HTTPS" "Cloudflare" _check_https "https://cloudflare.com"
    spin_check "HTTPS" "OpenWrt"    _check_https "https://openwrt.org"

    echo
    printf "${DIM}────────────────────────────────────────${RESET}\n"

    PCT=0
    [ "$TOTAL_CHECKS" -gt 0 ] && PCT=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

    printf "  Overall  "
    draw_bar "$PCT" 20 "score"
    printf " %s%% (%s/%s passed)\n" "$PCT" "$PASSED_CHECKS" "$TOTAL_CHECKS"

    if [ "$DNS_FAILED" -eq 0 ]; then
        printf "  🟢 ${GREEN}Network looks good${RESET}\n"
        return 0
    fi

    printf "  🔴 ${RED}DNS problems detected${RESET}\n"

    if _check_ping cloudflare.com; then
        dns_fix_menu
    fi

    return 0
}

case "$0" in
    *network_checker.sh) network_check ;;
esac