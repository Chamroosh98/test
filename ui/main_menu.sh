#!/bin/sh

main_menu()
{

    while true
        do

            clear
            show_banner
            show_system_info


            echo
            echo "  📦 1) Install Package"
            echo "  🚪 2) Exit"
            echo


            printf "  🤔 Choice : "
            read -r choice </dev/tty


            case "$choice" in

            1)
                package_menu || exit 1
                exit 0
            ;;

            2)
                exit 0
                ;;

            *)
                echo "  😒 Invalid choice!"
                sleep 1
                ;;

            esac

        done
}