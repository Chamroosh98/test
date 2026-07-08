#!/usr/bin/env bash

set -euo pipefail

generate_install_script() {

    mkdir -p "$DAYPASS_OUTPUT_DIR"

    local output="$DAYPASS_INSTALL_SCRIPT"

    cat > "$output" <<'EOF'
#!/bin/sh

###############################################################################
# DayPass Installer
###############################################################################

set -eu

REPO_URL="https://chamroosh98.github.io/test"

EOF

###############################################################################
# UI
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
# Installer
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
# Modules
###############################################################################

    for file in \
        "$DAYPASS_MODULE_DIR/zero_deps.sh" \
        "$DAYPASS_MODULE_DIR/version_check.sh"
    do
        [ -f "$file" ] || continue

        grep -v '^#!' "$file" >> "$output"
        printf '\n\n' >> "$output"
    done

###############################################################################
# Runtime
###############################################################################

    cat >> "$output" <<'EOF'

###############################################################################
# Runtime
###############################################################################

DEPLOYMENT_FAILED=0

deploy_system_dependencies

check_version

initialize_installer

clear
show_banner

###############################################################################
# Menu
###############################################################################

while true
do

    echo
    echo "1) Recommended"
    echo "2) Custom"
    echo

    printf "Select: "

    read -r choice </dev/tty

    case "$choice" in

        1)

            handle_recommended_profile
            break
            ;;

        2)

            handle_custom_profile
            break
            ;;

    esac

done

###############################################################################
# Geo
###############################################################################

show_geo_database_menu

###############################################################################
# Install
###############################################################################

deploy_targeted_packages

###############################################################################
# Finish
###############################################################################

echo
echo "Done."

exit 0

EOF

    chmod +x "$output"

    log_success "install.sh generated."

}