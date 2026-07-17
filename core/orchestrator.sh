#!/usr/bin/env bash

set -euo pipefail

DAYPASS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

###############################################################################
# Core
###############################################################################

source "$DAYPASS_ROOT/core/context.sh"
source "$DAYPASS_ROOT/core/cache.sh"

###############################################################################
# UI
###############################################################################

source "$DAYPASS_ROOT/ui/style.sh"
source "$DAYPASS_ROOT/ui/banner.sh"

###############################################################################
# Engines
###############################################################################

source "$DAYPASS_ROOT/core/fetcher.sh"
source "$DAYPASS_ROOT/core/template_gen.sh"

source "$DAYPASS_ROOT/metadata/manifest.sh"

source "$DAYPASS_ROOT/metadata/catalog.sh"

###############################################################################
# Main
###############################################################################

main() {
    # 👈 خواندن پارامتر ورودی از ترمینال (مثلاً ./core/orchestrator.sh arm_cortex-a7_neon-vfpv4)
    local target_arch="${1:-}" 

    show_banner
    log_info "📡 Initializing DayPass ..."

    cache_init

    rm -rf "$DAYPASS_TEMP_DIR"
    mkdir -p "$DAYPASS_TEMP_DIR"

    rm -rf "$DAYPASS_OUTPUT_DIR"
    mkdir -p "$DAYPASS_OUTPUT_DIR"

    log_info "🥇 Phase 1/3 : Fetch Packages ..."
    
    # 👈 پاس دادن معماری به واکشی‌کننده
    fetch_all_packages "$target_arch" ""

    generate_manifest
    generate_catalog
    
    echo -e "${GRAY}------------------------------------------------------------${NC}"

    log_info "🥈 Phase 2/3 : Generate Installer ..."
    generate_install_script || {
        echo "❌ template_gen.sh failed!"
        exit 1
    }

    echo -e "${GRAY}------------------------------------------------------------${NC}"

    log_info "🥉 Phase 3/3 : Build Output ..."
    for arch_dir in "$DAYPASS_TEMP_DIR"/*; do
        [[ ! -d "$arch_dir" ]] && continue
        arch_name="$(basename "$arch_dir")"

        mkdir -p "$DAYPASS_OUTPUT_DIR/$arch_name"
        cp -a "$arch_dir/." "$DAYPASS_OUTPUT_DIR/$arch_name/"
        log_success " Output generated for ${arch_name}"
    done

    echo -e "${GRAY}------------------------------------------------------------${NC}"
    log_success " DayPass Build Completed Successfully!"
}

###############################################################################
# Run
###############################################################################

main "$@"