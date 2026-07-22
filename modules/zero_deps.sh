#!/bin/sh

deploy_system_dependencies()
{
    echo "  🔎 Checking system dependencies ..."

    detect_package_manager
    pkg_update

    REQUIRED_PACKAGES="curl jq ca-bundle ca-certificates"

    for pkg in $REQUIRED_PACKAGES; do
        if pkg_installed "$pkg"; then
            continue
        fi
        echo "  📍 Installing $pkg ..."
        pkg_install "$pkg"
    done

    if [ -f /etc/openwrt_release ]; then
        echo
        echo "  🔎 Checking dnsmasq ..."

        if ! pkg_installed "dnsmasq-full"; then
            echo "  📍 Upgrading dnsmasq to dnsmasq-full ..."
            case "$PKG_MANAGER" in
                opkg)
                    opkg install dnsmasq-full --replace-files
                    ;;
                apk)
                    apk add dnsmasq-full
                    ;;
            esac
        else
            echo "  💣 dnsmasq-full is already installed!"
        fi
    fi
}