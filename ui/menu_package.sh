#!/bin/sh

package_menu()
{
    render_persistent_header

    echo " Package Type"
    echo " ────────────"
    echo "  1) Passwall-1"
    echo "  2) Passwall-2"
    echo

    printf "  ⁉️ Select : "
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

    render_persistent_header
    echo " Installation Mode"
    echo " ──────────────────"
    echo "  1) ⚡ Recommended (Quick & Pre-configured for standard users)"
    echo "  2) 🛠️ Custom      (Advanced package selection)"
    echo

    printf "  ⁉️ Select : "
    read -r mode_choice </dev/tty

    if [ "$mode_choice" = "1" ] || [ -z "$mode_choice" ]; then
        # RECOMMENDED 
        handle_recommended_profile
        
        # Default values
        SELECTED_ENGINE="xray"
        SELECTED_LANGUAGE="fa"
        SELECTED_GEO="official"
        export SELECTED_ENGINE SELECTED_LANGUAGE SELECTED_GEO

    else
        # CUSTOM 
        handle_custom_profile
        engine_menu
        language_menu
        geo_menu
    fi

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