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
# Installer
###############################################################################

for file in \
    "$DAYPASS_INSTALLER_DIR/network_checker.sh" \
    "$DAYPASS_INSTALLER_DIR/package_manager.sh" \
    "$DAYPASS_INSTALLER_DIR/install_core.sh" \
    "$DAYPASS_INSTALLER_DIR/package_deployer.sh" \
    "$DAYPASS_INSTALLER_DIR/package_resolver.sh" 
do

    # echo "$file"
    # ls -l "$file" || true
    [ -f "$file" ] || continue

    grep -v '^#!' "$file" >> "$output"
    printf '\n\n' >> "$output"
done
# echo "========================="

###############################################################################
# UI
###############################################################################

for file in \
    "$DAYPASS_UI_DIR/style.sh" \
    "$DAYPASS_UI_DIR/banner.sh" \
    "$DAYPASS_UI_DIR/state.sh" \
    "$DAYPASS_UI_DIR/system_info.sh" \
    "$DAYPASS_UI_DIR/progress.sh" \
    "$DAYPASS_UI_DIR/engine_menu.sh" \
    "$DAYPASS_UI_DIR/menu_recommended.sh" \
    "$DAYPASS_UI_DIR/menu_custom.sh" \
    "$DAYPASS_UI_DIR/menu_language.sh" \
    "$DAYPASS_UI_DIR/menu_geo.sh" \
    "$DAYPASS_UI_DIR/review.sh" \
    "$DAYPASS_UI_DIR/menu_package.sh" \
    "$DAYPASS_UI_DIR/main_menu.sh"
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

    echo "=== RESOLVER CONTENT CHECK ==="
    grep -A80 "^resolve_packages()" "$output" || true
    echo "=============================="

###############################################################################
# Runtime
###############################################################################

    cat >> "$output" <<'EOF'

###############################################################################
# Runtime
###############################################################################

DEPLOYMENT_FAILED=0

network_check || exit 1

deploy_system_dependencies

check_version

detect_arch

initialize_installer

###############################################################################
# UI Start
###############################################################################

reset_state

main_menu


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