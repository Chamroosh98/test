#!/bin/sh

detect_package_manager() {
    if command -v opkg >/dev/null 2>&1; then
        PKG_MANAGER="opkg"
        return
    fi

    if command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
        return
    fi

    log_error "Unsupported package manager!"
    exit 1
}

pkg_update() {
    case "$PKG_MANAGER" in
        opkg) opkg update || true ;;
        apk)  apk update || true ;;
    esac
}

pkg_install() {
    case "$PKG_MANAGER" in
        opkg) opkg install "$@" ;;
        apk)  apk add --allow-untrusted "$@" ;;
    esac
}

pkg_remove() {
    case "$PKG_MANAGER" in
        opkg) opkg remove "$@" ;;
        apk)  apk del "$@" ;;
    esac
}

pkg_installed() {
    case "$PKG_MANAGER" in
        opkg) opkg list-installed | grep -q "^$1 " ;;
        apk)  apk info -e "$1" >/dev/null 2>&1 ;;
    esac
}