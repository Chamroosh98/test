#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Core
###############################################################################

source "$ROOT_DIR/core/context.sh"
source "$ROOT_DIR/core/cache.sh"

###############################################################################
# UI
###############################################################################

source "$ROOT_DIR/ui/colors.sh"
source "$ROOT_DIR/ui/banner.sh"

###############################################################################
# Engines
###############################################################################

source "$ROOT_DIR/core/fetcher.sh"
source "$ROOT_DIR/core/template_gen.sh"

source "$ROOT_DIR/metadata/manifest.sh"

source "$ROOT_DIR/metadata/catalog.sh"

###############################################################################
# Main
###############################################################################

main() {

    show_banner

    log_info "Initializing DayPass..."

    ###########################################################################
    # Runtime
    ###########################################################################

    cache_init

    rm -rf "$DAYPASS_TEMP_DIR"
    mkdir -p "$DAYPASS_TEMP_DIR"

    rm -rf "$DAYPASS_OUTPUT_DIR"
    mkdir -p "$DAYPASS_OUTPUT_DIR"

    ###########################################################################
    # Phase 1
    ###########################################################################

    log_info "Phase 1/3 : Fetch Packages"

    fetch_all_packages ""

    generate_manifest

    generate_catalog
    
    echo -e "${GRAY}------------------------------------------------------------${NC}"

    ###########################################################################
    # Phase 2
    ###########################################################################

    log_info "Phase 2/3 : Generate Installer"

    generate_install_script

    echo -e "${GRAY}------------------------------------------------------------${NC}"

    ###########################################################################
    # Phase 3
    ###########################################################################

    log_info "Phase 3/3 : Build Output"

    for arch_dir in "$DAYPASS_TEMP_DIR"/*; do

        [[ ! -d "$arch_dir" ]] && continue

        arch_name="$(basename "$arch_dir")"

        mkdir -p "$DAYPASS_OUTPUT_DIR/$arch_name"

        cp -a \
            "$arch_dir/." \
            "$DAYPASS_OUTPUT_DIR/$arch_name/"

        log_success "Output generated for ${arch_name}"

    done

    echo -e "${GRAY}------------------------------------------------------------${NC}"

    log_success "DayPass Build Completed Successfully."

    log_info "Artifacts:"
    log_info "$DAYPASS_OUTPUT_DIR"

}

###############################################################################
# Run
###############################################################################

main "$@"