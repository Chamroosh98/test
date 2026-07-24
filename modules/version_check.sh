#!/bin/sh

check_version() {
    if ! command -v opkg >/dev/null 2>&1 && ! command -v apk >/dev/null 2>&1; then
        log_error "No supported package manager found!"
        return 1
    fi

    OPENWRT_VERSION="$(
        . /etc/openwrt_release 2>/dev/null
        echo "$DISTRIB_RELEASE"
    )"

    if [ -z "$OPENWRT_VERSION" ]; then
        log_warn "Unable to detect OpenWrt version!"
    else
        log_info "OpenWrt Version : ${OPENWRT_VERSION}"
    fi
}