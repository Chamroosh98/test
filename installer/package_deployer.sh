#!/bin/sh

SELECTED_PACKAGES=""

add_package() {

    [ -z "$1" ] && return

    case " $SELECTED_PACKAGES " in
        *" $1 "*) ;;
        *)
            SELECTED_PACKAGES="$SELECTED_PACKAGES $1"
            ;;
    esac
}

download_package() {

    package="$1"

    file=$(jq -r \
        --arg pkg "$package" \
        --arg arch "$ARCH" \
        '
        .architectures[]
        | select(.name==$arch)
        | .packages[]
        | select(.package==$pkg)
        | .file
        ' \
        "$MANIFEST_FILE")

    [ -z "$file" ] && return 1
    [ "$file" = "null" ] && return 1

    mkdir -p "$TMP_DIR/$(dirname "$file")"

    curl -fsSL \
        "$REPO_URL/$ARCH/$file" \
        -o "$TMP_DIR/$file"
}

install_package() {

    file="$1"

    case "$PKG_MANAGER" in

        opkg)

            pkg_install "$file"

            ;;

        apk)

            pkg_install "$file"

            ;;

    esac
}

deploy_targeted_packages() {

    for pkg in $SELECTED_PACKAGES
    do

        echo "Installing: $pkg"

        mkdir -p "$TMP_DIR"
        
        download_package "$pkg" || {

            echo "Download failed: $pkg"

            continue

        }

        file=$(jq -r \
            --arg pkg "$pkg" \
            --arg arch "$ARCH" \
            '
            .architectures[]
            | select(.name==$arch)
            | .packages[]
            | select(.package==$pkg)
            | .file
            ' \
            "$MANIFEST_FILE")

        install_package "$TMP_DIR/$file"

    done

}