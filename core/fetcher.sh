#!/usr/bin/env bash

set -euo pipefail

source "$DAYPASS_ROOT/core/context.sh"
source "$DAYPASS_PROVIDER_DIR/sourceforge.sh"

fetch_all_packages() {

    local proxy="${1:-}"

    if [[ ! -f "$DAYPASS_ARCH_FILE" ]]; then
        log_error "Architecture configuration not found."
        return 1
    fi

    local arch_count
    arch_count=$(jq '.architectures | length' "$DAYPASS_ARCH_FILE")

    [[ "$arch_count" -le 0 ]] && {
        log_error "No architectures defined."
        return 1
    }

    for ((i=0; i<arch_count; i++)); do

        local arch_name
        local base_url
        local feed_count

        arch_name=$(jq -r ".architectures[$i].name" "$DAYPASS_ARCH_FILE")
        base_url=$(jq -r ".architectures[$i].base_url" "$DAYPASS_ARCH_FILE")
        feed_count=$(jq ".architectures[$i].feeds | length" "$DAYPASS_ARCH_FILE")

        log_info "Processing Architecture: ${PURPLE}${arch_name}${NC}"

        local arch_dir="$DAYPASS_TEMP_DIR/$arch_name"

        mkdir -p "$arch_dir"

        for ((j=0; j<feed_count; j++)); do

            local feed_name
            local feed_url
            local feed_dir

            feed_name=$(jq -r ".architectures[$i].feeds[$j]" "$DAYPASS_ARCH_FILE")

            feed_url="$base_url/$feed_name"
            feed_dir="$arch_dir/$feed_name"

            mkdir -p "$feed_dir"

            log_info "Fetching Feed: ${CYAN}${feed_name}${NC}"

            ####################################################################
            # index.json
            ####################################################################

            if ! provider_download_index \
                "$feed_url" \
                "$feed_dir/index.json" \
                "$proxy"
            then
                log_error "Unable to fetch index.json"
                continue
            fi

            ####################################################################
            # packages.adb
            ####################################################################

            if ! provider_download_database \
                "$feed_url" \
                "$feed_dir/packages.adb" \
                "$proxy"
            then
                log_warning "packages.adb not available."
            fi

            ####################################################################
            # Parse Packages
            ####################################################################

            local packages

            packages=$(
                jq -r \
                '.packages | to_entries[] | "\(.key)-\(.value).apk"' \
                "$feed_dir/index.json" \
                2>/dev/null
            )

            if [[ -z "$packages" ]]; then

                packages=$(
                    jq -r \
                    '.. | .packages? // empty | to_entries[] | "\(.key)-\(.value).apk"' \
                    "$feed_dir/index.json" \
                    2>/dev/null
                )

            fi

            [[ -z "$packages" ]] && {
                log_warning "No packages found."
                continue
            }

            ####################################################################
            # Download Packages
            ####################################################################

            while read -r pkg; do

                [[ -z "$pkg" ]] && continue

                log_info "Downloading ${GREEN}${pkg}${NC}"

                provider_download_package \
                    "$feed_url" \
                    "$pkg" \
                    "$feed_dir/$pkg" \
                    "$proxy"

            done <<< "$packages"

            log_success "Feed synchronized."

        done

        ########################################################################
        # Generate Catalog
        ########################################################################

        (
            cd "$arch_dir" || exit

            find . \
                -type f \
                -name "*.apk" \
                | sed 's#^\./##' \
                | sort \
                > catalog.txt
        )

        log_success "Catalog generated for ${arch_name}"

    done

    return 0

}