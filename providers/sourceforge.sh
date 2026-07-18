#!/usr/bin/env bash

source "$DAYPASS_ROOT/core/context.sh"

provider_name() {
    echo "🟠 SourceForge"
}

provider_download() {

    local url="$1"
    local output="$2"
    local proxy="${3:-}"

    local timeout
    timeout=$(jq -r '.timeout' "$DAYPASS_SETTINGS_FILE")

    local retry
    retry=$(jq -r '.retry' "$DAYPASS_SETTINGS_FILE")

    if [[ -n "$proxy" ]]; then
        curl \
            --silent \
            --show-error \
            --location \
            --fail \
            --retry "$retry" \
            --connect-timeout "$timeout" \
            -x "$proxy" \
            -o "$output" \
            "$url"
    else
        curl \
            --silent \
            --show-error \
            --location \
            --fail \
            --retry "$retry" \
            --connect-timeout "$timeout" \
            -o "$output" \
            "$url"
    fi
}

provider_download_index() {

    local feed_url="$1"
    local output="$2"
    local proxy="${3:-}"

    provider_download \
        "$feed_url/index.json" \
        "$output" \
        "$proxy"
}

provider_download_database() {

    local feed_url="$1"
    local output="$2"
    local proxy="${3:-}"

    provider_download \
        "$feed_url/packages.adb" \
        "$output" \
        "$proxy"
}

provider_download_package() {

    local feed_url="$1"
    local package="$2"
    local output="$3"
    local proxy="${4:-}"

    provider_download \
        "$feed_url/$package" \
        "$output" \
        "$proxy"
}