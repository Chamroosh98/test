#!/bin/sh

deploy_system_dependencies() {

    echo "Checking system dependencies..."

    detect_package_manager

    pkg_update

    REQUIRED_PACKAGES="\
curl \
ca-bundle \
ca-certificates"

    for pkg in $REQUIRED_PACKAGES
    do

        if pkg_installed "$pkg"; then
            continue
        fi

        echo "Installing $pkg ..."

        pkg_install "$pkg"

    done

}