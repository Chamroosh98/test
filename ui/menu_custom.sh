#!/bin/sh

handle_custom_profile()
{
    ALL_AVAILABLE_PKGS="$(jq -r --arg arch "$ARCH" '.architectures[] | select(.name==$arch) | .packages[].package' "$MANIFEST_FILE" 2>/dev/null)"

    if [ -z "$ALL_AVAILABLE_PKGS" ]; then
        log_error "No packages found in manifest for architecture: $ARCH"
        return 1
    fi

    PAGE_SIZE=5
    CURRENT_PAGE=1
    TOTAL_PKGS=$(echo "$ALL_AVAILABLE_PKGS" | wc -w)
    TOTAL_PAGES=$(( (TOTAL_PKGS + PAGE_SIZE - 1) / PAGE_SIZE ))

    while true; do
        render_persistent_header

        echo " 🛠️ Custom Package Selection (Page $CURRENT_PAGE of $TOTAL_PAGES)"
        echo " ──────────────────────────────────────────────────────────"

        START_IDX=$(( (CURRENT_PAGE - 1) * PAGE_SIZE + 1 ))
        END_IDX=$(( CURRENT_PAGE * PAGE_SIZE ))

        i=1
        item_no=1
        eval set -- "$ALL_AVAILABLE_PKGS"
        
        for pkg in "$@"; do
            if [ "$i" -ge "$START_IDX" ] && [ "$i" -le "$END_IDX" ]; then
                
                is_selected=" "
                case " $SELECTED_PACKAGES " in
                    *" $pkg "*) is_selected="🟢" ;;
                esac
                
                printf "  %d) [%s] %s\n" "$item_no" "$is_selected" "$pkg"
                item_no=$((item_no + 1))
            fi
            i=$((i + 1))
        done

        echo " ──────────────────────────────────────────────────────────"
        echo "  [n] Next Page  |  [p] Prev Page  |  [d] Done Selection"
        echo

        printf "  ⁉️ Toggle Item (1-%d) or Action (n/p/d) : " $((item_no - 1))
        read -r cmd </dev/tty

        case "$cmd" in
            n|N)
                [ "$CURRENT_PAGE" -lt "$TOTAL_PAGES" ] && CURRENT_PAGE=$((CURRENT_PAGE + 1))
                ;;
            p|P)
                [ "$CURRENT_PAGE" -gt 1 ] && CURRENT_PAGE=$((CURRENT_PAGE - 1))
                ;;
            d|D)
                log_info "Custom package selection saved."
                break
                ;;
            [1-9])
                TARGET_INDEX=$(( START_IDX + cmd - 1 ))
                idx=1
                for pkg in "$@"; do
                    if [ "$idx" -eq "$TARGET_INDEX" ]; then
                        add_selected_package "$pkg"
                        break
                    fi
                    idx=$((idx + 1))
                done
                ;;
            *)
                log_warn "Invalid command!"
                sleep 1
                ;;
        esac
    done
}