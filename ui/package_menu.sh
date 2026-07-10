#!/bin/sh


package_menu()
{
    clear

    show_banner


    echo "Package Type"
    echo

    echo "1) Passwall"
    echo "2) Passwall2"

    printf "Choice: "
    read choice


    case "$choice" in

    1)

        SELECTED_PROFILE="passwall"

        add_selected_package "luci-app-passwall"
        engine_menu

    ;;

    2)

        SELECTED_PROFILE="passwall2"

        add_selected_package "luci-app-passwall2"
        engine_menu

    ;;

    *)

        echo "Invalid choice"
        return 1

    ;;

    esac


    export SELECTED_PROFILE


    language_menu

    geo_menu


    review_install

}