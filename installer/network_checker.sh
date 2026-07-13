#!/bin/sh

set -u

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"


ok()
{
    printf "${GREEN}✅ [ OK ]${RESET} %s\n" "$1"
}


fail()
{
    printf "${RED}❌ [FAIL]${RESET} %s\n" "$1"
}


info()
{
    printf "${CYAN}ℹ️ [INFO]${RESET} %s\n" "$1"
}


line()
{
    echo "----------------------------------------"
}


is_openwrt()
{
    [ -f /etc/openwrt_release ]
}


backup_network()
{
    mkdir -p /tmp/daypass

    if is_openwrt
    then
        cp /etc/config/network \
        /tmp/daypass/network.backup

        ok "Network backup created!"
    fi
}


get_current_dns()
{
    echo
    info "Current DNS"

    if is_openwrt
    then
        uci get network.lan.dns 2>/dev/null || echo "default"
    else
        cat /etc/resolv.conf
    fi
}


apply_dns()
{

    if ! is_openwrt
    then
        fail "Automatic DNS fix only supports OpenWrt!"
        return 1
    fi


    info "Applying DNS"

    uci set network.lan.peerdns='0'

    uci set network.lan.dns='1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4'

    uci commit network


    /etc/init.d/network restart


    ok "DNS updated"

}



dns_fix_menu()
{

    echo
    echo "DNS Fix ..."
    echo "-------"

    get_current_dns

    echo

    echo "✅ Recommended :"
    echo " 🌥️ Cloudflare :"
    echo "   1.1.1.1"
    echo "   1.0.0.1"

    echo

    echo " 🌐 Google :"
    echo "   8.8.8.8"
    echo "   8.8.4.4"

    echo

    while true
        do

            printf "🤔 Apply DNS fix? [y/N]: "
            read -r answer </dev/tty

            case "$answer" in

                y|Y)
                    apply_dns_fix
                    break
                    ;;

                n|N|"")
                    log_info "🙂‍↔️ DNS fix skipped!"
                    break
                    ;;

                *)
                    echo "😒 Invalid input! Please enter JUST y or n!"
                    ;;

            esac

        done

}



check_ping()
{
    host="$1"


    if ping -c 2 -W 2 "$host" >/dev/null 2>&1
    then
        ok "Ping $host"
        return 0
    else
        fail "Ping $host"
        return 1
    fi
}



check_https()
{
    name="$1"
    url="$2"


    if curl -fsSI \
        --connect-timeout 5 \
        "$url" >/dev/null 2>&1
    then
        ok "HTTPS $name"
        return 0
    else
        fail "HTTPS $name"
        return 1
    fi
}



check_dns()
{
    host="$1"


    if getent hosts "$host" >/dev/null 2>&1
    then
        ok "DNS $host"
        return 0
    else
        fail "DNS $host"
        return 1
    fi
}



network_check()
{

    echo
    echo "========================================"
    echo "        DayPass Network Check"
    echo "========================================"
    echo


    DNS_FAILED=0


    info "Checking DNS..."

    check_dns google.com || DNS_FAILED=1
    check_dns github.com || DNS_FAILED=1
    check_dns cloudflare.com || DNS_FAILED=1
    check_dns openwrt.org || DNS_FAILED=1


    echo

    info "Checking connectivity..."

    check_ping google.com
    check_ping github.com
    check_ping cloudflare.com
    check_ping openwrt.org


    echo

    info "Checking HTTPS..."

    check_https "Google" "https://google.com"
    check_https "GitHub" "https://github.com"
    check_https "Cloudflare" "https://cloudflare.com"
    check_https "OpenWrt" "https://openwrt.org"


    echo
    line


    if [ "$DNS_FAILED" -eq 0 ]
    then

        ok "Network looks good"

        return 0

    fi


    fail "DNS problems detected"


    if check_ping cloudflare.com
    then
        dns_fix_menu
    fi


    echo

    info "Continuing DayPass..."

    return 0

}