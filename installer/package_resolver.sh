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
                # Already exists! skip
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

    # 1. Prerequisites / Low-level tools
    add_final "tcping"
    add_final "geoview"

    # 2. Famous DBs
    if [ "${SELECTED_GEO:-}" = "official" ]; then
        add_final "v2ray-geoip"
        add_final "v2ray-geosite"
    fi

    # 3. Engine Core
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

    # 4. User-selected custom packages (excluding main app and i18n to maintain strict hierarchy)
    if [ -n "${SELECTED_PACKAGES:-}" ]; then
        for pkg in $SELECTED_PACKAGES; do
            case "$pkg" in
                luci-app-passwall|luci-app-passwall2|luci-i18n-*) 
                    ;; # Skip here, will be added in controlled order below
                *) 
                    add_final "$pkg" 
                    ;;
            esac
        done
    fi

    # 5. Main Application Interface (MUST BE INSTALLED BEFORE TRANSLATION)
    case "${SELECTED_PROFILE:-}" in
        passwall2) add_final "luci-app-passwall2" ;;
        passwall)  add_final "luci-app-passwall" ;;
    esac

    # 6. Language and Translations (MUST BE INSTALLED AFTER MAIN APP)
    case "${SELECTED_LANGUAGE:-}" in
        fa)    add_final "luci-i18n-passwall2-fa" ;;
        zh-cn) add_final "luci-i18n-passwall2-zh-cn" ;;
        ru)    add_final "luci-i18n-passwall2-ru" ;;
    esac

    if [ -z "$FINAL_PACKAGES" ]; then
        log_error "Package resolution finished with an empty package list!"
        return 1
    fi

    log_success "Package resolution complete."
    log_info "Final target list : [$FINAL_PACKAGES]"

    export FINAL_PACKAGES
}