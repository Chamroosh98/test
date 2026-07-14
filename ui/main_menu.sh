#!/bin/sh

show_dashboard()
{
    echo
    box_header "🖥  System Information"
    show_system_info_content
    box_subheader "🌐 Network"
    get_network_info_content
    box_footer
}

main_menu()
{
    while true
        do

            clear
            show_banner
            show_dashboard

            echo
            echo "  📦 1) Install Package"
            echo "  🌐 2) Network Diagnostics"
            echo "  🚪 3) Exit"
            echo

            printf "  ⁉️ Choice : "
            read -r choice </dev/tty

            case "$choice" in

                1)
                    package_menu || exit 1
                    exit 0
                    ;;

                2)
                    network_check
                    echo
                    printf "  ⏎  برای بازگشت Enter بزن..."
                    read -r _ </dev/tty
                    ;;

                3)
                    exit 0
                    ;;

                *)
                    echo "  ❌ Invalid choice!"
                    sleep 1
                    ;;

            esac

        done
}

main_menu