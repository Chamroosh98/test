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

    SUCCESS="$(echo "$NETWORK_JSON" | jq -r '.success')"
    if [ "$SUCCESS" != "true" ]; then
        log_warn "IP lookup failed!"
        return
    fi

    PUBLIC_IP="$(echo "$NETWORK_JSON" | jq -r '.ip')"
    COUNTRY="$(echo "$NETWORK_JSON" | jq -r '.country')"
    COUNTRY_CODE="$(echo "$NETWORK_JSON" | jq -r '.country_code')"
    FLAG="$(echo "$NETWORK_JSON" | jq -r '.flag.emoji // empty')"
    CITY="$(echo "$NETWORK_JSON" | jq -r '.city')"
    ISP="$(echo "$NETWORK_JSON" | jq -r '.connection.isp')"
    ASN="$(echo "$NETWORK_JSON" | jq -r '.connection.asn')"

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