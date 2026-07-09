#!/usr/bin/env bash

set -euo pipefail

source "$DAYPASS_ROOT/core/context.sh"
source "$DAYPASS_ROOT/core/cache.sh"
source "$DAYPASS_PROVIDER_DIR/sourceforge.sh"

fetch_all_packages() {

    local proxy="${1:-}"

    [[ -f "$DAYPASS_ARCH_FILE" ]] || {
        log_error "Architecture configuration not found."
        return 1
    }

    local arch_count
    arch_count=$(jq '.architectures | length' "$DAYPASS_ARCH_FILE")

    for ((i=0; i<arch_count; i++)); do

        local arch_name
        local base_url
        local feed_count

        arch_name=$(jq -r ".architectures[$i].name" "$DAYPASS_ARCH_FILE")
        base_url=$(jq -r ".architectures[$i].base_url" "$DAYPASS_ARCH_FILE")
        feed_count=$(jq ".architectures[$i].feeds | length" "$DAYPASS_ARCH_FILE")

        local arch_dir="$DAYPASS_TEMP_DIR/$arch_name"

        mkdir -p "$arch_dir"

        log_info "Processing ${PURPLE}${arch_name}${NC}"

        for ((j=0; j<feed_count; j++)); do

            local feed_name
            local feed_url
            local feed_dir
            local index_file
            local checksum_file
            local repository_changed=1

            feed_name=$(jq -r ".architectures[$i].feeds[$j]" "$DAYPASS_ARCH_FILE")

            feed_url="$base_url/$feed_name"
            feed_dir="$arch_dir/$feed_name"

            mkdir -p "$feed_dir"

            index_file="$feed_dir/index.json"
            checksum_file="$DAYPASS_CHECKSUM_CACHE/${arch_name}_${feed_name}.sha"

            log_info "Feed ${CYAN}${feed_name}${NC}"

            ####################################################################
            # Download index
            ####################################################################

            provider_download_index \
                "$feed_url" \
                "$index_file" \
                "$proxy"

            ####################################################################
            # Repository changed?
            ####################################################################

            if cache_has "$checksum_file"; then

                if ! cache_checksum_changed \
                    "$index_file" \
                    "$checksum_file"
                then

                    repository_changed=0

                fi

            fi

            cache_save_checksum \
                "$index_file" \
                "$checksum_file"

            ####################################################################
            # Package List
            ####################################################################

            local packages

            packages=$(
                jq -r \
                '.packages | to_entries[] | "\(.key)-\(.value).apk"' \
                "$index_file"
            )

            ####################################################################
            # Restore Feed
            ####################################################################

            if [[ "$repository_changed" -eq 0 ]]; then

                log_info "Repository unchanged."

                cache_feed_restore \
                    "$arch_name" \
                    "$feed_name" \
                    "$feed_dir"

                log_success "Feed restored from cache."

                continue

            fi

            log_info "Repository updated."

            ####################################################################
            # Sync Packages
            ####################################################################

            while read -r pkg; do

                [[ -z "$pkg" ]] && continue

                local target="$feed_dir/$pkg"

                if cache_package_has \
                    "$arch_name" \
                    "$feed_name" \
                    "$pkg"
                then

                    log_info "Cached ${GREEN}${pkg}${NC}"

                    cache_package_restore \
                        "$arch_name" \
                        "$feed_name" \
                        "$pkg" \
                        "$target"

                    continue

                fi

                log_info "Downloading ${GREEN}${pkg}${NC}"

                provider_download_package \
                    "$feed_url" \
                    "$pkg" \
                    "$target" \
                    "$proxy"

                cache_package_save \
                    "$arch_name" \
                    "$feed_name" \
                    "$pkg" \
                    "$target"

            done <<< "$packages"

            ####################################################################
            # Save Feed Cache
            ####################################################################

            cache_feed_save \
                "$arch_name" \
                "$feed_name" \
                "$feed_dir"

            log_success "Feed synchronized."

        done

    done

}