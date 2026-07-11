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
    "$DAYPASS_UI_DIR/state.sh" \
    "$DAYPASS_UI_DIR/system_info.sh" \
    "$DAYPASS_UI_DIR/progress.sh" \
    "$DAYPASS_UI_DIR/engine_menu.sh" \
    "$DAYPASS_UI_DIR/menu_recommended.sh" \
    "$DAYPASS_UI_DIR/menu_custom.sh" \
    "$DAYPASS_UI_DIR/menu_language.sh" \
    "$DAYPASS_UI_DIR/menu_geo.sh" \
    "$DAYPASS_UI_DIR/menu_package.sh" \
    "$DAYPASS_UI_DIR/menu.sh" \
    "$DAYPASS_UI_DIR/review.sh"
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
    "$DAYPASS_INSTALLER_DIR/package_resolver.sh" \
    "$DAYPASS_INSTALLER_DIR/package_deployer.sh"
do
    if [ ! -f "$file" ]; then
        echo "Missing installer module: $file" >&2
        exit 1
    fi

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

command -v resolve_packages >/dev/null || {
    echo "ERROR: package resolver missing"
    exit 1
}

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