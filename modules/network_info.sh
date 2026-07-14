#!/bin/sh

country_flag()
{
    case "$1" in
        IR) echo "🇮🇷" ;;
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

get_network_info()
{

    if ! command -v curl >/dev/null 2>&1; then
        log_warn "curl unavailable"
        return
    fi


    NETWORK_JSON="$(curl -fsS \
        --max-time 5 \
        https://ipwho.is/ 2>/dev/null || true)"


    if [ -z "$NETWORK_JSON" ]; then
        log_warn "Network location unavailable"
        return
    fi


    if command -v jq >/dev/null 2>&1; then

        SUCCESS="$(echo "$NETWORK_JSON" | jq -r '.success')"

        [ "$SUCCESS" != "true" ] && {
            log_warn "IP lookup failed"
            return
        }


        PUBLIC_IP="$(echo "$NETWORK_JSON" | jq -r '.ip')"

        COUNTRY="$(echo "$NETWORK_JSON" | jq -r '.country')"

        FLAG="$(echo "$NETWORK_JSON" | jq -r '.flag.emoji')"

        CITY="$(echo "$NETWORK_JSON" | jq -r '.city')"

        ISP="$(echo "$NETWORK_JSON" | jq -r '.connection.isp')"

        ASN="$(echo "$NETWORK_JSON" | jq -r '.connection.asn')"


        echo
        echo "🌐 Network"
        echo "-------------------------------"

        echo "IP      : $PUBLIC_IP"
        echo "Country : $FLAG $COUNTRY"

        [ -n "$CITY" ] &&
        echo "City    : $CITY"

        [ -n "$ISP" ] &&
        echo "ISP     : $ISP"

        [ -n "$ASN" ] &&
        echo "ASN     : AS$ASN"

        echo

    else

        log_warn "jq missing"

    fi

}