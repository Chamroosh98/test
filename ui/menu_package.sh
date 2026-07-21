#!/bin/sh

package_menu()
{
    render_persistent_header

    echo " Package Type"
    echo " ────────────"
    echo "  1) Passwall-1"
    echo "  2) Passwall-2"
    echo

    printf "  ⁉️ Choice : "
    read -r choice </dev/tty

    case "$choice" in
        1)
            SELECTED_PROFILE="passwall"
            add_selected_package "luci-app-passwall"
            ;;
        2)
            SELECTED_PROFILE="passwall2"
            add_selected_package "luci-app-passwall2"
            ;;
        *)
            log_error "Invalid choice!"
            return 1
            ;;
    esac

    export SELECTED_PROFILE

    menu_mode

    engine_menu

    language_menu

    geo_menu

    review_install || return 1

    if deploy_targeted_packages; then
        echo
        log_success "Installation completed :)"
    else
        echo
        log_error "Installation failed!"
        return 1
    fi

    return 0
}