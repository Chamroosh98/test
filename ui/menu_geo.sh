#!/bin/sh

geo_menu()
{

    echo

    echo "Geo Database"

    echo "1) Skip"
    echo "2) Official"
    echo "3) Iran Full"
    echo "4) Iran Lite"

    printf "Choice: "
    read -r choice </dev/tty


    GEOIP_URL=""
    GEOSITE_URL=""

    case "$choice" in

        1)
            SELECTED_GEO="none"
        ;;

        2)
            SELECTED_GEO="official"
            add_selected_package "v2ray-geoip"
            add_selected_package "v2ray-geosite"
        ;;

        3)
            SELECTED_GEO="iran-full"
            GEOIP_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geoip.dat"
            GEOSITE_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geosite.dat"
        ;;

        4)
            SELECTED_GEO="iran-lite"
            GEOIP_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geoip-lite.dat"
            GEOSITE_URL="https://raw.githubusercontent.com/Chocolate4U/Iran-v2ray-rules/release/geosite-lite.dat"
        ;;

        *)
            SELECTED_GEO="none"
        ;;

    esac

    export SELECTED_GEO
    export GEOIP_URL
    export GEOSITE_URL

}