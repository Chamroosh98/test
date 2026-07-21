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

get_network_info_content()
{
    if command -v curl >/dev/null 2>&1; then
        FETCH_CMD="curl -fsS --max-time 5"
    elif command -v uclient-fetch >/dev/null 2>&1; then
        FETCH_CMD="uclient-fetch -q -T 5 -O-"
    else
        log_warn "curl/uclient-fetch unavailable!"
        return
    fi

    NETWORK_JSON="$($FETCH_CMD https://ipwho.is/ 2>/dev/null)"

    if [ -z "$NETWORK_JSON" ]; then
        log_warn "Network location unavailable!"
        return
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq missing!"
        return
    fi

    eval "$(echo "$NETWORK_JSON" | jq -r '
        if .success == true then
            "SUCCESS=true\n" +
            "PUBLIC_IP=\(.ip // "")\n" +
            "COUNTRY=\(.country // "")\n" +
            "COUNTRY_CODE=\(.country_code // "")\n" +
            "FLAG=\(.flag.emoji // "")\n" +
            "CITY=\(.city // "")\n" +
            "ISP=\(.connection.isp // "")\n" +
            "ASN=\(.connection.asn // "")"
        else
            "SUCCESS=false"
        fi
    ' 2>/dev/null)"

    if [ "$SUCCESS" != "true" ]; then
        log_warn "IP lookup failed!"
        return
    fi

    [ -z "$FLAG" ] && FLAG="$(country_flag "$COUNTRY_CODE")"

    box_line "IP      : $PUBLIC_IP"
    box_line "Country : $FLAG $COUNTRY  ($CITY)"
    [ -n "$ISP" ] && box_line "ISP     : $ISP"
    [ -n "$ASN" ] && box_line "ASN     : AS$ASN"
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