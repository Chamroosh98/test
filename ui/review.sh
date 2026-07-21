#!/bin/sh

review_install()
{
    resolve_packages

    echo
    echo "Selected Profile  : ${SELECTED_PROFILE}"
    echo "Selected Engine   : ${SELECTED_ENGINE:-auto}"
    echo "Language          : ${SELECTED_LANGUAGE:-none}"
    echo "Geo Database      : ${SELECTED_GEO:-none}"
    echo
    echo "Resolved Packages :"
    echo "-------------------"

    for pkg in $FINAL_PACKAGES; do
        echo "  [+] $pkg"
    done

    echo

    while true; do
        printf "  ⁉️ Continue? [y/N] : "
        read -r confirm </dev/tty

        case "$confirm" in
            y|Y)
                return 0
                ;;
            n|N|"")
                log_warn "Installation cancelled!"
                return 1
                ;;
            *)
                log_error "Invalid input! Please enter Y or N."
                ;;
        esac
    done
}