#!/bin/sh

deploy_system_dependencies()
{
    echo "  🔎 Checking system dependencies ..."

    detect_package_manager

    pkg_update

    REQUIRED_PACKAGES="\
        curl \
        jq \
        ca-bundle \
        ca-certificates"

    for pkg in $REQUIRED_PACKAGES
        do
            if pkg_installed "$pkg"
                then
                    continue
            fi
            echo "  📍 Installing $pkg ..."
            pkg_install "$pkg"
        done

    if [ -f /etc/openwrt_release ]
        then
            echo
            echo "  🔎 Checking dnsmasq ..."

            case "$PKG_MANAGER" in

                opkg)
                    if opkg list-installed | grep -q "^dnsmasq "
                        then
                            echo "  🧼 Removing dnsmasq ..."
                            pkg_remove dnsmasq
                    fi

                    if ! pkg_installed dnsmasq-full
                        then
                            echo "  📍 Installing dnsmasq-full ..."
                            pkg_install dnsmasq-full
                        else
                            echo "  💣 dnsmasq-full already installed! "
                    fi
                ;;
                apk)
                    if apk info -e dnsmasq >/dev/null 2>&1
                        then
                            echo "  🧼 Removing dnsmasq ..."
                            pkg_remove dnsmasq
                    fi

                    if ! pkg_installed dnsmasq-full
                        then
                            echo "  📍 Installing dnsmasq-full ..."
                            pkg_install dnsmasq-full
                        else
                            echo "  💣 dnsmasq-full already installed! "
                    fi
                ;;
            esac
    fi
}