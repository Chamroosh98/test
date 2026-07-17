#!/usr/bin/env bash

set -euo pipefail

_append_files() {
    local label="$1"
    shift
    local files=("$@")
    local output="$DAYPASS_INSTALL_SCRIPT"

    echo "📦 Processing $label ..."

    for file in "${files[@]}"; do
        [ -f "$file" ] || continue
        
        local fname
        fname=$(basename "$file")

        echo -e "\n# 📄 Source : $label -> $fname" >> "$output"

        grep -v '^#!' "$file" >> "$output"
        echo -e "\n" >> "$output"
        
        echo "  ✅ [$fname] appended successfully!"
    done
}

generate_install_script() {
    mkdir -p "$DAYPASS_OUTPUT_DIR"
    local output="$DAYPASS_INSTALL_SCRIPT"

    cat > "$output" <<'EOF'
#!/bin/sh
set -eu

###############################################################################
# DayPass Installer (Auto-generated)
###############################################################################

REPO_URL="https://chamroosh98.github.io/DayPass"

EOF

    _append_files "Installer Core" \
        "$DAYPASS_INSTALLER_DIR/network_checker.sh" \
        "$DAYPASS_INSTALLER_DIR/package_manager.sh" \
        "$DAYPASS_INSTALLER_DIR/install_core.sh" \
        "$DAYPASS_INSTALLER_DIR/package_deployer.sh" \
        "$DAYPASS_INSTALLER_DIR/package_resolver.sh"

    _append_files "UI Libraries" \
        "$DAYPASS_UI_DIR/lib/styles.sh" \
        "$DAYPASS_UI_DIR/lib/box_utils.sh"

    _append_files "Modules" \
        "$DAYPASS_MODULE_DIR/zero_deps.sh" \
        "$DAYPASS_MODULE_DIR/version_check.sh" \
        "$DAYPASS_MODULE_DIR/system_info.sh" \
        "$DAYPASS_MODULE_DIR/network_info.sh" \
        "$DAYPASS_MODULE_DIR/resource_monitor.sh" \
        "$DAYPASS_MODULE_DIR/dns_fix.sh"

    _append_files "UI Components" \
        "$DAYPASS_UI_DIR/style.sh" \
        "$DAYPASS_UI_DIR/banner.sh" \
        "$DAYPASS_UI_DIR/state.sh" \
        "$DAYPASS_UI_DIR/progress.sh" \
        "$DAYPASS_UI_DIR/engine_menu.sh" \
        "$DAYPASS_UI_DIR/menu_recommended.sh" \
        "$DAYPASS_UI_DIR/menu_custom.sh" \
        "$DAYPASS_UI_DIR/menu_language.sh" \
        "$DAYPASS_UI_DIR/menu_geo.sh" \
        "$DAYPASS_UI_DIR/review.sh" \
        "$DAYPASS_UI_DIR/menu_package.sh" \
        "$DAYPASS_UI_DIR/main_menu.sh"

    cat >> "$output" <<'EOF'

###############################################################################
# Runtime Execution
###############################################################################

DEPLOYMENT_FAILED=0

network_check || exit 1
deploy_system_dependencies
check_version
detect_arch
initialize_installer

# Launching Interface
reset_state
main_menu

# Execution
deploy_targeted_packages

echo
echo "🎉 DayPass installation completed successfully! ;))"
exit 0
EOF

    chmod +x "$output"
    log_success "install.sh generated dynamically with zero garbage! 🚀"
}