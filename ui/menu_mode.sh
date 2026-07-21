#!/bin/sh

menu_mode()
{
    render_persistent_header

    echo " Installation Mode"
    echo " ──────────────────"
    echo "  1) ⚡ Recommended (Quick & Pre-configured for standard users)"
    echo "  2) 🛠️ Custom / On-demand (Advanced package selection)"
    echo

    printf "  ⁉️ Choice : "
    read -r choice </dev/tty

    case "$choice" in
        1)
            handle_recommended_profile
            ;;
        2)
            handle_custom_profile
            ;;
        *)
            log_warn "Invalid choice! Defaulting to Recommended mode!"
            handle_recommended_profile
            ;;
    esac
}