#!/bin/sh

engine_menu()
{

    echo

    echo "Proxy Engine"

    echo "-------------"

    echo "  1) Auto"
    echo "  2) Xray"
    echo "  3) Sing-box"

    printf "  ⁉️ Choice : "
    read -r choice </dev/tty


    case "$choice" in

        1)
            SELECTED_ENGINE="auto"
        ;;

        2)
            SELECTED_ENGINE="xray"
            add_selected_package "xray-core"
        ;;

        3)
            SELECTED_ENGINE="sing-box"

            echo
            echo "  ⚠️ WARNING :"
            echo "  Sing-box may consume more RAM on low-end devices."
            echo

            printf "  ⁉️ Continue? [y/N] : "
            read -r confirm </dev/tty

            case "$confirm" in

                y|Y)
                    add_selected_package "sing-box"
                ;;

                *)
                    SELECTED_ENGINE="auto"
                ;;

            esac

        ;;

        *)
            SELECTED_ENGINE="auto"
        ;;

    esac

    export SELECTED_ENGINE

}