#!/bin/sh

language_menu()
{
    if [ "$SELECTED_PROFILE" != "passwall2" ]; then
        SELECTED_LANGUAGE="en"
        export SELECTED_LANGUAGE
        return 0
    fi

    render_persistent_header

    echo " Language Selection (Passwall 2)"
    echo " ────────────────────────────────"
    echo "  1) Persian (fa)"
    echo "  2) English (en)"
    echo "  3) Chinese (zh-cn)"
    echo "  4) Russian (ru)"
    echo

    printf "  ⁉️ Choice : "
    read -r choice </dev/tty

    case "$choice" in
        1)
            SELECTED_LANGUAGE="fa"
            add_selected_package "luci-i18n-passwall2-fa"
            ;;
        2)
            SELECTED_LANGUAGE="en"
            ;;
        3)
            SELECTED_LANGUAGE="zh-cn"
            add_selected_package "luci-i18n-passwall2-zh-cn"
            ;;
        4)
            SELECTED_LANGUAGE="ru"
            add_selected_package "luci-i18n-passwall2-ru"
            ;;
        *)
            SELECTED_LANGUAGE="en"
            ;;
    esac

    export SELECTED_LANGUAGE
}