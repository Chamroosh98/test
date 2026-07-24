#!/bin/sh

deploy_system_dependencies()
{
    echo "  🔎 Checking system dependencies ..."

    detect_package_manager
    pkg_update

    # 1st ca-bundle, ca-certificates that HTTPS working whell!
    REQUIRED_PACKAGES="ca-bundle ca-certificates curl jq"

    for pkg in $REQUIRED_PACKAGES; do
        if pkg_installed "$pkg"; then
            continue
        fi
        echo "  📦 Installing [$pkg] ..."
        pkg_install "$pkg"
    done

    if ! command -v curl >/dev/null 2>&1; then
        echo "  ⚠️ Warning : curl installation via [$PKG_MANAGER] failed. Falling back to wget ..."
    fi

    if [ -f /etc/openwrt_release ]; then
        echo
        echo "  🔎 Checking dnsmasq ..."

        if ! pkg_installed "dnsmasq-full"; then
            echo "  🔼 Upgrading dnsmasq to dnsmasq-full ..."
            case "$PKG_MANAGER" in
                opkg)
                    opkg install dnsmasq-full --replace-files >/dev/null 2>&1 || true
                    ;;
                apk)
                    apk add dnsmasq-full >/dev/null 2>&1 || true
                    ;;
            esac
        else
            echo "  💣 dnsmasq-full is already installed!"
        fi
    fi
}