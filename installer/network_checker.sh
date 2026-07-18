#!/bin/sh

spin_sleep() {
    if command -v usleep >/dev/null 2>&1; then
        usleep 100000                           # 100,000 microseconds = 0.1 second
    else
        sleep 1
    fi
}

GREEN_COUNT=0
YELLOW_COUNT=0
RED_COUNT=0
TOTAL_CHECKS=0
DNS_FAILED=0

ROW_HOST=""
ROW_DNS_ICON="·"
ROW_PING_ICON="·"
ROW_HTTPS_ICON="·"
ROW_ACTIVE=""

redraw_row()
{
    spin="$1"
    d="$ROW_DNS_ICON"
    p="$ROW_PING_ICON"
    h="$ROW_HTTPS_ICON"

    case "$ROW_ACTIVE" in
        dns)   d="$spin" ;;
        ping)  p="$spin" ;;
        https) h="$spin" ;;
    esac

    printf "\r  %-18s  %-5s    %-5s    %-5s" "$ROW_HOST" "$d" "$p" "$h"
}

run_cell()
{
    ROW_ACTIVE="$1"
    tmp="$2"
    shift 2

    "$@" >"$tmp" 2>&1 &
    pid=$!

    spin_chars='-\|/'
    i=0
    while kill -0 "$pid" 2>/dev/null; 
    do
        c="$(printf '%s' "$spin_chars" | cut -c$(( (i % 4) + 1 )))"
        redraw_row "$c"
        i=$((i + 1))
        spin_sleep
    done

    wait "$pid" 2>/dev/null
    CELL_EXIT=$?
    CELL_OUTPUT="$(cat "$tmp" 2>/dev/null)"
    rm -f "$tmp"
}

process_host()
{
    ROW_HOST="$1"
    ROW_DNS_ICON="·"
    ROW_PING_ICON="·"
    ROW_HTTPS_ICON="·"
    ROW_ACTIVE=""
    redraw_row " "

    run_cell "dns" "/tmp/.nc_dns_$$" nslookup "$ROW_HOST" 127.0.0.1
    if [ "$CELL_EXIT" -eq 0 ]; then
        ROW_DNS_ICON="🟢"
    else
        ROW_DNS_ICON="🔴"
        DNS_FAILED=1
    fi

    run_cell "ping" "/tmp/.nc_ping_$$" ping -c 2 -W 2 "$ROW_HOST"
    LOSS="$(printf '%s' "$CELL_OUTPUT" | grep -o '[0-9]*% packet loss' | grep -o '^[0-9]*')"
    [ -z "$LOSS" ] && LOSS=100
    if [ "$LOSS" -eq 0 ]; then
        ROW_PING_ICON="🟢"
    elif [ "$LOSS" -lt 100 ]; then
        ROW_PING_ICON="🟡"
    else
        ROW_PING_ICON="🔴"
    fi

    run_cell "https" "/tmp/.nc_https_$$" curl -fsS -o /dev/null -w '%{time_total}' --connect-timeout 5 "https://$ROW_HOST"
    if [ "$CELL_EXIT" -ne 0 ]; then
        ROW_HTTPS_ICON="🔴"
    else
        IS_FAST="$(awk -v t="$CELL_OUTPUT" 'BEGIN { print (t < 2) ? "1" : "0" }' 2>/dev/null)"
        if [ "$IS_FAST" = "1" ]; then
            ROW_HTTPS_ICON="🟢"
        else
            ROW_HTTPS_ICON="🟡"
        fi
    fi

    ROW_ACTIVE=""
    redraw_row " "
    printf "\n"

    for icon in "$ROW_DNS_ICON" "$ROW_PING_ICON" "$ROW_HTTPS_ICON"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        case "$icon" in
            🟢) GREEN_COUNT=$((GREEN_COUNT + 1)) ;;
            🟡) YELLOW_COUNT=$((YELLOW_COUNT + 1)) ;;
            🔴) RED_COUNT=$((RED_COUNT + 1)) ;;
        esac
    done
}

is_openwrt() { [ -f /etc/openwrt_release ]; }

get_current_dns()
{
    echo
    printf "  ${CYAN}🗿${RESET} Current DNS :  "
    
    if is_openwrt; then
        DNS="$(uci get network.lan.dns 2>/dev/null)"

        if [ -n "$DNS" ]; then
            echo "$DNS"
        else
            echo "dnsmasq (127.0.0.1)"
        fi
    else
        grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' '
        echo
    fi
}

