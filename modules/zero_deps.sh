#!/bin/sh

deploy_system_dependencies()
{

    echo "Checking system dependencies..."


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


        echo "Installing $pkg ..."


        pkg_install "$pkg"

    done



    ###########################################################################
    # OpenWrt dnsmasq-full
    ###########################################################################

    if [ -f /etc/openwrt_release ]
    then

        echo
        echo "Checking dnsmasq..."

        if opkg list-installed | grep -q "^dnsmasq "
        then

            echo "[INFO] Removing dnsmasq..."

            opkg remove dnsmasq

        fi



        if ! opkg list-installed | grep -q "^dnsmasq-full "
        then

            echo "[INFO] Installing dnsmasq-full..."

            opkg update

            opkg install dnsmasq-full

        else

            echo "[ OK ] dnsmasq-full already installed"

        fi

    fi


}