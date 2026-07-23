#!/bin/sh

# ==============================================================================
# Package Resolver Module
# Dynamically resolves dependencies, core engines, translation packages,
# and geo-databases based on user choices from the TUI menus.
# ==============================================================================

resolve_packages()
{
    log_info "Resolving targeted packages and dependencies..."

    FINAL_PACKAGES=""

    # --------------------------------------------------------------------------
    # Helper: Adds package to FINAL_PACKAGES while preventing duplicates
    # --------------------------------------------------------------------------
    add_final()
    {
        pkg="$1"
        [ -z "$pkg" ] && return

        # Strict boundary check to prevent substring false positives
        case " $FINAL_PACKAGES " in
            *" $pkg "*) 
                # Package already present, skip
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

    # 1. Append user-selected base packages
    if [ -n "${SELECTED_PACKAGES:-}" ]; then
        for pkg in $SELECTED_PACKAGES; do
            add_final "$pkg"
        done
    fi

    # 2. Profile core engine & tool dependencies
    case "${SELECTED_PROFILE:-}" in
        passwall|passwall2)
            # Essential networking helper utilities
            add_final "tcping"
            add_final "geoview"

            # Core backend engine selection logic
            case "${SELECTED_ENGINE:-auto}" in
                xray)     
                    add_final "xray-core" 
                    ;;
                sing-box) 
                    add_final "sing-box" 
                    ;;
                auto|*)     
                    log_warn "Engine selection was empty or set to auto. Defaulting to [xray-core]."
                    add_final "xray-core" 
                    ;;
            esac
            ;;
        *)
            log_warn "No core profile selected or unknown profile : [${SELECTED_PROFILE:-none}]"
            ;;
    esac

    # 3. Resolve localization / translation packages (i18n)
    case "${SELECTED_LANGUAGE:-}" in
        fa)    add_final "luci-i18n-passwall2-fa" ;;
        zh-cn) add_final "luci-i18n-passwall2-zh-cn" ;;
        ru)    add_final "luci-i18n-passwall2-ru" ;;
        en|"") 
            # English is built-in by default
            ;;
    esac

    # 4. Geo-location databases resolution
    if [ "${SELECTED_GEO:-}" = "official" ]; then
        add_final "v2ray-geoip"
        add_final "v2ray-geosite"
    fi

    # 5. Primary App Interface Package (MUST BE APPENDED LAST)
    case "${SELECTED_PROFILE:-}" in
        passwall2) add_final "luci-app-passwall2" ;;
        passwall)  add_final "luci-app-passwall" ;;
    esac

    # Sanity check on final list
    if [ -z "$FINAL_PACKAGES" ]; then
        log_error "Package resolution finished with an empty package list!"
        return 1
    fi

    log_success "Package resolution complete."
    log_info "Final target list : [$FINAL_PACKAGES]"

    export FINAL_PACKAGES
}