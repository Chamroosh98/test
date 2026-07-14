#!/bin/sh

review_install()
{

    resolve_packages

    echo

    echo "Selected Profile"
    echo "----------------"

    echo "$SELECTED_PROFILE"


    echo

    echo "Selected Engine"
    echo "---------------"

    echo "${SELECTED_ENGINE:-auto}"


    echo

    echo "Language"
    echo "--------"

    echo "${SELECTED_LANGUAGE:-none}"


    echo

    echo "Geo Database"
    echo "------------"

    echo "${SELECTED_GEO:-none}"


    echo

    echo "Selected Packages"
    echo "-----------------"

    echo "Resolved Packages"
    echo "-----------------"

    for pkg in $FINAL_PACKAGES
        do
            echo "[+] $pkg"
        done

    echo

    
    while true
        do

            printf "  ⁉️ Continue? [y/N] : "
            read -r confirm </dev/tty

            case "$confirm" in

                y|Y)
                    return 0
                    ;;

                n|N|"")
                    echo "  ❌ Installation cancelled!"
                    exit 0
                    ;;

                *)
                    echo "  ❌ Invalid input! Please enter JUST y or n!"
                    ;;

            esac

        done

}