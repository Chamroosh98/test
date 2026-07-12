#!/bin/sh

###############################################################################
# DayPass Network Checker
###############################################################################

set -u


GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"


ok()
{
    echo -e "${GREEN}[ OK ]${RESET} $1"
}


fail()
{
    echo -e "${RED}[FAIL]${RESET} $1"
}


info()
{
    echo -e "${CYAN}[INFO]${RESET} $1"
}


line()
{
    echo "----------------------------------------"
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


    if curl -fsSI --connect-timeout 5 "$url" >/dev/null 2>&1
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



suggest_dns()
{

    echo

    echo -e "${YELLOW}DNS Problem detected${RESET}"

    echo
    echo "Recommended DNS:"
    echo "  1.1.1.1"
    echo "  1.0.0.1"
    echo

    echo "You can set it using:"
    echo

    echo "uci set network.lan.dns='1.1.1.1 1.0.0.1'"
    echo "uci commit network"
    echo "service network restart"

    echo

}



network_check()
{

    echo
    echo "========================================"
    echo "        DayPass Network Check"
    echo "========================================"
    echo


    FAILED=0


    info "Checking DNS..."

    check_dns google.com || FAILED=1
    check_dns github.com || FAILED=1
    check_dns cloudflare.com || FAILED=1
    check_dns openwrt.org || FAILED=1


    echo

    info "Checking connectivity..."

    check_ping google.com || FAILED=1
    check_ping github.com || FAILED=1
    check_ping cloudflare.com || FAILED=1
    check_ping openwrt.org || FAILED=1


    echo

    info "Checking HTTPS..."

    check_https "Google" "https://google.com" || FAILED=1
    check_https "GitHub" "https://github.com" || FAILED=1
    check_https "Cloudflare" "https://cloudflare.com" || FAILED=1
    check_https "OpenWrt" "https://openwrt.org" || FAILED=1


    echo
    line


    if [ "$FAILED" -eq 0 ]
    then

        ok "Network looks good"

        return 0

    fi



    fail "Network problems detected"


    if check_ping cloudflare.com
    then
        suggest_dns
    fi


    return 1

}