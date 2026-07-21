#!/bin/sh

detect_package_manager()
{
    if command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
    elif command -v opkg >/dev/null 2>&1; then
        PKG_MANAGER="opkg"
    else
        log_error "Neither apk nor opkg package manager found!"
        exit 1
    fi
}

pkg_update()
{
    log_info "Updating package lists using $PKG_MANAGER ..."

    if [ "$PKG_MANAGER" = "apk" ]; then
        if ! apk update --force-ipv4 --network-timeout 5 >/dev/null 2>&1; then
            log_warn "APK update faced minor repository issues (possibly IPv6 or blocked mirrors)."
            log_warn "Proceeding with existing cached indexes ..."
        fi
    elif [ "$PKG_MANAGER" = "opkg" ]; then
        if ! opkg update >/dev/null 2>&1; then
            log_warn "OPKG update faced minor warnings. Proceeding anyway ..."
        fi
    fi
}

pkg_install()
{
    PACKAGE_NAME="$1"

    if [ "$PKG_MANAGER" = "apk" ]; then
        apk add --force-ipv4 "$PACKAGE_NAME" >/dev/null 2>&1
    elif [ "$PKG_MANAGER" = "opkg" ]; then
        opkg install "$PACKAGE_NAME" >/dev/null 2>&1
    fi
}