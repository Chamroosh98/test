#!/bin/sh

handle_custom_profile()
{

    clear

    show_banner


    echo
    echo "  📝 Enter package names separated by spaces! "
    echo


    printf "> "

    read -r packages </dev/tty


    for pkg in $packages
    do

        add_selected_package "$pkg"

    done

}