backup_dns()
{
    mkdir -p /tmp/daypass

    if is_openwrt; then
        uci export network > /tmp/daypass/network_dns_backup
    fi
}

apply_dns()
{
    backup_dns

    if ! is_openwrt; then
        printf "  ${RED}🔴${RESET} Automatic DNS fix only supports OpenWrt!\n"
        return 1
    fi

    printf "  ${CYAN}💉 Applying DNS ...${RESET}\n"
    uci set network.lan.peerdns='0'
    uci set network.lan.dns='1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4'
    uci commit network
    /etc/init.d/network restart
    printf "  ${GREEN}🟢 DNS updated successfully!${RESET}\n"
}

restore_dns()
{
    if [ -f /tmp/daypass/network_dns_backup ]; then
        uci import network < /tmp/daypass/network_dns_backup
        uci commit network
        /etc/init.d/network restart
        printf "  ${GREEN}🟢 DNS restored!${RESET}\n"
    else
        printf "  ${RED}🔴 No DNS backup found!${RESET}\n"
    fi
}

dns_fix_menu()
{
    echo
    printf "  ${BOLD}${YELLOW}🛠️  DNS Quick Fix${RESET}\n"
    printf "  ${DIM}──────────────────────────────────────────${RESET}\n"
    get_current_dns
    echo
    printf "    ${BOLD}👻 Recommended :${RESET}\n"
    printf "        ${CYAN}🌐 Google${RESET}      (8.8.8.8, 8.8.4.4)\n"
    printf "        ${CYAN}🌥️ Cloudflare${RESET}  (1.1.1.1, 1.0.0.1)\n"
    echo

    while true; do
        printf "  ⁉️ ${BOLD}Apply DNS fix? [y/N]:${RESET} "
        read -r answer </dev/tty

        case "$answer" in
            y|Y) apply_dns; break ;;
            n|N|"") printf "  🫸 ${CYAN}DNS fix skipped!${RESET}\n"; break ;;
            *) echo "  ❌ Invalid input! Please enter JUST y or n!" ;;
        esac
    done
}

network_check()
{
    GREEN_COUNT=0
    YELLOW_COUNT=0
    RED_COUNT=0
    TOTAL_CHECKS=0
    DNS_FAILED=0

    echo
    printf "  ${BOLD}${CYAN}🔎 DayPass Network Check${RESET}\n"
    echo

    printf "  %-18s  %-5s    %-5s    %-5s\n" "Host" "DNS" "Ping" "HTTPS"
    printf "  ${DIM}──────────────────────────────────────────${RESET}\n"

    process_host "google.com"
    process_host "github.com"
    process_host "openwrt.org"
    process_host "cloudflare.com"

    printf "  ${DIM}──────────────────────────────────────────${RESET}\n"

    PCT=0
    [ "$TOTAL_CHECKS" -gt 0 ] && PCT=$((GREEN_COUNT * 100 / TOTAL_CHECKS))

    printf "  Overall Status   "
    draw_bar "$PCT" 15 "score" 
    printf " %s%% (🟢 %s  🟡 %s  🔴 %s)\n" "$PCT" "$GREEN_COUNT" "$YELLOW_COUNT" "$RED_COUNT"
    echo

    if [ "$DNS_FAILED" -eq 0 ] && [ "$RED_COUNT" -eq 0 ]; then
        printf "  ${GREEN}🟢 Network looks good and healthy!${RESET}\n"
        sleep 2   # 2 seconds to wait before clearing the screen
        clear
        return 0
    fi

    if [ "$DNS_FAILED" -eq 1 ]; then
        printf "  ${RED}🔴 DNS problems detected! ${RESET}\n"
        if ping -c 1 -W 2 cloudflare.com >/dev/null 2>&1; then
            dns_fix_menu
            sleep 2   # 2 seconds to wait before clearing the screen
            clear
            return 0
        fi
    elif [ "$YELLOW_COUNT" -gt 0 ]; then
        printf "  ${YELLOW}🟡 Network is up but degraded! ${RESET}\n"
    fi
    
    return 0
}

case "$0" in
    *network_checker.sh) network_check ;;
esac