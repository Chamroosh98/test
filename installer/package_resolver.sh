#!/bin/sh

resolve_packages()
{
    log_info "Resolving targeted packages and dependencies..."

    FINAL_PACKAGES=""

    add_final()
    {
        pkg="$1"
        [ -z "$pkg" ] && return

        case " $FINAL_PACKAGES " in
            *" $pkg "*) 
                # Already exits! skip
                ;;
            *) 
                if [ -z "$FINAL_PACKAGES" ]; then
                    FINAL_PACKAGES="$pkg"
                else
                    FINAL_PACKAGES="$FINAL_PACKAGES $pkg"
                fi
                log_info "  ├─ Resolved dependency : [$pkg]"
                ;;
        esac
    }

    # Prerequisites
    add_final "tcping"
    add_final "geoview"

    # Famous DB
    if [ "${SELECTED_GEO:-}" = "official" ]; then
        add_final "v2ray-geoip"
        add_final "v2ray-geosite"
    fi

    # Engine Core
    case "${SELECTED_ENGINE:-auto}" in
        xray)     
            add_final "xray-core" 
            ;;
        sing-box) 
            add_final "sing-box" 
            ;;
        auto|*)     
            add_final "xray-core" 
            ;;
    esac

    # Language and translations
    case "${SELECTED_LANGUAGE:-}" in
        fa)    add_final "luci-i18n-passwall2-fa" ;;
        zh-cn) add_final "luci-i18n-passwall2-zh-cn" ;;
        ru)    add_final "luci-i18n-passwall2-ru" ;;
    esac

    # User-selected custom packages
    if [ -n "${SELECTED_PACKAGES:-}" ]; then
        for pkg in $SELECTED_PACKAGES; do
            add_final "$pkg"
        done
    fi

    # 6. Main User Interface 
    case "${SELECTED_PROFILE:-}" in
        passwall2) add_final "luci-app-passwall2" ;;
        passwall)  add_final "luci-app-passwall" ;;
    esac

    if [ -z "$FINAL_PACKAGES" ]; then
        log_error "Package resolution finished with an empty package list!"
        return 1
    fi

    log_success "Package resolution complete."
    log_info "Final target list : [$FINAL_PACKAGES]"

    export FINAL_PACKAGES
}