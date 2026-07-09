#!/usr/bin/env bash

set -euo pipefail

source "$DAYPASS_ROOT/core/context.sh"
source "$DAYPASS_ROOT/core/cache.sh"
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

            ###############################################################################
            # index.json
            ###############################################################################

            local index_file="$feed_dir/index.json"
            local cache_sha="$DAYPASS_CHECKSUM_CACHE/${arch_name}_${feed_name}.sha"

            if ! provider_download_index \
                "$feed_url" \
                "$index_file" \
                "$proxy"
            then
                log_error "Unable to fetch index.json"
                continue
            fi

            if cache_has "$cache_sha"; then

                if ! cache_is_changed "$index_file" "$cache_sha"; then

                    log_info "No changes detected."

                    continue

                fi

            fi

            cache_save_checksum \
                "$index_file" \
                "$cache_sha"

            log_info "Repository updated."

            ####################################################################
            # packages.adb
            ####################################################################

            # if ! provider_download_database \
            #     "$feed_url" \
            #     "$feed_dir/packages.adb" \
            #     "$proxy"
            # then
            #     log_warning "packages.adb not available."
            # fi

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

            ###############################################################################
            # Download Packages
            ###############################################################################

            while read -r pkg; do

                [[ -z "$pkg" ]] && continue

                local cache_pkg="$DAYPASS_PACKAGE_CACHE/$arch_name/$feed_name/$pkg"
                local target_pkg="$feed_dir/$pkg"

                mkdir -p "$(dirname "$cache_pkg")"

                ###############################################################################
                # Check Repository Changes
                ###############################################################################

                local repository_changed=1

                if cache_has "$cache_sha"; then

                    if ! cache_is_changed "$index_file" "$cache_sha"; then

                        repository_changed=0

                        log_info "Repository unchanged."

                    fi

                fi

                cache_save_checksum \
                    "$index_file" \
                    "$cache_sha"

                ###########################################################################
                # Download (Only if Repository Changed)
                ###########################################################################

                if [[ "$repository_changed" -eq 1 ]]; then

                    log_info "Downloading ${GREEN}${pkg}${NC}"

                    provider_download_package \
                        "$feed_url" \
                        "$pkg" \
                        "$target_pkg" \
                        "$proxy"

                    cache_put \
                        "$target_pkg" \
                        "$cache_pkg"

                else

                    log_info "Restored ${GREEN}${pkg}${NC} from cache"

                    cache_get \
                        "$cache_pkg" \
                        "$target_pkg"

                fi                

            done <<< "$packages"

            log_success "Feed synchronized!"

        done


    done

    return 0

}