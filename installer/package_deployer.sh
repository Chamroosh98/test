#!/bin/sh

INSTALL_LOG="/tmp/daypass/install.log"
TRANSACTION_LOG="/tmp/daypass/transaction.log"

manifest_lookup()
{
    field="$1"
    package="$2"

    jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
        --arg field "$field" \
'
.architectures[]
| select(.name==$arch)
| .packages[]
| select(
    (.package == $pkg)
    or
    (.package | startswith($pkg + "-"))
)
| .[$field]
' \
"$MANIFEST_FILE" | head -n1
}

manifest_info()
{
    package="$1"

    jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
'
.architectures[]
| select(.name==$arch)
| .packages[]
| select(.package | startswith($pkg))
| "\(.package) | \(.size) bytes"
' \
"$MANIFEST_FILE" | head -n1
}

download_package()
{
    package="$1"

    file=$(manifest_lookup "file" "$package")
    sha256=$(manifest_lookup "sha256" "$package")

    if [ -z "$file" ] || [ "$file" = "null" ]; then
        log_error "Package not found in manifest : [$package]"
        return 1
    fi

    target="$TMP_DIR/$file"
    tmp="$target.part"

    mkdir -p "$(dirname "$target")"

    echo
    log_info "Package : $(manifest_info "$package")"
    log_info "File    : $file"
    log_info "URL     : $REPO_URL/$ARCH/$file"
    log_info "Downloading [$package] ..."

    if ! curl -fsSL "$REPO_URL/$ARCH/$file" -o "$tmp"; then
        log_error "Download failed for [$package]"
        rm -f "$tmp"
        return 1
    fi

    if [ ! -s "$tmp" ]; then
        log_error "Invalid package : empty file [$package]"
        rm -f "$tmp"
        return 1
    fi

    if ! echo "$sha256  $tmp" | sha256sum -c - >/dev/null 2>&1; then
        log_error "Checksum verification failed : [$package]"
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$target"
    log_success "Verified [$package]"
}

deploy_targeted_packages()
{
    mkdir -p "$(dirname "$INSTALL_LOG")"
    touch "$INSTALL_LOG"
    rm -f "$TRANSACTION_LOG"
    touch "$TRANSACTION_LOG"

    echo
    log_info "Starting installation ..."
    echo

    resource_snapshot
    estimate_install_size

    INSTALL_FILES=""

    for pkg in $FINAL_PACKAGES; do
        if ! download_package "$pkg"; then
            log_error "Download failed : [$pkg]"
            rollback_failed_install
            return 1
        fi

        file=$(manifest_lookup "file" "$pkg")
        INSTALL_FILES="$INSTALL_FILES $TMP_DIR/$file"
    done

    echo
    log_info "Installing packages :"
    echo "[$INSTALL_FILES]"
    echo

    case "$PKG_MANAGER" in
        apk)
            if apk add --allow-untrusted $INSTALL_FILES; then
                echo "$FINAL_PACKAGES" >> "$INSTALL_LOG"
                resource_compare
                return 0
            fi
            ;;
        opkg)
            if opkg install $INSTALL_FILES; then
                echo "$FINAL_PACKAGES" >> "$INSTALL_LOG"
                resource_compare
                return 0
            fi
            ;;
    esac

    log_error "Installation failed!"
    rollback_failed_install
    return 1
}

rollback_failed_install()
{
    echo
    log_warn "Rolling back installation ..."
    echo

    [ -f "$TRANSACTION_LOG" ] || return

    case "$PKG_MANAGER" in
        opkg)
            while read -r pkg; do
                [ -z "$pkg" ] && continue
                log_info "Removing ($pkg) for rollback ..."
                opkg remove "$pkg" || true
            done < "$TRANSACTION_LOG"
            ;;
        apk)
            while read -r pkg; do
                [ -z "$pkg" ] && continue
                log_info "Removing ($pkg) for rollback ..."
                apk del "$pkg" || true
            done < "$TRANSACTION_LOG"
            ;;
    esac

    rm -f "$TRANSACTION_LOG"
    log_success "Rollback completed!"
}