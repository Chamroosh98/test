#!/bin/sh

handle_custom_profile() {

    clear

    show_banner

    echo
    echo "Enter package names separated by spaces."
    echo

    printf "> "

    read -r packages

    for pkg in $packages
    do
        add_package "$pkg"
    done

}