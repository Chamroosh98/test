#!/bin/sh

main_menu()
{
    while true; do
        clear
        show_banner
        show_system_info
        get_network_info

        printf "  📦 %s1%s) Install Package\n" "$CYAN" "$RESET"
        printf "  🖥️  %s2%s) Network Speed Monitor\n" "$CYAN" "$RESET"
        printf "  🚪 %s3%s) Exit\n\n" "$CYAN" "$RESET"

        printf "  ⁉️  %sChoice%s %s:%s " "$YELLOW" "$RESET" "$GRAY" "$RESET"

        read -r choice </dev/tty

        case "$choice" in
            1)
                if command -v package_menu >/dev/null 2>&1; then
                    package_menu || true
                elif command -v install_package_menu >/dev/null 2>&1; then
                    install_package_menu || true
                else
                    log_error "Package menu function not found!"
                    sleep 1
                fi
                ;;
            2)
                if command -v show_live_speed >/dev/null 2>&1; then
                    show_live_speed || true
                    echo
                    printf "  %bPress [Enter] to return to main menu ...%b" "$GRAY" "$RESET"
                    read -r _ </dev/tty
                else
                    log_error "Live speed function not found!"
                    sleep 1
                fi
                ;;
            3)
                log_info "Exiting DayPass ..."
                exit 0
                ;;
            *)
                log_error "Invalid choice!"
                sleep 1
                ;;
        esac
    done
}