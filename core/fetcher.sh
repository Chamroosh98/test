#!/usr/bin/env bash

set -euo pipefail

source "$DAYPASS_ROOT/core/context.sh"
source "$DAYPASS_ROOT/core/cache.sh"
source "$DAYPASS_PROVIDER_DIR/sourceforge.sh"

fetch_all_packages() {

    local target_arch="${1:-}"
    local proxy="${2:-}"

    [[ -f "$DAYPASS_ARCH_FILE" ]] || {
        log_error " Architecture configuration not found!"
        return 1
    }

    local arch_count
    arch_count=$(jq '.architectures | length' "$DAYPASS_ARCH_FILE")

    for ((i=0; i<arch_count; i++)); do

        local arch_name
        arch_name=$(jq -r ".architectures[$i].name" "$DAYPASS_ARCH_FILE")

        if [[ -n "$target_arch" && "$arch_name" != "$target_arch" ]]; then
            continue
        fi

        local base_url
        local feed_count
        base_url=$(jq -r ".architectures[$i].base_url" "$DAYPASS_ARCH_FILE")
        feed_count=$(jq ".architectures[$i].feeds | length" "$DAYPASS_ARCH_FILE")

        local arch_dir="$DAYPASS_TEMP_DIR/$arch_name"
        mkdir -p "$arch_dir"

        log_info "  Processing ${PURPLE}${arch_name}${NC}"

        for ((j=0; j<feed_count; j++)); do
            local feed_name
            local feed_url
            local feed_dir
            local index_file

            feed_name=$(jq -r ".architectures[$i].feeds[$j]" "$DAYPASS_ARCH_FILE")
            feed_url="$base_url/$feed_name"
            feed_dir="$arch_dir/$feed_name"

            mkdir -p "$feed_dir"
            index_file="$feed_dir/index.json"

            log_info "  Feed ${CYAN}${feed_name}${NC}"

            provider_download_index "$feed_url" "$index_file" "$proxy"

            local packages
            packages=$(jq -r '.packages | to_entries[] | "\(.key)-\(.value).apk"' "$index_file")
            log_info "  Repository updated!"

            while read -r pkg; do
                [[ -z "$pkg" ]] && continue

                package_full="${pkg%.apk}"
                package_version="$(echo "$package_full" | grep -oE '[0-9].*$' || echo "unknown")"
                package_name="${package_full%"$package_version"}"
                package_name="${package_name%-}"

                target="$feed_dir/$pkg"

                cached_version="$(cache_package_version "$arch_name" "$feed_name" "$package_name")"

                if [[ "$cached_version" == "$package_version" ]]; then
                    log_info "Cached ${GREEN}${pkg}${NC}"
                    cache_package_restore "$arch_name" "$feed_name" "$pkg" "$target"
                    continue
                fi

                log_info "  Downloading ${GREEN}${pkg}${NC}"
                provider_download_package "$feed_url" "$pkg" "$target" "$proxy"
                cache_package_save "$arch_name" "$feed_name" "$pkg" "$target"
                cache_package_set_version "$arch_name" "$feed_name" "$package_name" "$package_version"

            done <<< "$packages"

            log_success "   Feed synchronized!"
        done
    done
}