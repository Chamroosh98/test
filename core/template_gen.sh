#!/usr/bin/env bash
# DayPass Installer Builder

set -euo pipefail

source "$DAYPASS_CORE_DIR/context.sh"

generate_install_script() {

    mkdir -p "$DAYPASS_OUTPUT_DIR"

    local output="$DAYPASS_INSTALL_SCRIPT"

    cat > "$output" <<'EOF'
#!/bin/sh

###############################################################################
# DayPass Installer
###############################################################################

REPO_URL="https://chamroosh98.github.io/DayPass"

EOF

###############################################################################
# Embed UI
###############################################################################

    for file in \
        "$DAYPASS_UI_DIR/colors.sh" \
        "$DAYPASS_UI_DIR/banner.sh" \
        "$DAYPASS_UI_DIR/menu_recommended.sh" \
        "$DAYPASS_UI_DIR/menu_custom.sh" \
        "$DAYPASS_UI_DIR/menu_geo.sh"
    do

        [ -f "$file" ] || continue

        grep -v '^#!' "$file" >> "$output"

        printf '\n\n' >> "$output"

    done

###############################################################################
# Embed Installer
###############################################################################

    for file in \
        "$DAYPASS_INSTALLER_DIR/package_manager.sh" \
        "$DAYPASS_INSTALLER_DIR/install_core.sh" \
        "$DAYPASS_INSTALLER_DIR/package_deployer.sh"
    do

        [ -f "$file" ] || continue

        grep -v '^#!' "$file" >> "$output"

        printf '\n\n' >> "$output"

    done

###############################################################################
# Embed Modules
###############################################################################

    for file in "$DAYPASS_MODULE_DIR"/*.sh
    do

        [ -f "$file" ] || continue

        grep -v '^#!' "$file" >> "$output"

        printf '\n\n' >> "$output"

    done

        cat >> "$output" <<'EOF'

###############################################################################
# Runtime
###############################################################################

DEPLOYMENT_FAILED=0

initialize_installer

clear
show_banner

###############################################################################
# Package Selection
###############################################################################

while true
do

    clear

    show_banner

    echo
    echo "  1) Recommended Installation"
    echo "  2) Custom Installation"
    echo

    printf "Select option: "

    read -r profile_choice

    case "$profile_choice" in

        1)

            handle_recommended_profile

            break

            ;;

        2)

            handle_custom_profile

            break

            ;;

        *)

            ;;

    esac

done

###############################################################################
# Geo Database
###############################################################################

show_geo_database_menu

###############################################################################
# Deploy Packages
###############################################################################

deploy_targeted_packages

###############################################################################
# Finish
###############################################################################

clear

show_banner

if [ "$DEPLOYMENT_FAILED" -eq 0 ]
then

    echo
    echo "========================================"
    echo " Installation completed successfully."
    echo "========================================"

else

    echo
    echo "========================================"
    echo " Installation finished with errors."
    echo "========================================"

fi

###############################################################################
# Cleanup
###############################################################################

rm -rf "$TMP_DIR"

EOF
    chmod +x "$output"

    log_success "DayPass installer generated successfully."

}

###############################################################################
# Standalone Execution
###############################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_install_script
fi