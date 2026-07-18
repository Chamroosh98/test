#!/bin/sh

package_menu()
{
    clear
    show_banner
    show_system_info


    echo "Package Type"
    echo

    echo "1) Passwall-1"
    echo "2) Passwall-2"

    printf "  ⁉️ Choice : "
    read -r choice </dev/tty


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
            echo "  ❌ Invalid choice!"
            return 1
        ;;

    esac

    export SELECTED_PROFILE

    language_menu

    geo_menu

    review_install || return 1

    if deploy_targeted_packages; then

        echo
        echo "  ✅ Installation completed :)"

    else

        echo
        echo "  ❌ Installation failed!"

    return 1

    fi

    return 0

}