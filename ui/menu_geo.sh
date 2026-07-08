#!/bin/sh

show_geo_database_menu() {

    echo
    echo "Geo Database"

    echo "1) v2ray-geoip"
    echo "2) v2ray-geosite"
    echo "3) Both"
    echo "4) Skip"

    printf "Choice: "

    read -r choice

    case "$choice" in

        1)
            add_package "v2ray-geoip"
            ;;

        2)
            add_package "v2ray-geosite"
            ;;

        3)
            add_package "v2ray-geoip"
            add_package "v2ray-geosite"
            ;;

    esac

}