#!/bin/sh

TOTAL_CHECKS=0
PASSED_CHECKS=0

DNS_BACKUP="/tmp/daypass/dns.backup"


section()
{
    echo
    printf "${BOLD}%s${RESET}\n" "$1"
    printf "${DIM}────────────────────────────────────────${RESET}\n"
}

info() { printf "${CYAN}  ℹ️ %s${RESET}\n" "$1"; }


_check_dns()   { getent hosts "$1" >/dev/null 2>&1; }
_check_ping()  { ping -c 2 -W 2 "$1" >/dev/null 2>&1; }
_check_https() { curl -fsSI --connect-timeout 5 "$1" >/dev/null 2>&1; }


spin_check()
{
    KIND="$1"
    LABEL="$2"
    shift 2

    "$@" >/dev/null 2>&1 &
    PID=$!

    I=0

    while kill -0 "$PID" 2>/dev/null; do

        FRAME="$(spinner_frame "$I")"

        printf "\r\033[K  ${GRAY}%s${RESET} %-6s %s" \
        "$FRAME" "$KIND" "$LABEL"

        I=$((I + 1))

        if command -v usleep >/dev/null 2>&1; then
            usleep 100000
        else
            sleep 1
        fi

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


is_openwrt()
{
    [ -f /etc/openwrt_release ]
}


backup_dns()
{
    mkdir -p /tmp/daypass

    if is_openwrt; then

        uci show network.lan.dns > "$DNS_BACKUP" 2>/dev/null

        info "DNS backup created"

    fi
}



restore_dns()
{

    if ! is_openwrt; then
        return 1
    fi


    if [ ! -f "$DNS_BACKUP" ]; then

        printf "  🔴 No DNS backup found!\n"

        return 1

    fi


    info "Restoring DNS ..."


    uci delete network.lan.dns 2>/dev/null
    uci delete network.lan.peerdns 2>/dev/null


    . "$DNS_BACKUP" 2>/dev/null


    uci commit network

    /etc/init.d/network restart


    printf "  🟢 DNS restored\n"

}



get_current_dns()
{

    info "Current DNS :"


    if is_openwrt; then

        DNS="$(uci get network.lan.dns 2>/dev/null)"

        if [ -n "$DNS" ]; then

            echo "     $DNS"

        else

            echo "     System default"

        fi

    else

        grep nameserver /etc/resolv.conf

    fi

}



apply_dns()
{

    if ! is_openwrt; then

        printf "  🔴 Automatic DNS fix only supports OpenWrt!\n"

        return 1

    fi


    backup_dns


    info "Applying DNS ..."


    uci set network.lan.peerdns='0'

    uci set network.lan.dns='1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4'


    uci commit network


    /etc/init.d/network restart


    printf "  🟢 DNS updated\n"

}



dns_fix_menu()
{

    section "  🛠️ DNS Fix"


    get_current_dns


    echo

    echo "  ✅ Recommended :"

    echo "      🌐 Google      (8.8.8.8, 8.8.4.4)"

    echo "      🌥️ Cloudflare  (1.1.1.1, 1.0.0.1)"

    echo


    while true
    do

        printf "  ⁉️ Action [y=Apply / r=Restore / n=Skip] : "

        read -r answer </dev/tty


        case "$answer" in


            y|Y)

                apply_dns
                break

            ;;


            r|R)

                restore_dns
                break

            ;;


            n|N|"")

                echo

                info "DNS fix skipped!"

                break

            ;;


            *)

                echo "  ❌ Invalid input! Use y, r or n!"

            ;;


        esac

    done

}



network_check()
{

    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    DNS_FAILED=0


    echo

    printf "${BOLD}${CYAN}🔎 DayPass Network Check ${RESET}\n"



    section "DNS Resolution"


    spin_check "DNS" "google.com"     _check_dns google.com || DNS_FAILED=1

    spin_check "DNS" "github.com"     _check_dns github.com || DNS_FAILED=1

    spin_check "DNS" "cloudflare.com" _check_dns cloudflare.com || DNS_FAILED=1

    spin_check "DNS" "openwrt.org"    _check_dns openwrt.org || DNS_FAILED=1



    section "Connectivity (ping)"


    spin_check "Ping" "google.com" _check_ping google.com

    spin_check "Ping" "github.com" _check_ping github.com

    spin_check "Ping" "cloudflare.com" _check_ping cloudflare.com

    spin_check "Ping" "openwrt.org" _check_ping openwrt.org



    section "HTTPS Reachability"


    spin_check "HTTPS" "Google" _check_https "https://google.com"

    spin_check "HTTPS" "GitHub" _check_https "https://github.com"

    spin_check "HTTPS" "Cloudflare" _check_https "https://cloudflare.com"

    spin_check "HTTPS" "OpenWrt" _check_https "https://openwrt.org"



    echo

    printf "${DIM}────────────────────────────────────────${RESET}\n"



    PCT=0

    [ "$TOTAL_CHECKS" -gt 0 ] && \
    PCT=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))


    printf "  Overall  "

    draw_bar "$PCT" 20 "score"

    printf " %s%% (%s/%s passed)\n" \
    "$PCT" "$PASSED_CHECKS" "$TOTAL_CHECKS"



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

    *network_checker.sh)

        network_check

        ;;

esac