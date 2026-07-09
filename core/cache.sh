#!/usr/bin/env bash

set -euo pipefail

source "$DAYPASS_ROOT/core/context.sh"

###############################################################################
# Init
###############################################################################

cache_init() {

    mkdir -p \
        "$DAYPASS_INDEX_CACHE" \
        "$DAYPASS_PACKAGE_CACHE" \
        "$DAYPASS_METADATA_CACHE" \
        "$DAYPASS_CHECKSUM_CACHE"

}

###############################################################################
# Generic
###############################################################################

cache_has() {

    [[ -f "$1" ]]

}

cache_put() {

    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    cp -af "$src" "$dst"

}

cache_get() {

    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    cp -af "$src" "$dst"

}

###############################################################################
# SHA
###############################################################################

cache_sha256() {

    sha256sum "$1" | awk '{print $1}'

}

cache_save_checksum() {

    cache_sha256 "$1" > "$2"

}

cache_checksum_changed() {

    local file="$1"
    local checksum="$2"

    [[ ! -f "$checksum" ]] && return 0

    [[ "$(cache_sha256 "$file")" != "$(cat "$checksum")" ]]

}

###############################################################################
# Feed Cache
###############################################################################

cache_feed_dir() {

    local arch="$1"
    local feed="$2"

    echo "$DAYPASS_PACKAGE_CACHE/$arch/$feed"

}

cache_feed_restore() {

    local arch="$1"
    local feed="$2"
    local target="$3"

    local cache_dir
    cache_dir="$(cache_feed_dir "$arch" "$feed")"

    [[ -d "$cache_dir" ]] || return 1

    mkdir -p "$target"

    cp -af "$cache_dir/." "$target/"

}

cache_feed_save() {

    local arch="$1"
    local feed="$2"
    local source="$3"

    local cache_dir
    cache_dir="$(cache_feed_dir "$arch" "$feed")"

    rm -rf "$cache_dir"

    mkdir -p "$cache_dir"

    cp -af "$source/." "$cache_dir/"

}

###############################################################################
# Package Cache
###############################################################################

cache_package_has() {

    local arch="$1"
    local feed="$2"
    local pkg="$3"

    [[ -f "$DAYPASS_PACKAGE_CACHE/$arch/$feed/$pkg" ]]

}

cache_package_restore() {

    local arch="$1"
    local feed="$2"
    local pkg="$3"
    local target="$4"

    mkdir -p "$(dirname "$target")"

    cp -af \
        "$DAYPASS_PACKAGE_CACHE/$arch/$feed/$pkg" \
        "$target"

}

cache_package_save() {

    local arch="$1"
    local feed="$2"
    local pkg="$3"
    local source="$4"

    local dst="$DAYPASS_PACKAGE_CACHE/$arch/$feed/$pkg"

    mkdir -p "$(dirname "$dst")"

    cp -af "$source" "$dst"

}

###############################################################################
# Package Version Metadata
###############################################################################

cache_package_version() {

    local arch="$1"
    local feed="$2"
    local package="$3"

    local version_file="$DAYPASS_METADATA_CACHE/$arch/$feed/$package.version"

    [[ -f "$version_file" ]] || return 0

    cat "$version_file"

}

cache_package_set_version() {

    local arch="$1"
    local feed="$2"
    local package="$3"
    local version="$4"

    local version_file="$DAYPASS_METADATA_CACHE/$arch/$feed/$package.version"

    mkdir -p "$(dirname "$version_file")"

    printf "%s" "$version" > "$version_file"

}