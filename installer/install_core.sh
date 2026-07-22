#!/bin/sh

initialize_installer()
{
    detect_package_manager

    log_info "Updating package database ..."
    pkg_update >/dev/null 2>&1 || log_warn "Package index update finished with warnings!"

    TMP_DIR="/tmp/daypass"
    mkdir -p "$TMP_DIR"

    MANIFEST_FILE="$TMP_DIR/manifest.json"

    if [ -z "${REPO_URL:-}" ]; then
        log_error "REPO_URL is not set!"
        exit 1
    fi

    # clear

    log_info "Downloading architecture manifest from : [$REPO_URL/manifest.json]"
    if ! curl -fsSL "$REPO_URL/manifest.json" -o "$MANIFEST_FILE"; then
        log_error "Failed to download manifest from [$REPO_URL/manifest.json]"
        exit 1
    fi

    if [ ! -s "$MANIFEST_FILE" ]; then
        log_error "Downloaded manifest file is empty!"
        exit 1
    fi

    if [ -f /etc/openwrt_release ]; then
        ARCH=$(grep "DISTRIB_ARCH" /etc/openwrt_release | cut -d"'" -f2)
    else
        ARCH="$(uname -m)"
    fi

    if [ -z "$ARCH" ]; then
        log_error "Unable to detect architecture!"
        exit 1
    fi

    if ! jq -e --arg arch "$ARCH" '.architectures[] | select(.name == $arch)' "$MANIFEST_FILE" >/dev/null 2>&1; then
        log_error "Architecture not supported in manifest: $ARCH"
        exit 1
    fi

    log_success "Manifest loaded successfully for architecture : [$ARCH] "

    export ARCH
    export TMP_DIR
    export MANIFEST_FILE
}