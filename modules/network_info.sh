#!/bin/sh

country_flag()
{
    case "$1" in
        IR) echo "🦁☀️" ;;
        AZ) echo "🇦🇿" ;;
        DE) echo "🇩🇪" ;;
        US) echo "🇺🇸" ;;
        NL) echo "🇳🇱" ;;
        RU) echo "🇷🇺" ;;
        CN) echo "🇨🇳" ;;
        JP) echo "🇯🇵" ;;
        SG) echo "🇸🇬" ;;
        TR) echo "🇹🇷" ;;
        GB) echo "🇬🇧" ;;
        FR) echo "🇫🇷" ;;
        FI) echo "🇫🇮" ;;
        SE) echo "🇸🇪" ;;
        PL) echo "🇵🇱" ;;
        *)  echo "🌐" ;;
    esac
}

fetch_ip_data()
{
    NETWORK_JSON="$($FETCH_CMD https://ipwho.is/ 2>/dev/null || true)"
    if echo "$NETWORK_JSON" | grep -q '"success":true'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country // "")|\(.country_code // "")|\(.flag.emoji // "")|\(.city // "")|\(.connection.isp // "")|\(.connection.asn // "")"' 2>/dev/null || echo "false|||||||"
        return 0
    fi

    NETWORK_JSON="$($FETCH_CMD https://ipapi.co/json/ 2>/dev/null || true)"
    if echo "$NETWORK_JSON" | grep -q '"ip"'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country_name // "")|\(.country_code // "")||\(.city // "")|\(.org // "")|\(.asn // "")"' 2>/dev/null || echo "false|||||||"
        return 0
    fi

    NETWORK_JSON="$($FETCH_CMD https://ifconfig.co/json 2>/dev/null || true)"
    if echo "$NETWORK_JSON" | grep -q '"ip"'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country // "")|\(.country_iso // "")||\(.city // "")|\(.asn_org // "")|\(.asn // "")"' 2>/dev/null || echo "false|||||||"
        return 0
    fi

    echo "false|||||||"
}

get_network_info_content()
{
    if command -v curl >/dev/null 2>&1; then
        FETCH_CMD="curl -fsS --max-time 4"
    elif command -v uclient-fetch >/dev/null 2>&1; then
        FETCH_CMD="uclient-fetch -q -T 4 -O-"
    else
        log_warn "curl/uclient-fetch unavailable!"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq missing!"
        return 0
    fi

    PARSED_DATA="$(fetch_ip_data || echo "false|||||||")"

    IFS='|' read -r SUCCESS PUBLIC_IP COUNTRY COUNTRY_CODE FLAG CITY ISP ASN <<EOF
$PARSED_DATA
EOF

    if [ "${SUCCESS:-false}" != "true" ] || [ -z "$PUBLIC_IP" ]; then
        log_warn "Network location unavailable!"
        return 0
    fi

    if [ "$COUNTRY_CODE" = "IR" ]; then
        FLAG="🦁☀️"
    elif [ -z "$FLAG" ]; then
        FLAG="$(country_flag "$COUNTRY_CODE")"
    fi

    CITY_STR=""
    [ -n "$CITY" ] && CITY_STR=" ${GRAY}($CITY)${RESET}"

    box_line "${GRAY}IP      :${RESET} ${CYAN}$PUBLIC_IP${RESET}"
    box_line "${GRAY}Country :${RESET} $FLAG ${WHITE}$COUNTRY${RESET}$CITY_STR"
    [ -n "$ISP" ] && box_line "${GRAY}ISP     :${RESET} ${WHITE}$ISP${RESET}"
    [ -n "$ASN" ] && box_line "${GRAY}ASN     :${RESET} ${GRAY}AS$ASN${RESET}"
}

get_network_info()
{
    echo
    box_header "🌐 Network"
    get_network_info_content
    box_footer
}

show_live_speed() {
    IFACE=$(uci get network.wan.device 2>/dev/null || echo "wan")
    [ ! -d "/sys/class/net/$IFACE" ] && IFACE="eth0"

    echo
    MSG="Monitoring live speed on [${CYAN}$IFACE${RESET}] ${GRAY}(Press Ctrl+C to stop)...${RESET}"
    if command -v log_info >/dev/null 2>&1; then
        log_info "$MSG"
    else
        echo "$MSG"
    fi
    echo

    RX_PREV=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
    TX_PREV=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)

    trap 'echo ""; return 0' INT

    while true; do
        sleep 1
        RX_NOW=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        TX_NOW=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)

        RX_SPEED=$(( (RX_NOW - RX_PREV) / 1024 ))
        TX_SPEED=$(( (TX_NOW - TX_PREV) / 1024 ))

        if [ "$RX_SPEED" -gt 1024 ]; then
            RX_FMT="$(awk "BEGIN {printf \"%.2f MB/s\", $RX_SPEED/1024}")"
        else
            RX_FMT="${RX_SPEED} KB/s"
        fi

        if [ "$TX_SPEED" -gt 1024 ]; then
            TX_FMT="$(awk "BEGIN {printf \"%.2f MB/s\", $TX_SPEED/1024}")"
        else
            TX_FMT="${TX_SPEED} KB/s"
        fi

        printf "\r  📥 ${GRAY}Down:${RESET} %-12s ${GRAY}|${RESET} 📤 ${GRAY}Up:${RESET} %-12s" "${GREEN}$RX_FMT${RESET}" "${YELLOW}$TX_FMT${RESET}"

        RX_PREV=$RX_NOW
        TX_PREV=$TX_NOW
    done
}

case "$0" in
    *network_info.sh) get_network_info ;;
esac