#!/bin/sh

country_flag()
{
    case "$1" in
        IR) echo "🦁☀️" ;;
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
        *)  echo "🏳️" ;;
    esac
}

fetch_ip_data()
{
    NETWORK_JSON="$($FETCH_CMD https://ipwho.is/ 2>/dev/null || true)"
    if echo "$NETWORK_JSON" | grep -q '"success":true'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.ip // "")|\(.country // "")|\(.country_code // "")|\(.flag.emoji // "")|\(.city // "")|\(.connection.isp // "")|\(.connection.asn // "")"' 2>/dev/null
        return 0
    fi

    NETWORK_JSON="$($FETCH_CMD "http://ip-api.com/json/?fields=status,country,countryCode,city,isp,as,query" 2>/dev/null || true)"
    if echo "$NETWORK_JSON" | grep -q '"status":"success"'; then
        echo "$NETWORK_JSON" | jq -r '"true|\(.query // "")|\(.country // "")|\(.countryCode // "")||\(.city // "")|\(.isp // "")|\(.as // "")"' 2>/dev/null
        return 0
    fi

    echo "false|||||||"
}

get_network_info_content()
{
    if command -v curl >/dev/null 2>&1; then
        FETCH_CMD="curl -fsS --max-time 7"
    elif command -v uclient-fetch >/dev/null 2>&1; then
        FETCH_CMD="uclient-fetch -q -T 7 -O-"
    else
        log_warn "curl/uclient-fetch unavailable!"
        return
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq missing!"
        return
    fi

    PARSED_DATA="$(fetch_ip_data)"

    IFS='|' read -r SUCCESS PUBLIC_IP COUNTRY COUNTRY_CODE FLAG CITY ISP ASN <<EOF
$PARSED_DATA
EOF

    if [ "${SUCCESS:-false}" != "true" ]; then
        log_warn "Network location unavailable!"
        return
    fi

    [ -z "$FLAG" ] && FLAG="$(country_flag "$COUNTRY_CODE")"

    box_line "IP      : $PUBLIC_IP"
    box_line "Country : $FLAG $COUNTRY  ($CITY)"
    [ -n "$ISP" ] && box_line "ISP     : $ISP"
    [ -n "$ASN" ] && box_line "ASN     : $ASN"
}

get_network_info()
{
    echo
    box_header "🌐 Network"
    get_network_info_content
    box_footer
}

case "$0" in
    *network_info.sh) get_network_info ;;
esac