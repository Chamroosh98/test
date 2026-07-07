#!/bin/sh

check_version() {

    if ! command -v opkg >/dev/null 2>&1; then
        return
    fi

    OPENWRT_VERSION="$(
        . /etc/openwrt_release 2>/dev/null
        echo "$DISTRIB_RELEASE"
    )"

    echo "OpenWrt Version : ${OPENWRT_VERSION:-Unknown}"

}