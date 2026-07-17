#!/bin/sh

resolve_packages()
{
    FINAL_PACKAGES=""

    add_final()
    {
        pkg="$1"

        [ -z "$pkg" ] && return

        case " $FINAL_PACKAGES " in

            *" $pkg "*)
                ;;

            *)
                FINAL_PACKAGES="$FINAL_PACKAGES $pkg"
                ;;
        esac
    }

    # Base selected packages
    #
    for pkg in $SELECTED_PACKAGES
    do
        add_final "$pkg"
    done

    # Passwall dependencies
    #
    case "$SELECTED_PROFILE" in


    passwall|passwall2)


        # dependencies MUST install first
        add_final "tcping"
        add_final "geoview"


        case "$SELECTED_ENGINE" in

        xray)
            add_final "xray-core"
            ;;


        sing-box)
            add_final "sing-box"
            ;;


        auto)
            add_final "xray-core"
            ;;

        esac

    ;;

    esac

    # Language
    #
    case "$SELECTED_LANGUAGE" in

        fa)
            add_final "luci-i18n-passwall2-fa"
        ;;


        zh-cn)
            add_final "luci-i18n-passwall2-zh-cn"
        ;;


        ru)
            add_final "luci-i18n-passwall2-ru"
        ;;

    esac

    # Geo
    #
    if [ "$SELECTED_GEO" = "official" ]; then

        add_final "v2ray-geoip"
        add_final "v2ray-geosite"

    fi

    # Passwall package LAST
    #
    case "$SELECTED_PROFILE" in

        passwall2)
            add_final "luci-app-passwall2"
        ;;


        passwall)
            add_final "luci-app-passwall"
        ;;

    esac

    export FINAL_PACKAGES

}