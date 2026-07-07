#!/usr/bin/env bash

set -euo pipefail

source "$DAYPASS_ROOT/core/context.sh"

cache_init() {

    mkdir -p \
        "$DAYPASS_INDEX_CACHE" \
        "$DAYPASS_PACKAGE_CACHE" \
        "$DAYPASS_METADATA_CACHE" \
        "$DAYPASS_CHECKSUM_CACHE"

}

cache_has() {

    local file="$1"

    [[ -f "$file" ]]

}

cache_put() {

    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"

    cp -f "$source" "$target"

}

cache_get() {

    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"

    cp -f "$source" "$target"

}

cache_remove() {

    local file="$1"

    rm -f "$file"

}

cache_clear() {

    rm -rf "$DAYPASS_CACHE_DIR"

    cache_init

}

cache_sha256() {

    local file="$1"

    sha256sum "$file" | awk '{print $1}'

}

cache_is_changed() {

    local file="$1"
    local checksum_file="$2"

    [[ ! -f "$checksum_file" ]] && return 0

    local current
    local old

    current=$(cache_sha256 "$file")
    old=$(cat "$checksum_file")

    [[ "$current" != "$old" ]]

}

cache_save_checksum() {

    local file="$1"
    local checksum_file="$2"

    cache_sha256 "$file" > "$checksum_file"

}